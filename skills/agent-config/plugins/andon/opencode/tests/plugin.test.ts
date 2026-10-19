import assert from "node:assert/strict";
import { test } from "node:test";
import { harness, input, receipt } from "./helpers.ts";
import { TOOL } from "../src/rule.ts";

test("pull is directly offered, outside Code Mode discovery", async () => {
  const h = await harness();
  assert.equal(h.tools.get(TOOL)?.options?.codemode, false);
  assert.equal(h.tools.size, 1);
});

test("rule is injected on every primary request only when the tool is offered", async () => {
  const h = await harness();
  assert.match((await h.context()).system[0].text, /Active trigger level: 3/);
  assert.match((await h.context()).system[0].text, /Andon cord/);
  assert.deepEqual((await h.context("other", false)).system, []);
});

test("prompt-level overrides are isolated and survive plugin reload/compaction", async () => {
  const h = await harness();
  await h.emit("session:prompt", {
    sessionID: "one",
    prompt: { text: "andon level 5 please" }
  });
  assert.match((await h.context()).system[0].text, /Active trigger level: 5/);
  assert.match(
    (await h.context("two")).system[0].text,
    /Active trigger level: 3/
  );
  h.cleanup();
  const reloaded = await harness({ storage: h.storage });
  assert.match(
    (await reloaded.context()).system[0].text,
    /Active trigger level: 5/
  );
  await reloaded.emit("session:prompt", {
    sessionID: "one",
    prompt: { text: "andon level default" }
  });
  assert.match(
    (await reloaded.context()).system[0].text,
    /Active trigger level: 3/
  );
});

test("mentioning a level does not change it", async () => {
  const h = await harness();
  await h.emit("session:prompt", {
    sessionID: "one",
    prompt: { text: "what does andon level 5 do?" }
  });
  assert.match((await h.context()).system[0].text, /Active trigger level: 3/);
});

test("attribution is host-supplied and uses the session location, not plugin location", async () => {
  const h = await harness();
  await h.context();
  assert.deepEqual(
    await h.pull({
      ...input,
      harness: "forged",
      conversation_id: "wrong",
      workspace_paths: ["/wrong"]
    }),
    receipt
  );
  const payload = h.calls.find((call) => call.args[0] === "pull")!
    .input as Record<string, unknown>;
  assert.equal(payload.harness, "opencode");
  assert.equal(payload.conversation_id, "one");
  assert.equal(payload.tool_use_id, "call-1");
  assert.equal(payload.model_name, "test/reasoner");
  assert.deepEqual(payload.workspace_paths, ["/sessions/one"]);
  assert.equal(payload.level, 3);
  assert.equal(payload.transcript_path, undefined);
  assert.equal(payload.step_idx, undefined);
});

test("child sessions receive their own attribution and model fallback", async () => {
  const h = await harness();
  await h.pull(input, "child-1");
  const payload = h.calls.find((call) => call.args[0] === "pull")!
    .input as Record<string, unknown>;
  assert.equal(payload.agent_id, "child-1");
  assert.equal(payload.model_name, "test/fallback");
});

test("only the pull permission is automatically allowed", async () => {
  const h = await harness();
  const ask = { action: TOOL, effect: "ask" };
  await h.emit("permission:evaluate", ask);
  assert.equal(ask.effect, "allow");
  const other = { action: "shell", effect: "ask" };
  const deny = { action: TOOL, effect: "deny" };
  await h.emit("permission:evaluate", other);
  await h.emit("permission:evaluate", deny);
  assert.equal(other.effect, "ask");
  assert.equal(deny.effect, "deny");
  await h.pull();
  assert.equal(h.permissions.length, 1);
});

test("explicit denial propagates and cannot write an alert", async () => {
  const h = await harness({ deny: true });
  await assert.rejects(h.pull(), /User denied/);
  assert.equal(h.calls.filter((call) => call.args[0] === "pull").length, 0);
});

test("store failure returns honest guidance and never retries a write", async () => {
  let writes = 0;
  const h = await harness({
    cli: async (args) => {
      if (args[0] === "stats") return '{"level":3}';
      writes++;
      throw new Error("read-only store");
    }
  });
  const result = await h.pull();
  assert.equal(result.ok, false);
  assert.match(result.guidance, /not confirmed saved/);
  assert.match(result.guidance, /Do not retry/);
  assert.equal(writes, 1);
});

test("failed session lookup does not produce misleading attribution", async () => {
  const h = await harness();
  h.breakSession();
  assert.equal((await h.pull()).ok, false);
  assert.equal(h.calls.filter((call) => call.args[0] === "pull").length, 0);
});

test("an unreadable success receipt does not invite duplicate pulls", async () => {
  const h = await harness({
    cli: async (args) => (args[0] === "stats" ? '{"level":3}' : "not JSON")
  });
  const result = await h.pull();
  assert.equal(result.ok, true);
  assert.match(result.guidance, /Do not pull again/);
});

test("disconnected UI cannot turn a saved pull into a failure", async () => {
  const h = await harness({ brokenEvents: true });
  assert.deepEqual(await h.pull(), receipt);
});

test("cancellation propagates rather than returning ordinary failure guidance", async () => {
  const h = await harness();
  const controller = new AbortController();
  controller.abort();
  const broken = await harness({
    cli: async (_args, _input, signal) => {
      signal?.throwIfAborted();
      return '{"level":3}';
    }
  });
  await assert.rejects(broken.pull(input, "one", controller.signal), {
    name: "AbortError"
  });
  assert.equal(h.calls.filter((call) => call.args[0] === "pull").length, 0);
});

test("commands support session reset and shared saved defaults", async () => {
  const h = await harness();
  await h.rpc("command", { text: "level 5", sessionID: "one" });
  assert.match((await h.context()).system[0].text, /Active trigger level: 5/);
  await h.rpc("command", { text: "level 4 --save", sessionID: "one" });
  assert.match((await h.context()).system[0].text, /Active trigger level: 4/);
  assert.match(
    (await h.context("two")).system[0].text,
    /Active trigger level: 4/
  );
  await h.rpc("command", { text: "level default --save", sessionID: "one" });
  assert.match((await h.context()).system[0].text, /Active trigger level: 3/);
});

test("command dispatch rejects arbitrary CLI operations and extra arguments", async () => {
  const h = await harness();
  for (const text of [
    "clear-resolved",
    "level 5 --save extra",
    "level 5 --oops",
    "list --status all"
  ]) {
    assert.match(
      ((await h.rpc("command", { text })) as { text: string }).text,
      /^Usage:/
    );
  }
  assert.match(
    ((await h.rpc("command", { text: "level 5" })) as { text: string }).text,
    /Open a session/
  );
  assert.equal(h.calls.filter((call) => call.args[0] === "level").length, 0);
});

test("board operations use the CLI and do not become model-facing tools", async () => {
  const h = await harness();
  const snapshot = (await h.rpc("snapshot", { sessionID: "one" })) as {
    alerts: unknown[];
    level: number;
  };
  assert.deepEqual(snapshot.alerts, []);
  assert.equal(snapshot.level, 3);
  await h.rpc("transition", { verb: "resolve", id: receipt.id });
  assert.deepEqual(h.calls.at(-1)?.args, [
    "resolve",
    receipt.id,
    "--all-matching",
    "--note",
    "resolve from the OpenCode Andon board"
  ]);
  await assert.rejects(
    h.rpc("transition", { verb: "clear-resolved", id: receipt.id }),
    /Invalid transition/
  );
  assert.equal(h.tools.size, 1);
});

test("sensor output and failure history are isolated by session", async () => {
  const h = await harness();
  await h.context();
  await h.context("two");
  const failed = (sessionID: string) => ({
    tool: "shell",
    sessionID,
    input: { command: "deploy --old" },
    status: "completed",
    result: { content: "Exited with code 1" }
  });
  await h.emit("tool:execute.after", failed("one"));
  const second = failed("one");
  await h.emit("tool:execute.after", second);
  assert.match(second.result.content, /Andon:.*failed twice/);
  const other = failed("two");
  await h.emit("tool:execute.after", other);
  assert.doesNotMatch(other.result.content, /Andon:/);
});

test("sensor errors preserve the Tool.Error and nudge the next model request", async () => {
  const h = await harness();
  await h.context();
  const error = new Error("process failed");
  const event = {
    tool: "shell",
    sessionID: "one",
    input: { command: "deploy" },
    status: "error",
    error
  };
  await h.emit("tool:execute.after", event);
  await h.emit("tool:execute.after", event);
  assert.equal(event.error, error);
  assert.match((await h.context()).system.at(-1)!.text, /Andon:.*failed twice/);
  assert.equal((await h.context()).system.length, 1);
});

test("sensor does nothing when the request lacks the pull tool", async () => {
  const h = await harness();
  await h.context("one", false);
  const event = {
    tool: "shell",
    sessionID: "one",
    input: { command: "deploy" },
    status: "completed",
    result: { content: "Exited with code 1" }
  };
  await h.emit("tool:execute.after", event);
  await h.emit("tool:execute.after", event);
  assert.equal(event.result.content, "Exited with code 1");
});

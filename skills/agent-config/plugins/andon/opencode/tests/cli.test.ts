import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { chmod, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import { createCli, cliJson } from "../src/cli.ts";
import { harness, input } from "./helpers.ts";

async function temporary(run: (directory: string) => Promise<void>) {
  const directory = await mkdtemp(join(tmpdir(), "andon-opencode-"));
  try {
    await run(directory);
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
}

test("native tool writes records readable by the unchanged CLI", async () =>
  temporary(async (directory) => {
    const cli = createCli({
      env: { ...process.env, ANDON_STATE_DIR: directory, ANDON_LEVEL: "3" }
    });
    const h = await harness({ cli });
    await h.context();
    const pulled = await h.pull();
    assert.equal(pulled.ok, true);
    const alert = await cliJson<Record<string, unknown>>(cli, [
      "show",
      pulled.id,
      "--json"
    ]);
    assert.equal(alert.harness, "opencode");
    assert.equal(alert.conversation_id, "one");
    assert.deepEqual(alert.workspace_paths, ["/sessions/one"]);
    // Simulate another harness writing the existing payload shape.
    await cli(["pull", "--json", "-"], {
      ...input,
      harness: "claude-code",
      conversation_id: "claude-session"
    });
    const alerts = await cliJson<Record<string, unknown>[]>(cli, [
      "list",
      "--json"
    ]);
    assert.equal(alerts.length, 2);
    assert.equal(alerts[0].recurrences, 2);
    await h.rpc("transition", { id: pulled.id, verb: "resolve" });
    assert.deepEqual(await cliJson(cli, ["list", "--json"]), []);
  }));

test("saved defaults still yield to ANDON_LEVEL", async () =>
  temporary(async (directory) => {
    const cli = createCli({
      env: { ...process.env, ANDON_STATE_DIR: directory, ANDON_LEVEL: "2" }
    });
    const h = await harness({ cli });
    await h.rpc("command", { text: "level 5", sessionID: "one" });
    assert.match((await h.context()).system[0].text, /Active trigger level: 2/);
    assert.equal(
      JSON.parse(await readFile(join(directory, "config.json"), "utf8")).level,
      5
    );
  }));

test("missing script interpreter falls back to Python without uv", async () =>
  temporary(async (directory) => {
    const script = join(directory, "andon");
    await writeFile(
      script,
      '#!/no/such/interpreter\nimport sys\nprint("fallback " + sys.argv[1])\n'
    );
    await chmod(script, 0o755);
    const cli = createCli({ script });
    assert.equal(await cli(["show"]), "fallback show\n");
  }));

test("fallback resolves command names through PATH", async () =>
  temporary(async (directory) => {
    const script = join(directory, "andon-fixture");
    await writeFile(script, '#!/no/such/interpreter\nprint("found on PATH")\n');
    await chmod(script, 0o755);
    const cli = createCli({
      script: "andon-fixture",
      env: { ...process.env, PATH: `${directory}:${process.env.PATH}` }
    });
    assert.equal(await cli([]), "found on PATH\n");
  }));

test("ordinary CLI failures are surfaced without retry", async () =>
  temporary(async (directory) => {
    const script = join(directory, "fail");
    await writeFile(script, '#!/bin/sh\nprintf "diagnostic" >&2\nexit 1\n');
    await chmod(script, 0o755);
    await assert.rejects(createCli({ script })([]), /diagnostic/);
  }));

test("subprocesses have bounded timeouts and support cancellation", async () =>
  temporary(async (directory) => {
    const script = join(directory, "slow");
    const python = execFileSync("which", ["python3"], {
      encoding: "utf8"
    }).trim();
    await writeFile(script, `#!${python}\nimport time\ntime.sleep(30)\n`);
    await chmod(script, 0o755);
    await assert.rejects(createCli({ script, timeout: 25 })([]));
    const controller = new AbortController();
    const running = createCli({ script })([], undefined, controller.signal);
    controller.abort();
    await assert.rejects(running, { name: "AbortError" });
  }));

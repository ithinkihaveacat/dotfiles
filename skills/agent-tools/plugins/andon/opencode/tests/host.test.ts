import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { once } from "node:events";
import { mkdir, mkdtemp, rm, symlink, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { createServer } from "node:http";
import { test } from "node:test";
import { fileURLToPath } from "node:url";
import { OpenCode } from "@opencode/client";
import { Service } from "@opencode/client/service";
import { Andon } from "../src/rpc.ts";
import type { Snapshot, TextResponse } from "../src/types.ts";

async function modelFixture() {
  const requests: Record<string, unknown>[] = [];
  let pulled = false;
  const server = createServer(async (request, response) => {
    try {
      let body = "";
      for await (const chunk of request) body += chunk;
      const input = JSON.parse(body) as Record<string, unknown>;
      requests.push(input);
      const tools = (input.tools ?? []) as { function?: { name: string } }[];
      const tool = tools.find((tool) => tool.function?.name === "andon_pull");
      const call = tool && !pulled;
      if (call) pulled = true;
      response.writeHead(200, { "content-type": "text/event-stream" });
      const delta = call
        ? {
            tool_calls: [
              {
                index: 0,
                id: "call_fixture",
                type: "function",
                function: {
                  name: "andon_pull",
                  arguments: JSON.stringify({
                    color: "yellow",
                    kind: "stale_instruction",
                    summary: "Fixture flag was removed",
                    details:
                      "SKILL.md documents --old; --help only offers --new",
                    sources: ["fixture/SKILL.md"]
                  })
                }
              }
            ]
          }
        : { content: "Fixture complete." };
      const chunk = (delta: unknown, finish_reason: string | null) => ({
        id: "fixture",
        object: "chat.completion.chunk",
        created: 1,
        model: "fixture",
        choices: [{ index: 0, delta, finish_reason }]
      });
      response.write(`data: ${JSON.stringify(chunk(delta, null))}\n\n`);
      response.write(
        `data: ${JSON.stringify(chunk({}, call ? "tool_calls" : "stop"))}\n\n`
      );
      response.end("data: [DONE]\n\n");
    } catch (error) {
      response.writeHead(500);
      response.end(String(error));
    }
  });
  server.listen(0, "127.0.0.1");
  await once(server, "listening");
  const address = server.address() as { port: number };
  return {
    server,
    requests,
    reset: () => {
      pulled = false;
    },
    baseURL: `http://127.0.0.1:${address.port}/v1`
  };
}

for (const installation of ["configured", "symlinked"]) {
  test(
    `installed OpenCode loads the ${installation} package and serves the board RPC`,
    {
      skip:
        !process.env.OPENCODE_TEST_BINARY &&
        "set OPENCODE_TEST_BINARY to an OpenCode V2 executable",
      timeout: 60_000
    },
    async () => {
      const directory = await mkdtemp(join(tmpdir(), "andon-host-"));
      const fixture = await modelFixture();
      const config = join(directory, "config");
      await mkdir(join(config, "opencode"), { recursive: true });
      const plugin = fileURLToPath(new URL("..", import.meta.url));
      if (installation === "symlinked") {
        await mkdir(join(config, "opencode", "plugins"));
        await symlink(
          plugin,
          join(config, "opencode", "plugins", "andon"),
          "dir"
        );
      }
      await writeFile(
        join(config, "opencode", "opencode.json"),
        JSON.stringify({
          $schema: "https://opencode.ai/config.json",
          plugins: installation === "configured" ? [plugin] : undefined,
          update: "disable",
          snapshots: false,
          model: "andon-test/fixture",
          providers: {
            "andon-test": {
              package: "@opencode/ai/providers/openai-compatible",
              settings: { baseURL: fixture.baseURL, apiKey: "test-only" },
              models: {
                fixture: {
                  capabilities: { tools: true },
                  limit: { context: 128000, output: 4096 }
                }
              }
            }
          }
        })
      );
      const server = spawn(
        process.env.OPENCODE_TEST_BINARY!,
        [
          "serve",
          "--service",
          "--hostname",
          "127.0.0.1",
          "--port",
          "0",
          "--log-level",
          "debug",
          "--print-logs"
        ],
        {
          cwd: directory,
          env: {
            PATH: process.env.PATH,
            HOME: directory,
            TMPDIR: tmpdir(),
            XDG_CONFIG_HOME: config,
            XDG_DATA_HOME: join(directory, "data"),
            XDG_STATE_HOME: join(directory, "state"),
            XDG_CACHE_HOME: join(directory, "cache"),
            ANDON_STATE_DIR: join(directory, "andon"),
            ANDON_LEVEL: "3"
          },
          stdio: ["ignore", "pipe", "pipe"]
        }
      );
      let output = "";
      const exited = once(server, "exit");
      try {
        const url = await new Promise<string>((resolve, reject) => {
          const timeout = setTimeout(
            () => reject(new Error(`Server did not become ready: ${output}`)),
            30_000
          );
          const received = (data: Buffer) => {
            output += data.toString();
            const match = /http:\/\/127\.0\.0\.1:\d+/.exec(output);
            if (match) {
              clearTimeout(timeout);
              resolve(match[0]);
            }
          };
          server.stdout.on("data", received);
          server.stderr.on("data", received);
          server.once("error", (error) => {
            clearTimeout(timeout);
            reject(error);
          });
          server.once("exit", () => {
            clearTimeout(timeout);
            reject(new Error(output));
          });
        });
        const endpoint = await Service.discover({
          file: join(directory, "state", "opencode", "service.json")
        });
        assert.ok(endpoint, `No test service registration at ${url}`);
        const client = OpenCode.make({
          baseUrl: endpoint.url,
          headers: Service.headers(endpoint)
        });
        const location = { directory };
        await client.agent.list({ location });
        const session = await client.session.create({
          location,
          title: "Andon smoke test"
        });
        const rpc = client.rpc(Andon);
        const before = (await rpc.snapshot(
          { sessionID: session.id },
          { location }
        )) as Snapshot;
        const plugins = await client.plugin.list({ location });
        const andon = plugins.data.find((plugin) => plugin.id === "andon");
        assert.equal(
          andon?.state.status,
          "active",
          JSON.stringify({
            plugins,
            config: await client.config.get({ location }),
            output
          })
        );
        assert.equal(before.level, 3);
        assert.deepEqual(before.alerts, []);
        const changed = (await rpc.command(
          { text: "level 5", sessionID: session.id },
          { location }
        )) as TextResponse;
        assert.match(changed.text, /level 5/);
        const after = (await rpc.snapshot(
          { sessionID: session.id },
          { location }
        )) as Snapshot;
        assert.equal(after.level, 5);
        assert.equal(after.sessionOverride, true);
        await assert.rejects(
          rpc.transition(
            { id: "invalid", verb: "clear-resolved" },
            { location }
          )
        );
        await client.session.prompt({
          sessionID: session.id,
          text: "Exercise the fixture tool."
        });
        await client.session.wait(
          { sessionID: session.id },
          { signal: AbortSignal.timeout(20_000) }
        );
        const reported = (await rpc.snapshot(
          { sessionID: session.id },
          { location }
        )) as Snapshot;
        assert.equal(
          reported.alerts.length,
          1,
          JSON.stringify(
            await client.session.context({ sessionID: session.id })
          )
        );
        assert.equal(reported.alerts[0].conversation_id, session.id);
        assert.equal(reported.alerts[0].harness, "opencode");
        assert.equal(reported.alerts[0].level, 5);
        assert.ok(
          fixture.requests.some((request) =>
            JSON.stringify(request.messages).includes("Active trigger level: 5")
          )
        );
        assert.ok(
          fixture.requests.some((request) =>
            JSON.stringify(request.tools).includes('"name":"andon_pull"')
          )
        );
        await client.session.command({
          sessionID: session.id,
          name: "andon",
          text: "level 2"
        });
        await client.session.wait(
          { sessionID: session.id },
          { signal: AbortSignal.timeout(20_000) }
        );
        const fromCommand = (await rpc.snapshot(
          { sessionID: session.id },
          { location }
        )) as Snapshot;
        assert.equal(
          fromCommand.level,
          2,
          "server-side slash commands must parse their arguments"
        );
        const denied = await client.session.create({
          location,
          title: "Andon explicit deny"
        });
        await client.session.update({
          sessionID: denied.id,
          permissions: [{ action: "andon_pull", resource: "*", effect: "deny" }]
        });
        fixture.reset();
        await client.session.prompt({
          sessionID: denied.id,
          text: "Exercise the denied tool."
        });
        await client.session.wait(
          { sessionID: denied.id },
          { signal: AbortSignal.timeout(20_000) }
        );
        const still = (await rpc.snapshot(
          { sessionID: denied.id },
          { location }
        )) as Snapshot;
        assert.equal(
          still.alerts.length,
          1,
          "an explicit deny must not write another alert"
        );
      } catch (error) {
        throw new Error(`${String(error)}\n${output}`);
      } finally {
        server.kill("SIGTERM");
        const kill = setTimeout(() => server.kill("SIGKILL"), 5_000);
        await exited;
        clearTimeout(kill);
        fixture.server.closeAllConnections();
        await new Promise<void>((resolve) =>
          fixture.server.close(() => resolve())
        );
        await rm(directory, { recursive: true, force: true });
      }
    }
  );
}

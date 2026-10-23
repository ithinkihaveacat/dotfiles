import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import {
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  writeFileSync
} from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import plugin, {
  payload,
  run,
  shouldEnsure
} from "../plugins/ensure-commit-hooks.ts";

type Hook = (event: { command: string; cwd: string }) => Promise<void>;

function temporary(prefix: string): string {
  return mkdtempSync(join(tmpdir(), prefix));
}

function repository(): string {
  const dir = temporary("opencode-hook-repo-");
  execFileSync("git", ["init", "-q", dir]);
  return dir;
}

function commitHook(dir: string): string {
  return join(dir, ".git", "hooks", "commit-msg.d", "10-agent");
}

async function shellHook(): Promise<Hook> {
  let found: Hook | undefined;
  await plugin.setup({
    shell: {
      async hook(name, callback) {
        assert.equal(name, "create.before");
        found = callback;
        return { dispose() {} };
      }
    }
  });
  assert.ok(found);
  return found;
}

function setRequiredHooks(value: string | undefined): void {
  if (value === undefined) delete process.env.AGENT_REQUIRED_HOOKS;
  else process.env.AGENT_REQUIRED_HOOKS = value;
}

test("recognises git commit commands", () => {
  assert.equal(shouldEnsure("git commit -m x"), true);
  assert.equal(shouldEnsure("git status && git commit -m x"), true);
  assert.equal(shouldEnsure("cd repo\n  git commit -m x"), true);
  assert.equal(shouldEnsure("git status"), false);
  assert.equal(shouldEnsure("node commit.js"), false);
  assert.equal(shouldEnsure("legit commit"), false);
});

test("builds the payload the shared script already accepts", () => {
  assert.deepEqual(JSON.parse(payload("git commit -m x", "/tmp/repo")), {
    cwd: "/tmp/repo",
    tool_input: { command: "git commit -m x" }
  });
});

test("passes the command and cwd to the shared script", async () => {
  const dir = temporary("opencode-hook-payload-");
  const script = join(dir, "capture.sh");
  const out = join(dir, "out.json");
  writeFileSync(script, '#!/usr/bin/env bash\ncat >"$OUT"\n');
  process.env.OUT = out;

  await run(script, "git commit -m x", "/tmp/repo");

  assert.deepEqual(JSON.parse(readFileSync(out, "utf8")), {
    cwd: "/tmp/repo",
    tool_input: { command: "git commit -m x" }
  });
});

test("installs the commit hook from a subdirectory before git commit", async () => {
  const dir = repository();
  const sub = join(dir, "packages", "web");
  mkdirSync(sub, { recursive: true });
  setRequiredHooks("agent");

  const hook = await shellHook();
  await hook({ command: "git commit -m test", cwd: sub });

  assert.ok(existsSync(commitHook(dir)));
});

test("follows git -C targets and ignores other commands", async () => {
  const target = repository();
  const elsewhere = temporary("opencode-hook-elsewhere-");
  setRequiredHooks("agent");

  const hook = await shellHook();
  await hook({ command: `git -C ${target} commit -m test`, cwd: elsewhere });
  assert.ok(existsSync(commitHook(target)));

  const untouched = repository();
  await hook({ command: "git status", cwd: untouched });
  assert.equal(existsSync(commitHook(untouched)), false);
});

test("honours the opt-out, leaves non-repositories alone and never throws", async () => {
  const optedOut = repository();
  setRequiredHooks("");
  const hook = await shellHook();
  await hook({ command: "git commit -m test", cwd: optedOut });
  assert.equal(existsSync(commitHook(optedOut)), false);

  setRequiredHooks("agent");
  const plain = temporary("opencode-hook-plain-");
  await hook({ command: "git commit -m test", cwd: plain });
  assert.equal(existsSync(commitHook(plain)), false);

  setRequiredHooks(undefined);
});

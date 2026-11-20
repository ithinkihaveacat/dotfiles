import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { after, test } from "node:test";
import {
  payload,
  run,
  shouldEnsure
} from "../plugins/ensure-commit-hooks.ts";

const temporaryDirs: string[] = [];

function temporary(prefix: string): string {
  const dir = mkdtempSync(join(tmpdir(), prefix));
  temporaryDirs.push(dir);
  return dir;
}

after(() => {
  for (const dir of temporaryDirs) {
    rmSync(dir, { recursive: true, force: true });
  }
});

async function withEnv(
  vars: Record<string, string | undefined>,
  fn: () => Promise<void>
): Promise<void> {
  const prev = new Map<string, string | undefined>();
  for (const [k, v] of Object.entries(vars)) {
    prev.set(k, process.env[k]);
    if (v === undefined) delete process.env[k];
    else process.env[k] = v;
  }
  try {
    await fn();
  } finally {
    for (const [k, v] of prev) {
      if (v === undefined) delete process.env[k];
      else process.env[k] = v;
    }
  }
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
  await withEnv({ OUT: out }, async () => {
    await run(script, "git commit -m x", "/tmp/repo");
  });

  assert.deepEqual(JSON.parse(readFileSync(out, "utf8")), {
    cwd: "/tmp/repo",
    tool_input: { command: "git commit -m x" }
  });
});

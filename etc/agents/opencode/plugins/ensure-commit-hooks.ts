// OpenCode adapter for the shared commit-hook safety net.
//
// OpenCode's shell hook already exposes the command and working directory, so
// this adapter only decides whether a shell command is a `git commit` and feeds
// that to ../../hooks/ensure-commit-hooks in the payload shape the script
// already accepts (the same one Claude Code sends). The repository checks,
// symlink guards and opt-out stay in the shared script.
//
// It writes nothing itself, never blocks a tool call and never throws. The
// plugin runs in the OpenCode server, so `bash`, `jq` and `git` must exist
// there, as they must for the other agents' hook.

import { execFile } from "node:child_process";
import { existsSync, realpathSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const TIMEOUT_MS = 5_000;
const GIT_COMMIT = /(?:^|[^A-Za-z0-9_-])git\s+[\s\S]*commit(?:[^A-Za-z0-9_-]|$)/;

type ShellCreateBefore = {
  command: string;
  cwd: string;
};

type Context = {
  shell?: {
    hook(
      name: "create.before",
      callback: (event: ShellCreateBefore) => Promise<void> | void
    ): Promise<unknown>;
  };
};

// Local directories are loaded as plain V2 plugin definitions: OpenCode reads
// `id` and `setup`, so no runtime import of `@opencode/plugin` is needed (which
// also keeps this file testable outside a configured OpenCode install).
export function shouldEnsure(command: string): boolean {
  return GIT_COMMIT.test(command);
}

export function payload(command: string, cwd: string): string {
  return JSON.stringify({ cwd, tool_input: { command } });
}

function sharedScript(): string | undefined {
  try {
    const here = dirname(realpathSync(fileURLToPath(import.meta.url)));
    const script = join(here, "..", "..", "hooks", "ensure-commit-hooks");
    return existsSync(script) ? script : undefined;
  } catch {
    return undefined;
  }
}

export function run(
  script: string,
  command: string,
  cwd: string
): Promise<void> {
  return new Promise((resolve) => {
    const child = execFile(
      "bash",
      [script],
      { timeout: TIMEOUT_MS, windowsHide: true },
      () => resolve()
    );
    child.on("error", () => resolve());
    child.stdin?.on("error", () => {});
    child.stdin?.end(payload(command, cwd));
  });
}

export default {
  id: "dotfiles.ensure-commit-hooks",
  async setup(ctx: Context) {
    const script = sharedScript();
    if (!script || !ctx.shell) return;
    await ctx.shell.hook("create.before", async (event) => {
      try {
        if (process.env.AGENT_REQUIRED_HOOKS === "") return;
        if (!shouldEnsure(event.command)) return;
        await run(script, event.command, event.cwd);
      } catch {
        // A hook must never block or fail a shell tool call.
      }
    });
  }
};

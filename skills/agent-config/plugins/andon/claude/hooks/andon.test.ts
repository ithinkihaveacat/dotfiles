import { describe, expect, mock, test } from "claude-code/testing";
import type { On } from "claude-code";

import { INPUT_SCHEMA, TOOL, buildRule } from "./rule";
import { createSensor } from "./sensor";

type Run = { argv: readonly string[]; stdin?: string };

const PULLED = {
  ok: true,
  id: "ANDON-20261016-125226-e790",
  color: "yellow",
  kind: "stale_instruction",
  level: 3,
  fingerprint: "a1b2c3d4e5f6",
  recurrences: 2,
  guidance:
    "Logged yellow Andon alert. Continue with your chosen workaround; do not interrupt the user."
};

const ALERT = {
  id: PULLED.id,
  created_at: "2026-10-16T12:52:26Z",
  status: "open",
  color: "yellow",
  kind: "stale_instruction",
  level: 3,
  summary: "deploy SKILL.md documents removed --fast flag",
  sources: ["skills/deploy/SKILL.md"],
  fingerprint: PULLED.fingerprint,
  recurrences: 2
};

type RunResult = {
  exitCode: number;
  stdout: string;
  stderr: string;
  isStdoutTruncated: boolean;
  isStderrTruncated: boolean;
};

function result(exitCode: number, stdout: string, stderr = ""): RunResult {
  return {
    exitCode,
    stdout,
    stderr,
    isStdoutTruncated: false,
    isStderrTruncated: false
  };
}

/** The CLI as the tests see it: canned JSON per subcommand. */
function fakeCli(level: number): (argv: readonly string[]) => RunResult {
  return (argv) => {
    const verb = argv.find((a) => !a.includes("/") && a !== "python3");
    const answers: Record<string, unknown> = {
      level: { level, source: "default" },
      stats: { open: 2, open_red: 0, level },
      pull: PULLED,
      list: [ALERT]
    };
    const answer = verb === undefined ? undefined : answers[verb];

    return result(0, answer === undefined ? "" : JSON.stringify(answer));
  };
}

type Options = {
  level?: number;
  run?: (argv: readonly string[]) => RunResult;
  registered?: { name: string; isDeferred?: unknown; description: string }[];
  /** What the user's rules and mode decide for the pull tool. */
  verdict?: "allow" | "ask" | "deny";
  isPlaced?: boolean;
};

/** Answers every engine call the plugin makes, the CLI included. */
function engine(
  on: On,
  {
    level = 3,
    run = fakeCli(level),
    registered = [],
    verdict = "ask",
    isPlaced = true
  }: Options = {}
): Run[] {
  const runs: Run[] = [];
  mock.clock(on);
  on("session.start", ($, e) => ({ cwd: e.cwd }));
  on("session.id", () => ({ value: "session-1" }));
  on("session.cwd", () => ({ value: "/work/app" }));
  on("session.root", () => ({ value: "/work/app" }));
  on("session.turns", () => ({ value: 7 }));
  on("session.model", () => ({ value: "claude-opus-5-5" }));
  on("fs.exists", () => ({ value: true }));
  on("ui.status", () => ({ value: undefined }));
  on("ui.toast", () => ({ value: undefined }));
  on("classic.SessionStart", () => ({}));
  on("tool.register", ($, e) => {
    registered.push(e);

    return { value: { tool: `mcp__andon__${e.name}` } };
  });
  on("ui.open", () => ({
    value: isPlaced ? { isPlaced } : { isPlaced, reason: "no surface" }
  }));
  on("ui.panes", () => ({ value: [] }));
  on("fs.stat", () => ({ deny: "not in tests" }));
  on("tool.check", () => ({ decision: verdict }));
  on("command.register", ($, e) => ({ value: { command: e.name } }));
  on("process.run", ($, e) => {
    runs.push({ argv: e.argv, stdin: e.init?.stdin });

    return { value: run(e.argv) };
  });

  return runs;
}

const START = {
  cwd: "/work/app",
  surface: "terminal",
  isInteractive: true
} as const;

describe("the rule", () => {
  test("drops the do-not-pull list and self-filtering at level 5", () => {
    expect(buildRule(3)).toContain("Do not pull for");
    expect(buildRule(5)).not.toContain("Do not pull for");
    expect(buildRule(5)).toContain("Do not self-filter");
  });

  test("includes the full 1-5 trigger level rubric and omits level from INPUT_SCHEMA", () => {
    const rule = buildRule(3);
    expect(rule).toContain("Active trigger level: 3 (standard).");
    expect(rule).toContain("- Level 1 (red only):");
    expect(rule).toContain("- Level 2 (conservative):");
    expect(rule).toContain("- Level 3 (standard):");
    expect(rule).toContain("- Level 4 (proactive audit):");
    expect(rule).toContain("- Level 5 (maximum coverage):");
    expect("level" in INPUT_SCHEMA.properties).toBe(false);
  });
});

describe("the sensor", () => {
  const skill = "/home/me/.dotfiles/skills/deploy";

  test("nudges once when a command fails after its skill was read", () => {
    const sensor = createSensor();
    sensor.observe({
      tool: "Read",
      input: { file_path: `${skill}/SKILL.md` },
      isError: false,
      level: 3
    });
    const failed = {
      tool: "Bash",
      input: { command: "skills/deploy/scripts/deploy --fast" },
      isError: true,
      level: 3
    };
    expect(sensor.observe(failed)).toContain(TOOL);
    expect(sensor.observe(failed)).toBe(null);
  });

  test("nudges on a --help probe after a failure, and on a repeated failure", () => {
    const sensor = createSensor();
    sensor.observe({
      tool: "Bash",
      input: { command: "tool --fast" },
      isError: true,
      level: 3
    });
    expect(
      sensor.observe({
        tool: "Bash",
        input: { command: "tool --help" },
        isError: false,
        level: 3
      })
    ).toContain("--help");
    sensor.observe({
      tool: "Bash",
      input: { command: "make lint" },
      isError: true,
      level: 3
    });
    expect(
      sensor.observe({
        tool: "Bash",
        input: { command: "make lint" },
        isError: true,
        level: 3
      })
    ).toContain("failed twice");
  });

  test("stays quiet at level 1 and after a pull", () => {
    const sensor = createSensor();
    sensor.observe({
      tool: "Bash",
      input: { command: "tool --fast" },
      isError: true,
      level: 1
    });
    expect(
      sensor.observe({
        tool: "Bash",
        input: { command: "tool --help" },
        isError: false,
        level: 1
      })
    ).toBe(null);
    sensor.observe({
      tool: "Bash",
      input: { command: "x --y" },
      isError: true,
      level: 3
    });
    sensor.observe({ tool: TOOL, input: {}, isError: false, level: 3 });
    expect(
      sensor.observe({
        tool: "Bash",
        input: { command: "x --help" },
        isError: false,
        level: 3
      })
    ).toBe(null);
  });
});

describe("the plugin", () => {
  test("registers the pull tool eagerly with the default level", async ($, on) => {
    const registered: {
      name: string;
      isDeferred?: unknown;
      description: string;
    }[] = [];
    engine(on, { level: 4, registered });
    await $.session.start(START);
    expect(registered).toHaveLength(1);
    expect(registered[0]?.isDeferred).toBe(false);
    // The rule carries the level, so the description cannot go stale.
    expect(registered[0]?.description).not.toContain("proactive audit");
  });

  test("adds the rule only to requests that offer the tool", async ($, on) => {
    engine(on);
    on("prompt.compose", () => ({
      sections: [{ id: "intro", text: "intro", scope: "shared" }]
    }));
    await $.session.start(START);
    const base = {
      model: "m",
      promptModel: "m",
      surfaces: [],
      outputStyle: null,
      traits: []
    };
    const withTool = await $.prompt.compose({ ...base, tools: ["Bash", TOOL] });
    expect(withTool.sections.map((s) => s.id)).toEqual(["intro", "andon:rule"]);
    const without = await $.prompt.compose({ ...base, tools: ["Bash"] });
    expect(without.sections.map((s) => s.id)).toEqual(["intro"]);
  });

  test("locks in the configured level for the session and /andon level updates the CLI default", async ($, on) => {
    let statsLevel = 4;
    const runs = engine(on, {
      run: (argv) => {
        if (argv.includes("stats")) {
          return result(
            0,
            JSON.stringify({ open: 2, open_red: 0, level: statsLevel })
          );
        }
        return fakeCli(statsLevel)(argv);
      }
    });
    on("prompt.compose", () => ({ sections: [] }));
    await $.session.start(START);
    statsLevel = 2;
    const composed = await $.prompt.compose({
      model: "m",
      promptModel: "m",
      surfaces: [],
      outputStyle: null,
      traits: [],
      tools: [TOOL]
    });
    expect(composed.sections[0]?.text).toContain(
      "Active trigger level: 4 (proactive audit)."
    );
    const setOut = await $.command.run({
      command: "andon",
      args: "level 5",
      origin: { kind: "composer" },
      presentation: { isFullscreen: false, columns: 80 }
    });
    expect(setOut.text).toContain("5 (maximum coverage)");
    expect(
      runs.some((r) => r.argv.includes("level") && r.argv.includes("5"))
    ).toBe(true);
  });

  test("a pull is allowed, stamped with the session and saved by the CLI", async ($, on) => {
    const runs = engine(on);
    await $.session.start(START);
    await $.classic.SessionStart({
      source: "startup",
      transcript_path: "/home/me/.claude/projects/app/session-1.jsonl"
    });
    const { decision } = await $.tool.check({ tool: TOOL, input: {} });
    expect(decision).toBe("allow"); // the engine asked; the plugin lifts it
    const ran = await $.tool.call({
      tool: TOOL,
      color: "yellow",
      kind: "stale_instruction",
      summary: "deploy SKILL.md documents removed --fast flag",
      details: "deploy --fast: unknown option; --help shows --quick",
      sources: ["skills/deploy/SKILL.md"],
      resolution: "Ran deploy --quick"
    });
    const pull = runs.find((r) => r.argv.includes("pull"));
    const sent = JSON.parse(pull?.stdin ?? "{}");
    expect(sent).toEqual(
      expect.objectContaining({
        harness: "claude-code",
        conversation_id: "session-1",
        step_idx: 7,
        level: 3,
        model_name: "claude-opus-5-5",
        workspace_paths: ["/work/app"],
        transcript_path: "/home/me/.claude/projects/app/session-1.jsonl"
      })
    );
    expect(JSON.stringify(ran.result)).toContain("do not interrupt the user");
  });

  test("a CLI failure still answers the model with guidance", async ($, on) => {
    const cli = fakeCli(3);
    engine(on, {
      run: (argv) =>
        argv.includes("pull")
          ? result(
              1,
              "",
              "andon pull: cannot write /state: Read-only file system"
            )
          : cli(argv)
    });
    await $.session.start(START);
    const ran = await $.tool.call({
      tool: TOOL,
      color: "red",
      kind: "rule_conflict",
      summary: "s",
      details: "d"
    });
    expect(JSON.stringify(ran.result)).toContain("Read-only file system");
    expect(JSON.stringify(ran.result)).toContain(
      "Stop work on the blocked path"
    );
  });

  test("the board lists alerts and resolves a group on every surface", async ($, on) => {
    const runs = engine(on);
    await $.session.start(START);
    const opened = await $.command.run({
      command: "andon",
      args: "",
      origin: { kind: "composer" },
      presentation: { isFullscreen: true, columns: 100 }
    });
    expect(opened.text).toContain("board opened");
    for (const surface of ["terminal", "desktop"] as const) {
      const ui = await $.ui.mount({
        plugin: "andon",
        surface,
        component: "Pane",
        requestId: "andon-board",
        props: {
          title: "Andon",
          isFocused: true,
          bodyColumns: 100,
          placement: "dock",
          scroll: { offset: 0, bodyRows: 30 },
          view: {}
        }
      });
      expect((await ui.find({ text: /removed --fast flag/ }))?.text).toContain(
        "×2"
      );
      await ui.press({ key: `resolve-${ALERT.id}` });
      const resolve = runs.findLast((r) => r.argv.includes("resolve"));
      expect(resolve?.argv).toEqual(
        expect.arrayContaining([ALERT.id, "--all-matching"])
      );
      await ui.unmount();
    }
  });

  test("a deny from the user's rules stands", async ($, on) => {
    engine(on, { verdict: "deny" });
    await $.session.start(START);
    const { decision } = await $.tool.check({ tool: TOOL, input: {} });
    expect(decision).toBe("deny");
  });

  test("/andon answers with the list where no pane can be drawn", async ($, on) => {
    engine(on, {
      isPlaced: false,
      run: (argv) =>
        argv.includes("list")
          ? result(0, "e790  yellow L3  stale_instruction  deploy SKILL.md\n")
          : fakeCli(3)(argv)
    });
    await $.session.start(START);
    const ran = await $.command.run({
      command: "andon",
      args: "",
      origin: { kind: "composer" },
      presentation: { isFullscreen: false, columns: 80 }
    });
    expect(ran.text).toContain("e790  yellow");
  });
});

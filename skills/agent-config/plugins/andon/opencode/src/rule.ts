// Kept independent of Claude's hooks; see ../CHANGELOG.md for the sharing boundary.
export const TOOL = "andon_pull";
export const DEFAULT_LEVEL = 3;
export const KINDS = [
  "skill_contradiction",
  "rule_conflict",
  "stale_instruction",
  "stuck_loop",
  "tool_anomaly",
  "environment_block",
  "other"
] as const;

export const LEVELS: Record<number, { name: string; when: string }> = {
  1: {
    name: "red only",
    when:
      "Pull `red` when blocked or when an explicitly requested capability is " +
      "unavailable. Never pull `yellow`; work around recoverable issues silently."
  },
  2: {
    name: "conservative",
    when:
      "Pull `red` when blocked or when an explicitly requested capability is " +
      "unavailable. Pull `yellow` only for verified, reproducible defects: a " +
      "direct contradiction between instructions, or a documented flag, script, " +
      "or path confirmed missing via `--help` or the filesystem."
  },
  3: {
    name: "standard",
    when:
      "Pull `red` when blocked or when an explicitly requested capability is " +
      "unavailable. Pull `yellow` when a skill or rule contradicts another " +
      "instruction, names a stale flag, path, or reference, requires an " +
      "undocumented workaround, causes a skill/harness tool, binary, MCP server, " +
      "or subagent to fail at runtime (even on the first attempt if you abandon " +
      "it or switch to an alternative), or causes the same documented step to " +
      "fail twice."
  },
  4: {
    name: "proactive audit",
    when:
      "Everything at Level 3, plus pull `yellow` on the first encounter with " +
      "harness friction: an instruction so vague or underspecified it forced a " +
      "`--help` probe, an unstated prerequisite, or a misleading tool " +
      "description or error."
  },
  5: {
    name: "maximum coverage",
    when:
      "Do not self-filter for severity or confidence. Treat every skill, rule, " +
      "and tool interaction as under active QA audit: pull `yellow` in parallel " +
      "whenever you deviate from, supplement, or double-check any documented " +
      "instruction, flag, or tool behavior — even if resolved on the first try, " +
      "and including transient failures whose retry or timeout behavior was " +
      "undocumented or misleading."
  }
};

export function isLevel(value: unknown): value is number {
  return Number.isInteger(value) && Number(value) >= 1 && Number(value) <= 5;
}

export function levelLabel(level: number): string {
  return `${level} (${LEVELS[level]?.name ?? "unknown"})`;
}

export function buildRule(level: number): string {
  const lines = [
    `# Andon Cord (\`${TOOL}\`)`,
    "",
    "Your instructions (`SKILL.md`, `AGENTS.md`, `CLAUDE.md`), rules, tool schemas, and " +
      "helper scripts are shared across agent sessions and can contain defects. Even when " +
      "you find a clean workaround in this conversation, working around a flaw silently " +
      "means future agent sessions will hit the same broken instruction or tool and waste " +
      `tokens and time rediscovering the fix. Pulling the Andon cord with \`${TOOL}\` ` +
      "records the defect out-of-band so its source can be fixed once, while you continue " +
      "fulfilling the user's request.",
    "",
    "Between tool calls — whenever a command, tool, binary, MCP server, or subagent " +
      "fails, times out, or is unavailable; you run `--help` or inspect a script because " +
      "a documented step did not work as written; or you deviate from or abandon a " +
      "`SKILL.md`, `AGENTS.md`, or `CLAUDE.md` instruction — evaluate the issue against " +
      `the session's trigger level and call \`${TOOL}\`.`,
    "",
    `- **Subagent Accountability:** If a delegated subagent lacks \`${TOOL}\` and reports ` +
      "a tool failure, timeout, or connection/permission block back to you (including " +
      "asynchronously via `<SYSTEM_MESSAGE>`), pull the cord on that turn.",
    "",
    "## How to Pull: Parallel Yellow, Blocking Red",
    "",
    '- **Yellow (`color: "yellow"`) — Workaround and Continue:** A safe workaround or ' +
      `alternative exists that fulfills the user's request. Call \`${TOOL}\` **in the same ` +
      "parallel tool-call batch** as your workaround or next task step, and **continue " +
      "the user's task immediately** without mentioning the defect to the user. Do not " +
      "spend a separate turn on a yellow pull.",
    '- **Red (`color: "red"`) — Blocked or Requested Capability Unavailable:** Call ' +
      `\`${TOOL}\` and **stop work on that path immediately** when either:`,
    "  1. **An explicitly requested capability is unavailable:** A tool, MCP server, or " +
      "subagent that the user explicitly asked you to use (e.g., via a slash command, " +
      "`@` mention, or direct instruction) fails, times out, or cannot connect — **even " +
      "if fallback inputs (such as local files or screenshots) are available**. Do not " +
      "silently substitute a fallback for an explicitly requested capability.",
    "  2. **You cannot proceed safely:** Instructions conflict on an irreversible or " +
      "externally visible action, requirements are circular, or three attempts at the " +
      "same step produced no new diagnostic.",
    "  After pulling `red`, end your turn and tell the user what failed or conflicted, " +
      "what decision you need, and what you completed so far. (Color is severity " +
      "metadata; stopping is your responsibility, not enforced by the harness.)",
    "",
    "## Workaround Precedence and Report Fields",
    "",
    "- **Precedence:** Explicit user instructions and global safety rules outrank skill " +
      "guidelines; the stricter of two verification steps wins; live `--help` output " +
      "beats stale CLI prose (without overriding safety policy).",
    "- **Fields:** Quote the conflicting directive, flag, path, or error in `details`; " +
      "list the affected files, rules, tools, or subagents in `sources` (paths as read); " +
      "put the workaround taken (`yellow`) or decision needed (`red`) in `resolution`; " +
      "and give the concrete edit that would fix the source in `proposed_fix`.",
    "",
    "## Trigger Sensitivity Levels (`1`–`5`)",
    "",
    `Active trigger level: ${levelLabel(level)}.`,
    "",
    "The trigger level is fixed for the session (`$ANDON_LEVEL` > " +
      "`~/.local/state/andon/config.json` via `andon level` or `/andon level` > default " +
      "**Level 3 (standard)**):",
    "",
    ...([1, 2, 3, 4, 5] as const).map(
      (n) => `- **Level ${levelLabel(n)}:** ${LEVELS[n]!.when}`
    ),
    "",
    "## Not a Harness Defect (Do Not Pull)",
    "",
    "- Ordinary compile, lint, type-check, or test failures in repository code you are " +
      "editing or reviewing.",
    "- Normal non-error exit codes (such as `rg`, `grep`, or `diff` returning `1` on no " +
      "matches) or routine sandbox escalations when network or write access is required " +
      "(unless a skill falsely claimed sandbox compatibility).",
    "- Ambiguity in the user's request — ask the user directly.",
    "- At Levels 1–4, a transient failure that succeeds on immediate retry with " +
      "identical arguments."
  ];

  return lines.join("\n");
}

export const DESCRIPTION =
  "Pull the Andon cord to record a defect or friction in your operating harness " +
  "(skills, rules, tool schemas, helper scripts, MCP servers, or subagents) so it " +
  "can be fixed for future sessions instead of worked around silently. Call " +
  "color='yellow' in the same parallel tool-call batch as your workaround and " +
  "continue the user's task without interrupting them. Call color='red' and stop " +
  "immediately when blocked or when a capability explicitly requested by the user " +
  "is unavailable. Evaluate against the session's trigger level under 'Andon Cord' " +
  "in your instructions.";

export const INPUT_SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: ["color", "kind", "summary", "details"],
  properties: {
    color: {
      type: "string",
      enum: ["yellow", "red"],
      description:
        "yellow: worked around it, continuing. red: blocked, asking the user."
    },
    kind: { type: "string", enum: [...KINDS] },
    summary: {
      type: "string",
      maxLength: 120,
      description: "One-line headline."
    },
    details: {
      type: "string",
      description:
        "What conflicted or failed, quoting the directives, flags, paths or errors."
    },
    sources: {
      type: "array",
      items: { type: "string" },
      description:
        "Files, rules or tools involved, e.g. skills/deploy/SKILL.md."
    },
    resolution: {
      type: "string",
      description:
        "Yellow: the workaround taken. Red: the decision or fix needed."
    },
    proposed_fix: {
      type: "string",
      description: "The concrete edit that would remove the defect."
    }
  }
} as const;

export const MODEL_FIELDS = Object.keys(INPUT_SCHEMA.properties);

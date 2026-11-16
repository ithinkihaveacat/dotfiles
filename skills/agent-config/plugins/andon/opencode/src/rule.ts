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
    when: "Pull `red` when blocked or an explicitly requested capability is unavailable; never `yellow`."
  },
  2: {
    name: "conservative",
    when: "Level 1, plus `yellow` for verified instruction contradictions or documented flags, scripts, or paths confirmed missing."
  },
  3: {
    name: "standard",
    when: "Level 2, plus stale references, undocumented workarounds, skill/harness tool, binary, MCP, or subagent runtime failures (even on the first attempt if abandoned), or a documented step failing twice."
  },
  4: {
    name: "proactive audit",
    when: "Level 3, plus first-encounter friction: vague instructions forcing `--help`, unstated prerequisites, or misleading tool descriptions/errors."
  },
  5: {
    name: "maximum coverage",
    when: "Do not self-filter: pull `yellow` in parallel whenever you deviate from, supplement, or double-check any documented instruction, flag, or tool behavior, including undocumented transient retries."
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
    "Instructions (`SKILL.md`, `AGENTS.md`, `CLAUDE.md`), rules, schemas, and helper " +
      "scripts are shared across sessions; silent workarounds leave future sessions to " +
      `rediscover the same flaw. Pull the Andon cord (\`${TOOL}\`) whenever a command, ` +
      "tool, MCP server, or subagent fails or times out, forces an unplanned `--help` or " +
      "script inspection, or makes you deviate from a documented instruction.",
    "",
    `- **Subagent Accountability:** If a subagent lacks \`${TOOL}\` and reports a tool ` +
      "failure, timeout, or connection/permission block (including asynchronously), pull on that turn.",
    "",
    "## How to Pull: Parallel Yellow, Blocking Red",
    "",
    '- **Yellow (`color: "yellow"`):** Safe workaround exists. Call ' +
      `\`${TOOL}\` **in the same parallel tool-call batch** as your workaround and ` +
      "continue immediately without mentioning it to the user — **never spend a standalone turn on a yellow pull**.",
    '- **Red (`color: "red"`):** Stop on that path immediately when (1) an **explicitly ' +
      "requested capability** (slash command, `@` mention, named tool/MCP/subagent) fails " +
      "or cannot connect — even if fallback inputs exist — or (2) instructions conflict on " +
      "an irreversible/external action, requirements are circular, or 3 attempts yield no " +
      "new diagnostic. End your turn and ask the user for a decision (stopping is your responsibility, not host-enforced).",
    "",
    "## Precedence and Fields",
    "",
    "- **Precedence:** User instructions and safety rules outrank skills; stricter checks and live `--help` beat stale prose.",
    "- **Fields:** Set `level` to this defect's 1–5 rubric tier (`<=` active trigger level); " +
      "quote the failing directive/flag/path/error in `details`; list paths, rules, or tools " +
      "in `sources`; put workaround (`yellow`) or decision needed (`red`) in `resolution`; " +
      "give the concrete source edit in `proposed_fix`.",
    "",
    "## Trigger Sensitivity Levels (`1`–`5`)",
    "",
    `Active trigger level: ${levelLabel(level)}.`,
    "Session-fixed (`$ANDON_LEVEL` > `config.json` via `andon level` > `3`):",
    "",
    ...([1, 2, 3, 4, 5] as const).map(
      (n) => `- **Level ${levelLabel(n)}:** ${LEVELS[n]!.when}`
    ),
    "",
    "## Not a Harness Defect (Do Not Pull)",
    "",
    "- Ordinary compile, lint, type-check, or test failures in repository code under edit or review.",
    "- Normal non-error exit codes (`rg`, `grep`, or `diff` returning `1` on no matches) or routine network/write sandbox escalations (unless sandbox support was claimed).",
    "- Ambiguity in the user's request — ask directly.",
    "- At Levels 1–4, a transient failure that succeeds on immediate retry with identical arguments."
  ];

  return lines.join("\n");
}

export const DESCRIPTION =
  "Record a defect in shared instructions, skills, rules, schemas, scripts, MCP servers, " +
  "or subagents. Yellow: call in parallel with your workaround and continue silently. " +
  "Red: stop immediately when blocked or an explicitly requested capability is unavailable. " +
  "See 'Andon Cord' for the session trigger level.";

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
    },
    level: {
      type: "integer",
      minimum: 1,
      maximum: 5,
      description:
        "Intrinsic 1-5 rubric tier of this defect (<= active session trigger level)."
    }
  }
} as const;

export const MODEL_FIELDS = Object.keys(INPUT_SCHEMA.properties);

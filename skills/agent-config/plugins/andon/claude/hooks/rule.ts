// The always-on rule, the tool's description and schema, and the level
// vocabulary. Kept apart from register.tsx so tests can read them directly.

export const TOOL_NAME = "pull";
export const TOOL = "mcp__andon__pull";
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

export const LEVEL_NAMES: Record<number, string> = {
  1: "red-only",
  2: "conservative",
  3: "standard",
  4: "proactive",
  5: "max-coverage"
};

export const LEVELS: Record<number, { name: string; when: string }> = {
  1: {
    name: LEVEL_NAMES[1]!,
    when: "Red blockers and unavailable user-requested capabilities only."
  },
  2: {
    name: LEVEL_NAMES[2]!,
    when: "Verified contradictions, or documented flags, scripts, or paths confirmed missing via `--help` or filesystem."
  },
  3: {
    name: LEVEL_NAMES[3]!,
    when: "Stale references, undocumented workarounds, runtime failures or timeouts in a skill script, tool, binary, MCP server, or subagent (even if abandoned on first try), or a documented step failing twice."
  },
  4: {
    name: LEVEL_NAMES[4]!,
    when: "First-try friction: vague prose forcing `--help` or script inspection, unstated prerequisites, or misleading errors/descriptions."
  },
  5: {
    name: LEVEL_NAMES[5]!,
    when: "Active QA audit: any deviation from, supplement to, or verification of documented steps, flags, or tool behavior, including undocumented transient retries."
  }
};

export function isLevel(value: unknown): value is number {
  return (
    Number.isInteger(value) && (value as number) >= 1 && (value as number) <= 5
  );
}

export function levelLabel(level: number): string {
  return `${level} (${LEVEL_NAMES[level] ?? "unknown"})`;
}

/** The system prompt section, rendered for the level in force. */
export function buildRule(level: number): string {
  const lines = [
    `# Andon Cord (\`${TOOL}\`)`,
    "",
    "Shared instructions (`SKILL.md`, `AGENTS.md`, `CLAUDE.md`), rules, schemas, and scripts " +
      "drift; silent workarounds force future sessions to rediscover fixes. When you hit a " +
      "harness defect or friction, match its intrinsic tier (`1`–`5`) below and call " +
      `\`${TOOL}\` if \`tier <= active trigger level\` (omit secrets from reports).`,
    "",
    `- **Subagent Accountability:** If a subagent lacks \`${TOOL}\` and reports a tool ` +
      "failure, timeout, or block, pull on that turn.",
    "",
    "## Parallel Yellow vs. Blocking Red",
    "",
    '- **Yellow (`color: "yellow"`):** Safe workaround exists. Call ' +
      `\`${TOOL}\` in the same parallel tool-call batch as your workaround and ` +
      "continue without mentioning the pull (never use a standalone turn).",
    '- **Red (`color: "red"`):** Pull `red`, stop on the blocked path, and ask the user how ' +
      "to proceed when: (1) an explicitly requested capability (tool, MCP server, subagent, " +
      "slash command, or `@` mention) fails or is unavailable — ask rather than substituting a " +
      "fallback, even if local inputs exist; or (2) instructions conflict on an " +
      "irreversible/external action, requirements are circular, or 3 tries yield no new " +
      "diagnostic. Finish independent safe work first, then end your turn.",
    "",
    "## Precedence",
    "",
    "Host safety rules and explicit user instructions outrank skills; stricter checks win; " +
      "live `--help` outranks stale CLI flag docs (never safety policy).",
    "",
    "## Trigger Sensitivity Levels (`1`–`5`)",
    "",
    `Active trigger level: ${levelLabel(level)}. Session-fixed (\`$ANDON_LEVEL\` > \`config.json\` > \`3\`).`,
    "Pull when the defect's intrinsic `level` (`1`–`5`) `<=` active trigger level:",
    "",
    ...([1, 2, 3, 4, 5] as const).map(
      (n) => `- **${n} (\`${LEVELS[n]!.name}\`):** ${LEVELS[n]!.when}`
    ),
    "",
    "## Out of Scope (Skip Pulling)",
    "",
    "- Compile, lint, type, or test failures in repo code under edit or review.",
    "- Expected non-zero exits (`rg`, `grep`, or `diff` returning `1` on no match) or routine sandbox escalations (unless sandbox support was claimed).",
    "- Ambiguity in the user's prompt — ask directly.",
    "- Transient failures at Levels 1–4 that succeed on immediate identical retry, or unconfirmed `pull` writes (check the store before retrying)."
  ];

  return lines.join("\n");
}

export const DESCRIPTION =
  "Pull the Andon Cord to log a harness defect in skills, rules, schemas, scripts, MCP servers, " +
  "or subagents. Yellow: batch in parallel with your workaround and continue silently. " +
  "Red: stop on the blocked path and ask the user. Follow the Andon Cord trigger level; " +
  "do not retry unconfirmed writes.";

/**
 * Kept short: the rule carries the guidance (a long description is skimmed),
 * and the level in force, so the description never goes stale.
 */
export function buildDescription(): string {
  return DESCRIPTION;
}

export const INPUT_SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: ["color", "kind", "summary", "details"],
  properties: {
    color: {
      type: "string",
      enum: ["yellow", "red"],
      description:
        "yellow: worked around, continuing. red: blocked, asking user."
    },
    kind: { type: "string", enum: [...KINDS] },
    summary: {
      type: "string",
      minLength: 1,
      maxLength: 120,
      description: "One-line defect headline."
    },
    details: {
      type: "string",
      minLength: 1,
      description:
        "Verbatim directive, flag, path, or error that conflicted or failed."
    },
    sources: {
      type: "array",
      items: { type: "string" },
      description:
        "Affected files, rules, tools, or subagents (keys deduplication)."
    },
    resolution: {
      type: "string",
      description: "Yellow: workaround taken. Red: user decision needed."
    },
    proposed_fix: {
      type: "string",
      description: "Concrete source edit to fix the defect."
    },
    level: {
      type: "integer",
      minimum: 1,
      maximum: 5,
      description:
        "Intrinsic defect tier from the Andon rubric (<= session trigger level)."
    }
  }
} as const;

export const MODEL_FIELDS = Object.keys(INPUT_SCHEMA.properties);

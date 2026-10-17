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

export const LEVELS: Record<number, { name: string; when: string }> = {
  1: {
    name: "red only",
    when: "Never pull yellow. Pull red only when blocked."
  },
  2: {
    name: "conservative",
    when:
      "Pull yellow only for a verified defect: a direct contradiction, or a " +
      "documented flag, path or script confirmed missing (by --help or the " +
      "filesystem)."
  },
  3: {
    name: "standard",
    when:
      "Pull yellow when a skill or rule contradicts another instruction, names " +
      "a stale flag, path or reference, needs an undocumented workaround, or " +
      "the same documented step failed twice."
  },
  4: {
    name: "proactive audit",
    when:
      "Everything at level 3, plus the first sign of friction: a step so vague " +
      "it forced a --help probe, an unstated prerequisite, or a misleading " +
      "tool error."
  },
  5: {
    name: "maximum coverage",
    when:
      "Do not self-filter for severity or confidence. Treat every skill, rule " +
      "and tool interaction as under QA audit: pull yellow whenever you " +
      "deviate from, supplement or double-check a documented instruction."
  }
};

export function isLevel(value: unknown): value is number {
  return (
    Number.isInteger(value) && (value as number) >= 1 && (value as number) <= 5
  );
}

/**
 * Finds a level change the person asked for: a message that starts with it
 * ("andon level 5", "set andon level to 2", "andon level default"). A message
 * that only talks about a level ("what does andon level 5 do?") is no request.
 */
export function parseLevelRequest(text: string): number | "default" | null {
  const match =
    /^\s*(?:set |use |switch to )?andon\s+level\s+(?:to\s+)?([1-5]|default|reset)\b/i.exec(
      text
    );
  if (match === null) return null;
  const value = match[1]!.toLowerCase();

  return value === "default" || value === "reset" ? "default" : Number(value);
}

export function levelLabel(level: number): string {
  return `${level} (${LEVELS[level]?.name ?? "unknown"})`;
}

/** The system prompt section, rendered for the level in force. */
export function buildRule(level: number, isSessionLevel: boolean): string {
  const lines = [
    "# Andon cord",
    "",
    "Your instructions, skills, rules, tool descriptions and helper scripts " +
      "can be wrong. When they are, pull the Andon cord with the " +
      `\`${TOOL}\` tool, so the defect is fixed at its source instead of ` +
      "being rediscovered by every later session.",
    "",
    `Active trigger level: ${levelLabel(level)}` +
      (isSessionLevel ? ", set by the user for this conversation. " : ". ") +
      LEVELS[level]!.when,
    "",
    "Between tool calls — whenever a command or tool fails after you followed " +
      "a skill or rule, you run `--help` or read a script because a documented " +
      "step did not work as written, or you deviate from a SKILL.md, AGENTS.md " +
      "or CLAUDE.md instruction — check the level above and pull if it applies.",
    "",
    "- Yellow (a safe workaround exists): call the pull tool in the same " +
      "parallel tool-call batch as your workaround and carry on. Do not spend " +
      "a separate turn on it and do not mention it to the user.",
    "- Red (blocked: instructions conflict on an irreversible or externally " +
      "visible action, requirements are circular, or three attempts at one " +
      "step gave no new diagnostic): pull, stop work on that path, and tell the " +
      "user what conflicted and what decision you need.",
    "",
    "Choosing a workaround: the user’s and global safety rules outrank skill " +
      "text; the stricter of two verification steps wins; live `--help` output " +
      "beats stale prose. In the pull, quote the conflicting text, flag, path or " +
      "error in `details`; name the files, rules or tools involved in " +
      "`sources` (paths as you read them); put the workaround (yellow) or the " +
      "decision needed (red) in `resolution`, and the edit that would remove " +
      "the defect in `proposed_fix`.",
    ""
  ];
  if (level < 5) {
    lines.push(
      "Do not pull for: ordinary compile, lint or test failures in the code " +
        "you are editing; ambiguity in the user’s request (ask them); a " +
        "transient failure that succeeds on retry.",
      ""
    );
  }
  lines.push(
    "Levels: 1 red only, 2 conservative, 3 standard, 4 proactive audit, " +
      "5 maximum coverage. The user changes the level for this conversation " +
      'by starting a message with "andon level 5" or with `/andon level 5`; this section ' +
      "always shows the level in force, including after compaction."
  );

  return lines.join("\n");
}

/**
 * Kept short: the rule carries the guidance (a long description is skimmed),
 * and the level in force, so the description never goes stale.
 */
export function buildDescription(): string {
  return (
    "Pull the Andon cord: report a defect in your own instructions, skills, " +
    "rules or tools (a contradiction, a stale flag or path, a misbehaving " +
    "tool, a loop you cannot break). Yellow: call it in parallel with your " +
    "workaround and continue. Red: you are blocked; stop and ask the user. " +
    'See "Andon cord" in your instructions for when to pull.'
  );
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
        "The trigger level you pulled at; defaults to the active level."
    }
  }
} as const;

export const MODEL_FIELDS = Object.keys(INPUT_SCHEMA.properties);

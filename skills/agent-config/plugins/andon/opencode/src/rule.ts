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

const LEVELS: Record<number, string> = {
  1: "Red only: never pull yellow. Pull red only when blocked.",
  2: "Conservative: pull yellow only for a verified contradiction or a documented flag, path or script confirmed missing by --help or the filesystem.",
  3: "Standard: pull yellow for contradictory instructions, stale flags, paths or references, undocumented workarounds, or the same documented step failing twice.",
  4: "Proactive audit: everything at level 3, plus vague steps that force a --help probe, unstated prerequisites, or misleading tool errors.",
  5: "Maximum coverage: do not self-filter for severity or confidence. Pull yellow whenever you deviate from, supplement or double-check a documented instruction."
};

export function isLevel(value: unknown): value is number {
  return Number.isInteger(value) && Number(value) >= 1 && Number(value) <= 5;
}

export function buildRule(level: number): string {
  return [
    "# Andon cord",
    `Your instructions, skills, rules, tool descriptions and helper scripts can be wrong. Report defects with \`${TOOL}\` so their source can be fixed for later sessions.`,
    `Active trigger level: ${level}. ${LEVELS[level]}`,
    "Between tool calls, check this level when following a skill or rule fails, when you probe --help or read a script because a documented step did not work, or when you deviate from SKILL.md or AGENTS.md.",
    "Yellow (a safe workaround exists): pull in the same parallel batch as your workaround and continue. Do not spend a separate turn on it or mention it to the user.",
    "Red (blocked): pull, stop on that path, and explain the blocker and decision needed. Examples: conflicting instructions for an irreversible or externally visible action, circular requirements, or three attempts with no new diagnostic. Color is guidance, not an enforced execution stop.",
    "User and global safety rules outrank skill text. Prefer the stricter verification step; use live --help to verify documented CLI syntax, not to override safety policy. Quote the conflicting text, flag, path or error in details, name the sources as you read them, record the workaround or decision needed in resolution, and suggest a source fix in proposed_fix.",
    ...(level < 5
      ? [
          "Do not pull for ordinary compile, lint or test failures in code you are editing, ambiguity in the user's request (ask them), or transient failures that succeed on retry."
        ]
      : []),
    [
      "Trigger levels (fixed for the session; configured via `andon level` or `/andon level`):",
      ...([1, 2, 3, 4, 5] as const).map((n) => `- Level ${n}: ${LEVELS[n]}`)
    ].join("\n")
  ].join("\n\n");
}

export const DESCRIPTION =
  "Pull the Andon cord: report a defect in your own instructions, skills, rules or tools. Yellow: call in parallel with your workaround and continue. Red: blocked; stop on that path and ask the user. See the Andon cord instructions for the active trigger level.";

export const INPUT_SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: ["color", "kind", "summary", "details"],
  properties: {
    color: { type: "string", enum: ["yellow", "red"] },
    kind: { type: "string", enum: [...KINDS] },
    summary: {
      type: "string",
      maxLength: 120,
      description: "One-line headline."
    },
    details: {
      type: "string",
      description: "Quote the conflicting instructions, flags, paths or errors."
    },
    sources: {
      type: "array",
      items: { type: "string" },
      description: "Files, rules or tools involved, as read."
    },
    resolution: {
      type: "string",
      description: "Workaround taken (yellow) or decision needed (red)."
    },
    proposed_fix: {
      type: "string",
      description: "The concrete edit that would remove the defect."
    }
  }
} as const;

export const MODEL_FIELDS = Object.keys(INPUT_SCHEMA.properties);

import { TOOL } from "./rule.ts";

export type Observation = {
  tool: string;
  input: unknown;
  failed: boolean;
  level: number;
};

export function createSensor() {
  const skills: string[] = [];
  const failures = new Map<string, number>();
  const nudged = new Set<string>();
  let lastFailed = false;

  function nudge(key: string, reason: string): string | null {
    if (nudged.has(key) || nudged.size >= 5) return null;
    nudged.add(key);
    return `Andon: ${reason} If documented instructions were wrong or stale, pull ${TOOL} (yellow) in the same batch as your workaround; otherwise ignore this.`;
  }

  return {
    observe({ tool, input, failed, level }: Observation): string | null {
      if (tool === TOOL) {
        lastFailed = false;
        return null;
      }
      if (!input || typeof input !== "object") return null;
      const args = input as Record<string, unknown>;
      if (
        !failed &&
        tool === "read" &&
        typeof args.path === "string" &&
        /(?:^|\/)SKILL\.md$/.test(args.path)
      ) {
        const directory = args.path.slice(0, -"/SKILL.md".length);
        if (!skills.includes(directory)) skills.unshift(directory);
        skills.length = Math.min(skills.length, 20);
      }
      if (!failed && tool === "skill" && typeof args.id === "string") {
        if (!skills.includes(args.id)) skills.unshift(args.id);
        skills.length = Math.min(skills.length, 20);
      }
      if (level === 1 || tool !== "shell" || typeof args.command !== "string")
        return null;
      const command = args.command.trim();
      const wasFailed = lastFailed;
      lastFailed = failed;
      if (!failed) {
        return wasFailed && /(?:^|\s)(?:--help|-h)(?:\s|$)/.test(command)
          ? nudge(
              `help:${command.split(/\s+/)[0]}`,
              "you probed --help after a command failed."
            )
          : null;
      }
      const count = (failures.get(command) ?? 0) + 1;
      // Bound long-lived sessions without dropping the most recent failure.
      if (failures.size >= 100 && !failures.has(command))
        failures.delete(failures.keys().next().value!);
      failures.set(command, count);
      const skill = skills.find(
        (path) =>
          command.includes(path) ||
          command.includes(`${path.split("/").at(-1)}/`)
      );
      if (skill)
        return nudge(
          `skill:${skill}`,
          `a command failed after you read the skill ${skill}.`
        );
      return count >= 2
        ? nudge(`repeat:${command}`, "the same command has failed twice.")
        : null;
    }
  };
}

/** A nonzero shell exit is often a completed tool call, not a Tool.Error. */
export function shellFailed(result: {
  content?: unknown;
  metadata?: Record<string, unknown>;
}): boolean {
  const code = result.metadata?.exitCode ?? result.metadata?.exit_code;
  if (typeof code === "number") return code !== 0;
  const text =
    typeof result.content === "string"
      ? result.content
      : Array.isArray(result.content)
        ? result.content
            .filter((item) => item.type === "text")
            .map((item) => item.text)
            .join("\n")
        : "";
  // Match the shell tool's trailing status line, not arbitrary output containing "error".
  const match = /(?:^|\n)Exited with code (\d+)\s*$/.exec(text);
  return match !== null && Number(match[1]) !== 0;
}

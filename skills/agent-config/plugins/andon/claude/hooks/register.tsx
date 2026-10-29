import { atom, read, update } from "claude-code";
import type { EngineInterface, Register } from "claude-code";

import type { AndonAlert, AndonCounts, AndonFilter } from "../types";
import {
  DEFAULT_LEVEL,
  INPUT_SCHEMA,
  MODEL_FIELDS,
  TOOL,
  TOOL_NAME,
  buildDescription,
  buildRule,
  isLevel,
  levelLabel
} from "./rule";
import { createSensor } from "./sensor";

type Engine = EngineInterface;

const PANE = "andon-board";
const REFRESH_MS = 60_000;
const CLI_TIMEOUT_MS = 15_000;

const defaultLevel = atom(
  { plugin: "andon", key: "defaultLevel" } as const,
  DEFAULT_LEVEL
);
const counts = atom({ plugin: "andon", key: "counts" } as const, {
  open: 0,
  red: 0
});
const board = atom({ plugin: "andon", key: "board" } as const, []);
const filter = atom({ plugin: "andon", key: "filter" } as const, "open");
const isSessionOnly = atom(
  { plugin: "andon", key: "isSessionOnly" } as const,
  false
);
const notice = atom({ plugin: "andon", key: "notice" } as const, null);

const FILTERS: { value: AndonFilter; label: string }[] = [
  { value: "open", label: "Open" },
  { value: "red", label: "Red" },
  { value: "yellow", label: "Yellow" },
  { value: "closed", label: "Closed" },
  { value: "all", label: "All" }
];

/** Background work that outlives its dispatch: a failure there is not the caller's. */
function quietly(work: Promise<unknown>): void {
  work.catch(() => undefined);
}

// --- The shared CLI: the one reader and writer of the alert store ----------

type CliResult = { ok: boolean; stdout: string; error: string };

/**
 * The skill's own CLI (this plugin is skills/agent-config/plugins/andon/claude),
 * else `andon` on PATH for a copy installed away from the repository.
 */
async function cliPath($: Engine): Promise<string> {
  const skillScript = `${$.plugin.root}/../../../scripts/andon`;

  return (await $.fs.exists(skillScript)) ? skillScript : "andon";
}

async function cli(
  $: Engine,
  args: string[],
  stdin?: string
): Promise<CliResult> {
  const path = await cliPath($);
  // The CLI is a uv script using the standard library alone: where uv is
  // missing from the host's PATH (exit 127 from env), python3 runs it as well.
  const attempts = [
    [path, ...args],
    ["python3", path, ...args]
  ];
  let error = "";
  for (const argv of attempts) {
    try {
      const ran = await $.process.run(argv, {
        stdin,
        timeoutMs: CLI_TIMEOUT_MS
      });
      if (ran.exitCode === 0)
        return { ok: true, stdout: ran.stdout, error: "" };
      error = ran.stderr.trim() || `${argv[0]} exited ${ran.exitCode}`;
      if (ran.exitCode !== 127) break;
    } catch (err) {
      error = `cannot run ${argv[0]}: ${String(err)}`;
    }
  }

  return { ok: false, stdout: "", error };
}

async function cliJson<T>($: Engine, args: string[]): Promise<T | null> {
  const ran = await cli($, args);
  if (!ran.ok) return null;
  try {
    return JSON.parse(ran.stdout) as T;
  } catch {
    return null;
  }
}

// --- Level, counts and the board ---------------------------------------------

let levelLocked = false;
let initialLoad: Promise<void> | null = null;

async function showStatus($: Engine): Promise<void> {
  const level = await read($, defaultLevel);
  const { open, red } = await read($, counts);
  if (open === 0 && level === DEFAULT_LEVEL) {
    $.ui.status(undefined);

    return;
  }
  // The engine heads the line with the plugin name ("andon: ").
  const parts = [`L${level}`];
  if (open > 0) parts.push(`${open} open`);
  if (red > 0) parts.push(`${red} red`);
  $.ui.status(parts.join(" · "));
}

// Where the CLI keeps the store, from `stats --json`, and the store's files'
// mtimes when last read: the timer runs the CLI only when they change.
let stateDir: string | null = null;
let seenStamps = "";

async function storeChanged($: Engine): Promise<boolean> {
  if (stateDir === null) return true;
  const dir = stateDir;
  const files = levelLocked
    ? ["events.jsonl"]
    : ["events.jsonl", "config.json"];
  const stamps = await Promise.all(
    files.map((name) =>
      $.fs.stat(`${dir}/${name}`).then(
        (stat) => String(stat.mtimeMs),
        () => "-"
      )
    )
  );
  const key = stamps.join(",");
  if (key === seenStamps) return false;
  seenStamps = key;

  return true;
}

async function isBoardOpen($: Engine): Promise<boolean> {
  return (await $.ui.panes()).some((pane) => pane.id === PANE);
}

async function refreshCounts($: Engine): Promise<void> {
  const stats = await cliJson<{
    open: number;
    open_red: number;
    level: number;
    state_dir?: string;
  }>($, ["stats", "--json"]);
  if (stats === null) return;
  if (typeof stats.state_dir === "string") stateDir = stats.state_dir;
  const next: AndonCounts = { open: stats.open, red: stats.open_red };
  const was = await read($, counts);
  if (was.open !== next.open || was.red !== next.red) {
    await update($, counts, () => next);
    // Another session's pull or resolve: keep an open board's rows in step
    // with its header.
    if (await isBoardOpen($)) await refreshBoard($);
  }
  if (!levelLocked && isLevel(stats.level)) {
    levelLocked = true;
    if (stats.level !== (await read($, defaultLevel))) {
      await update($, defaultLevel, () => stats.level);
    }
  }
  await showStatus($);
}

async function ensureLockedLevel($: Engine): Promise<number> {
  if (!levelLocked && initialLoad !== null) await initialLoad;
  levelLocked = true;

  return read($, defaultLevel);
}

async function refreshBoard($: Engine): Promise<void> {
  const chosen = await read($, filter);
  const args = [
    "list",
    "--json",
    "--status",
    chosen === "open" || chosen === "red" || chosen === "yellow"
      ? "open"
      : "all"
  ];
  if (chosen === "red" || chosen === "yellow") args.push("--color", chosen);
  if (await read($, isSessionOnly))
    args.push("--session", await $.session.id());
  const alerts = await cliJson<AndonAlert[]>($, args);
  if (alerts === null) {
    await update(
      $,
      notice,
      () => "Could not read the alert store; see `andon list`."
    );

    return;
  }
  const rows =
    chosen === "closed" ? alerts.filter((a) => a.status !== "open") : alerts;
  await update($, board, () => rows);
}

// --- The pull tool -----------------------------------------------------------

type PullResponse = {
  ok: boolean;
  id?: string;
  color?: string;
  fingerprint?: string;
  recurrences?: number;
  guidance: string;
  error?: string;
};

const FALLBACK_GUIDANCE: Record<string, string> = {
  yellow: "Continue with your chosen workaround; do not interrupt the user.",
  red: "Stop work on the blocked path and explain the blocker and the decision you need to the user."
};

async function pull(
  $: Engine,
  e: Record<string, unknown>
): Promise<PullResponse> {
  const fields: Record<string, unknown> = {};
  for (const key of MODEL_FIELDS)
    if (e[key] !== undefined) fields[key] = e[key];
  const level = await ensureLockedLevel($);
  const cwd = await $.session.cwd();
  const root = await $.session.root();
  const payload = {
    ...fields,
    level,
    harness: "claude-code",
    conversation_id: await $.session.id(),
    agent_id: typeof e.agentId === "string" ? e.agentId : undefined,
    tool_use_id: typeof e.tool_use_id === "string" ? e.tool_use_id : undefined,
    step_idx: await $.session.turns(),
    workspace_paths: root === cwd ? [cwd] : [cwd, root],
    model_name: await $.session.model()
  };
  const ran = await cli($, ["pull", "--json", "-"], JSON.stringify(payload));
  const color = String(fields.color);
  if (!ran.ok) {
    $.ui.toast(`Andon: the alert was not saved (${ran.error.slice(0, 120)})`);

    return {
      ok: false,
      error: ran.error,
      guidance: `The alert was not saved; mention the defect to the user at the end of your turn. ${FALLBACK_GUIDANCE[color] ?? ""}`
    };
  }
  let response: PullResponse;
  try {
    response = JSON.parse(ran.stdout) as PullResponse;
  } catch {
    // The CLI exited 0, so the alert is saved: say so, or the model pulls again.
    return {
      ok: true,
      guidance: `The alert was saved, but its response was unreadable; do not pull again. ${FALLBACK_GUIDANCE[color] ?? ""}`
    };
  }
  const times =
    (response.recurrences ?? 1) > 1 ? ` (×${response.recurrences} open)` : "";
  $.ui.toast(
    `Andon ${color}: ${String(fields.summary ?? "").slice(0, 80)}${times}`
  );
  quietly(refreshCounts($));

  return response;
}

// --- The board -------------------------------------------------------------

function age(createdAt: string, nowMs: number): string {
  const minutes = Math.max(
    0,
    Math.round((nowMs - Date.parse(createdAt)) / 60_000)
  );
  if (minutes < 60) return `${minutes}m`;
  if (minutes < 48 * 60) return `${Math.round(minutes / 60)}h`;

  return `${Math.round(minutes / 1440)}d`;
}

/** The newest alert of each fingerprint, carrying how many share it. */
function groupByFingerprint(alerts: readonly AndonAlert[]): AndonAlert[] {
  const seen = new Set<string>();

  return alerts.filter((a) => {
    if (seen.has(a.fingerprint)) return false;
    seen.add(a.fingerprint);

    return true;
  });
}

async function act(
  $: Engine,
  verb: "resolve" | "dismiss" | "reopen",
  alert: AndonAlert
): Promise<void> {
  const args = [verb, alert.id, "--all-matching"];
  if (verb !== "reopen")
    args.push(
      "--note",
      `${verb === "resolve" ? "Resolved" : "Dismissed"} from the Andon board`
    );
  const ran = await cli($, args);
  const past = {
    resolve: "Resolved",
    dismiss: "Dismissed",
    reopen: "Reopened"
  }[verb];
  await update($, notice, () =>
    ran.ok ? `${past} ${alert.id}.` : `${verb} failed: ${ran.error}`
  );
  await refreshBoard($);
  await refreshCounts($);
}

async function copyPrompt(
  $: Engine,
  alert: AndonAlert,
  surface: Parameters<Engine["ui"]["copy"]>[0]["surface"]
): Promise<void> {
  const ran = await cli($, ["prompt", alert.id]);
  if (!ran.ok) {
    await update($, notice, () => `prompt failed: ${ran.error}`);

    return;
  }
  const copied = await $.ui.copy({ text: ran.stdout, surface });
  await update($, notice, () =>
    copied.isCopied
      ? `Copied the fix prompt for ${alert.id}. Paste it into a fresh session.`
      : `Could not copy (${copied.reason}); run: andon prompt ${alert.id}`
  );
}

// --- The /andon command ----------------------------------------------------

const USAGE = [
  "Usage: /andon [board|list|stats|level [1-5|default|reset]]",
  "",
  "  /andon              open the Andon board",
  "  /andon list         list open alerts from every session",
  "  /andon stats        counts, top sources and top fingerprints",
  "  /andon level        show the trigger level in force",
  "  /andon level 5      set the default level for new sessions",
  "  /andon level reset  reset the default level to 3"
].join("\n");

async function runCommand($: Engine, args: string): Promise<string> {
  const words = args.trim().split(/\s+/).filter(Boolean);
  const verb = words[0] ?? "board";
  if (verb === "board") {
    await refreshBoard($);
    const opened = await $.ui.open({ id: PANE, title: "Andon" });
    if (opened.isPlaced) return "Andon board opened.";
    // No surface draws panes here (VS Code, -p): answer with the list instead.
    const ran = await cli($, ["list"]);

    return ran.ok
      ? ran.stdout.trimEnd() || "No open Andon alerts."
      : `andon list failed: ${ran.error}`;
  }
  if (verb === "list" || verb === "stats") {
    const ran = await cli($, verb === "list" ? ["list"] : ["stats"]);

    return ran.ok
      ? ran.stdout.trimEnd() || "No open Andon alerts."
      : `andon ${verb} failed: ${ran.error}`;
  }
  if (verb !== "level" || words.length > 2) return USAGE;
  const value = words[1];
  if (value === undefined) {
    const level = await ensureLockedLevel($);

    return `Andon level ${levelLabel(level)}.`;
  }
  if (value === "default" || value === "reset") {
    const ran = await cli($, ["level", "--reset"]);
    if (!ran.ok) return `andon level failed: ${ran.error}`;

    return `Andon default level reset to ${levelLabel(DEFAULT_LEVEL)} (applies to new sessions).`;
  }
  const level = Number(value);
  if (!isLevel(level)) return USAGE;
  const ran = await cli($, ["level", String(level)]);
  if (!ran.ok) return `andon level failed: ${ran.error}`;

  return `Andon default level set to ${levelLabel(level)} (applies to new sessions).`;
}

// --- Hooks -------------------------------------------------------------------

export const register: Register = (on) => {
  const sensor = createSensor();

  on("session.start", async ($, e, next) => {
    const started = await next(e);
    levelLocked = false;
    initialLoad = null;
    // Awaited before the first prompt, so nothing here waits on the CLI: the
    // counts and the default level arrive in the background.
    await $.tool.register({
      name: TOOL_NAME,
      description: buildDescription(),
      inputSchema: INPUT_SCHEMA,
      isDeferred: false
    });
    await $.command.register({
      name: "andon",
      description: "Andon board, alerts and trigger level",
      argumentHint: "[board|list|stats|level [1-5|default|reset]]"
    });
    initialLoad = refreshCounts($);
    quietly(initialLoad);
    $.clock.every(REFRESH_MS, () =>
      quietly(
        storeChanged($).then((changed) =>
          changed ? refreshCounts($) : undefined
        )
      )
    );

    return started;
  });

  // The always-on rule. Only where the tool is offered: a rule naming a tool
  // the request lacks would send the model after something that is not there.
  on("prompt.compose", async ($, e, next) => {
    const composed = await next(e);
    if (!e.tools.includes(TOOL)) return composed;
    const level = await ensureLockedLevel($);

    return {
      sections: [
        ...composed.sections,
        {
          id: "andon:rule",
          text: buildRule(level),
          scope: "session" as const
        }
      ]
    };
  });

  // A pull the user has to approve is a pull that will not happen, so an
  // 'ask' becomes 'allow'. A deny from the user's rules or mode stands.
  on("tool.check", { tool: "mcp__andon__pull" }, async ($, e, next) => {
    const verdict = await next(e);

    return verdict.decision === "ask"
      ? { ...verdict, decision: "allow" as const }
      : verdict;
  }).catch(($, e, next) => next(e));

  on("tool.call", { tool: "mcp__andon__pull" }, async ($, e) => {
    const response = await pull($, e as unknown as Record<string, unknown>);

    return { result: JSON.stringify(response) };
  }).catch(($, e) => ({
    result: JSON.stringify({
      ok: false,
      error: `${$.plugin.name}: the pull failed (${e.tool_use_id})`,
      guidance:
        "The alert was not saved; mention the defect to the user at the end of your turn, then continue as the rule says."
    })
  }));

  // The sensor reads every tool call's outcome; it only ever adds a reminder.
  on("tool.call", async ($, e, next) => {
    const ran = await next(e);
    // Main loop only: a subagent's tool list may lack the pull tool, and its
    // failures are not the main loop's pattern.
    if (ran.deny !== undefined || e.agentId !== undefined) return ran;
    const level = await read($, defaultLevel);
    const reminder = sensor.observe({
      tool: e.tool,
      input: e as unknown as Record<string, unknown>,
      isError: ran.isError === true,
      level
    });

    return reminder === null
      ? ran
      : { ...ran, context: [...(ran.context ?? []), reminder] };
  }).catch(($, e, next) => next(e));

  on("command.run", { command: "andon" }, async ($, e) => ({
    text: await runCommand($, e.args)
  }));

  on("ui.render", { component: "Pane", requestId: PANE }, async ($, e) => {
    const { Box, Text, Button } = $.ui.resolve(e);
    const alerts = groupByFingerprint(await read($, board));
    const chosen = await read($, filter);
    const sessionOnly = await read($, isSessionOnly);
    const { open, red } = await read($, counts);
    const level = await read($, defaultLevel);
    const line = await read($, notice);
    const nowMs = await $.clock.now();
    const room = Math.max(1, Math.floor(((e.viewport?.rows ?? 30) - 6) / 4));

    return (
      <Box flexDirection="column">
        <Text bold>
          Andon · level {level} · {open} open, {red} red
        </Text>
        <Box flexDirection="row" gap={1}>
          {FILTERS.map((f) => (
            <Button
              key={`filter-${f.value}`}
              label={f.label}
              variant={f.value === chosen ? "primary" : "secondary"}
              onPress={() =>
                quietly(
                  update($, filter, () => f.value).then(() => refreshBoard($))
                )
              }
            />
          ))}
          <Button
            key="session-only"
            label={sessionOnly ? "This session" : "All sessions"}
            onPress={() =>
              quietly(
                update($, isSessionOnly, (was) => !was).then(() =>
                  refreshBoard($)
                )
              )
            }
          />
          <Button
            key="refresh"
            label="Refresh"
            onPress={() => quietly(refreshBoard($))}
          />
        </Box>
        {line !== null && <Text dimColor>{line}</Text>}
        {alerts.length === 0 && <Text dimColor>No alerts here.</Text>}
        {alerts.slice(0, room).map((alert) => (
          <Box key={`alert-${alert.id}`} flexDirection="column" marginTop={1}>
            <Text>
              <Text color={alert.color === "red" ? "error" : "warning"} bold>
                {alert.color === "red" ? "■ red   " : "■ yellow"}
              </Text>{" "}
              {alert.summary}
              {alert.recurrences > 1 ? (
                <Text bold> ×{alert.recurrences}</Text>
              ) : (
                ""
              )}
            </Text>
            <Text dimColor>
              {alert.kind} · L{alert.level} · {age(alert.created_at, nowMs)} ago
              · {alert.id.slice(-4)}
              {alert.status === "open" ? "" : ` · ${alert.status}`}
              {alert.sources.length > 0 ? ` · ${alert.sources.join(", ")}` : ""}
            </Text>
            <Box flexDirection="row" gap={1}>
              <Button
                key={`prompt-${alert.id}`}
                label="Copy fix prompt"
                onPress={(press) =>
                  quietly(copyPrompt($, alert, press.surface))
                }
              />
              {alert.status === "open" ? (
                <>
                  <Button
                    key={`resolve-${alert.id}`}
                    label="Resolve"
                    onPress={() => quietly(act($, "resolve", alert))}
                  />
                  <Button
                    key={`dismiss-${alert.id}`}
                    label="Dismiss"
                    onPress={() => quietly(act($, "dismiss", alert))}
                  />
                </>
              ) : (
                <Button
                  key={`reopen-${alert.id}`}
                  label="Reopen"
                  onPress={() => quietly(act($, "reopen", alert))}
                />
              )}
            </Box>
          </Box>
        ))}
        {alerts.length > room && (
          <Text dimColor>
            …and {alerts.length - room} more; see `andon list`.
          </Text>
        )}
      </Box>
    );
  });
};

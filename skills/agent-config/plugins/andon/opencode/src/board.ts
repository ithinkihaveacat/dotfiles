import type { Context } from "@opencode/plugin/tui/context";
import { Andon } from "./rpc.ts";
import type { Alert, Snapshot, TextResponse } from "./types.ts";

export type Filter = "open" | "red" | "yellow" | "closed" | "all";

export function boardRows(
  alerts: Alert[],
  filter: Filter,
  sessionID?: string
): Alert[] {
  const seen = new Set<string>();
  return alerts.filter((alert) => {
    if (sessionID && alert.conversation_id !== sessionID) return false;
    if (filter === "closed" && alert.status === "open") return false;
    if (["open", "red", "yellow"].includes(filter) && alert.status !== "open")
      return false;
    if ((filter === "red" || filter === "yellow") && alert.color !== filter)
      return false;
    const key = `${alert.fingerprint}:${alert.status}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

export async function setupBoard(
  context: Context,
  update: (snapshot: Snapshot | null, error: string) => void
) {
  const rpc = context.client.rpc(Andon);
  const controller = new AbortController();
  let serial = 0;
  let lastError = "";
  let snapshot: Snapshot | null = null;
  let filter: Filter = "open";
  let sessionOnly = false;
  let boardOpen = false;

  function sessionID() {
    const route = context.ui.router.current();
    return route.type === "session" ? route.sessionID : undefined;
  }

  function options() {
    const id = sessionID();
    return {
      signal: controller.signal,
      location:
        (id ? context.data.session.get(id)?.location : undefined) ??
        context.location ??
        context.data.location.default()
    };
  }

  function failed(error: unknown) {
    if (controller.signal.aborted) return;
    const message = String(error);
    snapshot = null;
    update(null, message);
    if (message !== lastError)
      context.ui.toast.show({ title: "Andon", message, variant: "error" });
    lastError = message;
  }

  async function refresh() {
    const request = ++serial;
    const id = sessionID();
    try {
      const next = (await rpc.snapshot(
        { sessionID: id },
        options()
      )) as Snapshot;
      if (request !== serial || id !== sessionID() || controller.signal.aborted)
        return;
      snapshot = next;
      lastError = "";
      update(next, "");
    } catch (error) {
      if (request === serial) failed(error);
    }
  }

  async function board() {
    if (boardOpen) return;
    boardOpen = true;
    try {
      while (!controller.signal.aborted) {
        await refresh();
        if (!snapshot) return;
        const current = snapshot as Snapshot;
        const rows = boardRows(
          current.alerts,
          filter,
          sessionOnly ? sessionID() : undefined
        );
        const selected = await context.ui.dialog.select({
          title: `Andon · L${current.level} · ${current.stats.open} open · ${current.stats.open_red} red`,
          placeholder: "Search alerts; Enter to inspect, Escape to close",
          options: [
            { title: `Filter: ${filter}`, value: "filter", category: "View" },
            {
              title: sessionOnly
                ? "Scope: this session"
                : "Scope: all sessions",
              value: "scope",
              category: "View"
            },
            { title: "Refresh", value: "refresh", category: "View" },
            ...rows.map((alert) => ({
              title: `${alert.color} · ${alert.summary}${alert.recurrences > 1 ? ` ×${alert.recurrences}` : ""}`,
              value: alert.id,
              description: `${alert.kind} · ${alert.status} · ${alert.sources.join(", ")}`,
              category: "Alerts"
            }))
          ]
        });
        if (!selected) return;
        if (selected === "refresh") continue;
        if (selected === "scope") {
          if (!sessionID())
            context.ui.toast.show({
              message: "Open a session to filter its alerts."
            });
          else sessionOnly = !sessionOnly;
          continue;
        }
        if (selected === "filter") {
          const chosen = await context.ui.dialog.select<Filter>({
            title: "Andon filter",
            current: filter,
            options: (
              ["open", "red", "yellow", "closed", "all"] as Filter[]
            ).map((value) => ({ title: value, value }))
          });
          if (chosen) filter = chosen;
          continue;
        }
        const alert = rows.find((row) => row.id === selected);
        if (!alert) continue;
        const action = await context.ui.dialog.select({
          title: alert.summary,
          options: [
            { title: "Details", value: "details" },
            { title: "Fix prompt", value: "prompt" },
            { title: "Copy fix prompt", value: "copy" },
            ...(alert.status === "open"
              ? [
                  {
                    title: "Resolve all matching open alerts",
                    value: "resolve"
                  },
                  {
                    title: "Dismiss all matching open alerts",
                    value: "dismiss"
                  }
                ]
              : [{ title: "Reopen matching closed alerts", value: "reopen" }])
          ]
        });
        if (!action) continue;
        if (action === "details") {
          await context.ui.dialog.alert({
            title: alert.id,
            message: [
              `${alert.color} / ${alert.kind} / ${alert.status}`,
              alert.details,
              `Sources: ${alert.sources.join(", ") || "(none)"}`,
              alert.resolution && `Workaround / decision: ${alert.resolution}`,
              alert.proposed_fix && `Proposed fix: ${alert.proposed_fix}`,
              `Origin: ${alert.harness ?? "unknown"} / ${alert.conversation_id ?? "unknown session"}`
            ]
              .filter(Boolean)
              .join("\n\n")
          });
        } else if (action === "prompt" || action === "copy") {
          const result = (await rpc.prompt(
            { id: alert.id },
            options()
          )) as TextResponse;
          if (
            action === "copy" &&
            context.renderer.copyToClipboardOSC52(result.text)
          ) {
            context.ui.toast.show({
              message: "Fix prompt sent to the terminal clipboard.",
              variant: "success"
            });
            continue;
          }
          await context.ui.dialog.alert({
            title: "Andon fix prompt",
            message: result.text
          });
        } else {
          const result = (await rpc.transition(
            { id: alert.id, verb: action },
            options()
          )) as TextResponse;
          context.ui.toast.show({ message: result.text, variant: "success" });
        }
      }
    } catch (error) {
      failed(error);
    } finally {
      boardOpen = false;
    }
  }

  context.keymap.layer(() => ({
    mode: "global",
    commands: [
      {
        id: "andon.board",
        title: "Andon board and trigger level",
        group: "Andon",
        palette: true,
        slash: { name: "andon", arguments: true },
        run: async (input) => {
          const text = input?.trim() ?? "";
          if (!text || text === "board") return board();
          try {
            const result = (await rpc.command(
              { text, sessionID: sessionID() },
              options()
            )) as TextResponse;
            await refresh();
            await context.ui.dialog.alert({
              title: "Andon",
              message: result.text
            });
          } catch (error) {
            failed(error);
          }
        }
      }
    ]
  }));
  const stop = rpc.events.on(
    "changed",
    (event) => {
      if (event.location.directory === options().location.directory)
        void refresh();
    },
    { signal: controller.signal }
  );
  // Also pick up CLI/Claude writes, which do not emit OpenCode RPC events.
  const timer = setInterval(() => void refresh(), 30_000);
  await refresh();
  return {
    refresh,
    cleanup: () => {
      controller.abort();
      stop();
      clearInterval(timer);
    }
  };
}

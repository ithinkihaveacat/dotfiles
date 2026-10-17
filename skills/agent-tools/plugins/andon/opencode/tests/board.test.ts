import assert from "node:assert/strict";
import { test } from "node:test";
import type { Context, KeymapLayer } from "@opencode/plugin/tui/context";
import { boardRows, setupBoard } from "../src/board.ts";
import type { Alert, Snapshot } from "../src/types.ts";

const alert: Alert = {
  id: "ANDON-20261017-120000-abcd",
  created_at: "2026-10-17T12:00:00Z",
  status: "open",
  color: "yellow",
  kind: "stale_instruction",
  level: 3,
  summary: "Removed flag",
  details: "--old was removed",
  sources: ["SKILL.md"],
  fingerprint: "same",
  recurrences: 2,
  conversation_id: "one"
};
const snapshot: Snapshot = {
  alerts: [alert],
  stats: { open: 1, open_red: 0, level: 3 },
  level: 3,
  sessionOverride: false
};

test("board filters before grouping and does not hide closed status differences", () => {
  const rows = [
    alert,
    { ...alert, id: "other", conversation_id: "two" },
    { ...alert, status: "resolved" as const },
    { ...alert, status: "dismissed" as const },
    { ...alert, fingerprint: "red", color: "red" as const }
  ];
  assert.equal(boardRows(rows, "open").length, 2);
  assert.equal(boardRows(rows, "closed").length, 2);
  assert.equal(boardRows(rows, "red").length, 1);
  assert.equal(boardRows(rows, "yellow", "two")[0].id, "other");
});

test("terminal board uses server RPC, scopes requests, and cleans up subscriptions", async () => {
  const calls: { method: string; input: unknown; options: unknown }[] = [];
  let layer: KeymapLayer | undefined;
  let stopped = false;
  const updates: (Snapshot | null)[] = [];
  const context = {
    client: {
      rpc: () => ({
        snapshot: async (input: unknown, options: unknown) => {
          calls.push({ method: "snapshot", input, options });
          return snapshot;
        },
        command: async (input: unknown, options: unknown) => {
          calls.push({ method: "command", input, options });
          return { text: "Andon level 3" };
        },
        events: {
          on: () => () => {
            stopped = true;
          }
        }
      })
    },
    location: { directory: "/plugin" },
    keymap: {
      layer: (factory: () => KeymapLayer) => {
        layer = factory();
      }
    },
    data: {
      session: { get: () => ({ location: { directory: "/moved/session" } }) }
    },
    ui: {
      router: { current: () => ({ type: "session", sessionID: "one" }) },
      toast: { show: () => {} },
      dialog: { select: async () => undefined, alert: async () => {} }
    }
  } as unknown as Context;
  const board = await setupBoard(context, (next) => updates.push(next));
  try {
    assert.equal(updates[0], snapshot);
    assert.deepEqual(calls[0].input, { sessionID: "one" });
    assert.equal(
      (calls[0].options as { location: { directory: string } }).location
        .directory,
      "/moved/session"
    );
    const command = layer!.commands![0];
    assert.equal(command.slash?.name, "andon");
    await command.run("level 3");
    assert.equal(
      calls.find((call) => call.method === "command")?.method,
      "command"
    );
    await command.run(); // Open and cancel the board.
  } finally {
    board.cleanup();
  }
  assert.equal(stopped, true);
  assert.equal(
    (calls[0].options as { signal: AbortSignal }).signal.aborted,
    true
  );
});

for (const action of ["resolve", "dismiss", "reopen", "copy", "prompt"]) {
  test(`board ${action} uses the control plane, not model tools`, async () => {
    let run: (() => void | false | Promise<void>) | undefined;
    const choices =
      action === "reopen"
        ? ["filter", "closed", alert.id, action, undefined]
        : [alert.id, action, undefined];
    const mutations: unknown[] = [];
    const shown: string[] = [];
    const copied: string[] = [];
    const context = {
      client: {
        rpc: () => ({
          snapshot: async () => ({
            ...snapshot,
            alerts: [
              { ...alert, status: action === "reopen" ? "resolved" : "open" }
            ]
          }),
          transition: async (input: unknown) => {
            mutations.push(input);
            return { text: "Updated" };
          },
          prompt: async () => ({ text: "Fix this source defect." }),
          events: { on: () => () => {} }
        })
      },
      renderer: {
        copyToClipboardOSC52: (text: string) => {
          copied.push(text);
          return true;
        }
      },
      location: { directory: "/server" },
      keymap: {
        layer: (factory: () => KeymapLayer) => {
          run = factory().commands![0].run;
        }
      },
      data: { session: { get: () => undefined } },
      ui: {
        router: { current: () => ({ type: "session", sessionID: "one" }) },
        toast: { show: () => {} },
        dialog: {
          select: async () => choices.shift(),
          alert: async ({ message }: { message: string }) => {
            shown.push(message);
          }
        }
      }
    } as unknown as Context;
    const board = await setupBoard(context, () => {});
    try {
      await run!();
    } finally {
      board.cleanup();
    }
    if (action === "copy")
      assert.deepEqual(copied, ["Fix this source defect."]);
    else if (action === "prompt")
      assert.deepEqual(shown, ["Fix this source defect."]);
    else assert.deepEqual(mutations, [{ id: alert.id, verb: action }]);
  });
}

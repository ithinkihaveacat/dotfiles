// Tests: ../tests/plugin.test.ts
import { Plugin } from "@opencode/plugin";
import type { ToolContext } from "@opencode/plugin/promise/tool";
import { createCli, cliJson, type Cli } from "./cli.ts";
import { Andon } from "./rpc.ts";
import {
  buildRule,
  DEFAULT_LEVEL,
  DESCRIPTION,
  INPUT_SCHEMA,
  isLevel,
  MODEL_FIELDS,
  TOOL
} from "./rule.ts";
import { createSensor, shellFailed } from "./sensor.ts";
import type { Alert, Stats } from "./types.ts";

const USAGE = "Usage: /andon [board|list|stats|level [1-5|default|reset]]";
const guidance = (color: unknown) =>
  color === "red"
    ? "Stop on the blocked path and explain the blocker and decision needed to the user."
    : "Continue with your safe workaround; do not interrupt the user.";

export async function setup(
  ctx: Plugin.Context,
  cli: Cli = createCli({
    script: typeof ctx.options.cli === "string" ? ctx.options.cli : undefined
  })
) {
  let defaultLevel = DEFAULT_LEVEL;
  let checkedAt = 0;
  let notify = async () => {};
  const sensors = new Map<string, ReturnType<typeof createSensor>>();
  const sessionLevels = new Map<string, number>();
  const offered = new Set<string>();
  const models = new Map<string, string>();
  const pendingReminders = new Map<string, string>();

  async function refreshDefault(force = false) {
    if (!force && Date.now() - checkedAt < 60_000) return;
    checkedAt = Date.now();
    try {
      const stats = await cliJson<Stats>(cli, ["stats", "--json"]);
      if (isLevel(stats.level)) defaultLevel = stats.level;
    } catch {
      /* A broken store must not prevent loading the reporting tool. */
    }
  }

  async function sessionLevel(sessionID?: string): Promise<number> {
    if (sessionID && sessionLevels.has(sessionID)) {
      return sessionLevels.get(sessionID)!;
    }
    await refreshDefault();
    if (sessionID) {
      if (sessionLevels.size >= 128) {
        sessionLevels.delete(sessionLevels.keys().next().value!);
      }
      sessionLevels.set(sessionID, defaultLevel);
    }
    return defaultLevel;
  }

  async function command(text: string, sessionID?: string): Promise<string> {
    const words = text.trim().split(/\s+/).filter(Boolean);
    const verb = words[0] ?? "board";
    if (["board", "list", "stats"].includes(verb) && words.length <= 1) {
      return (
        (await cli([verb === "board" ? "list" : verb])).trim() ||
        "No matching Andon alerts."
      );
    }
    if (verb !== "level" || words.length > 2) return USAGE;
    if (words.length === 1) {
      await refreshDefault(true);
      const locked = sessionID ? sessionLevels.get(sessionID) : undefined;
      return locked !== undefined && locked !== defaultLevel
        ? `Andon level ${locked} for this session (default ${defaultLevel}).`
        : `Andon level ${defaultLevel}.`;
    }
    const value =
      words[1] === "default" || words[1] === "reset"
        ? "default"
        : Number(words[1]);
    if (value !== "default" && !isLevel(value)) return USAGE;
    await cli(
      value === "default" ? ["level", "--reset"] : ["level", String(value)]
    );
    await refreshDefault(true); // Respect ANDON_LEVEL even after a saved change.
    await notify().catch(() => {});
    return `Andon level ${defaultLevel} (applies to new sessions).`;
  }

  async function pull(input: unknown, context: ToolContext) {
    // Even with automatic approval, explicit user/agent denies must be evaluated.
    await ctx.permission.assert({
      sessionID: context.sessionID,
      agent: context.agent,
      source: { type: "tool", messageID: context.messageID, id: context.id },
      action: TOOL,
      resources: ["*"],
      save: ["*"]
    });
    const fields: Record<string, unknown> = {};
    const args = input as Record<string, unknown>;
    for (const key of MODEL_FIELDS)
      if (args[key] !== undefined) fields[key] = args[key];
    let saved: string;
    try {
      const session = await ctx.session.get({ sessionID: context.sessionID });
      const level = await sessionLevel(context.sessionID);
      const model =
        models.get(context.sessionID) ??
        (session.model
          ? `${session.model.providerID}/${session.model.id}`
          : undefined);
      saved = await cli(
        ["pull", "--json", "-"],
        {
          ...fields,
          level,
          harness: "opencode",
          conversation_id: context.sessionID,
          agent_id: session.parentID ? context.sessionID : undefined,
          tool_use_id: context.id,
          workspace_paths: [session.location.directory],
          model_name: model
        },
        context.signal
      );
    } catch (error) {
      context.signal.throwIfAborted();
      return {
        content: JSON.stringify({
          ok: false,
          error: String(error),
          guidance: `The alert was not confirmed saved. Do not retry automatically; mention the defect to the user at the end of your turn. ${guidance(fields.color)}`
        })
      };
    }
    // The write succeeded: no UI/event failure may turn it into a failed pull.
    await notify().catch(() => {});
    try {
      const response = JSON.parse(saved);
      return { content: JSON.stringify(response) };
    } catch {
      return {
        content: JSON.stringify({
          ok: true,
          guidance: `The alert was saved but its receipt was unreadable. Do not pull again. ${guidance(fields.color)}`
        })
      };
    }
  }

  await ctx.permission.hook("evaluate", (event) => {
    if (event.action === TOOL && event.effect === "ask") event.effect = "allow";
  });
  await ctx.tool.transform((editor) => {
    editor.add({
      name: TOOL,
      description: DESCRIPTION,
      input: INPUT_SCHEMA,
      // Directly offered, even when other tools use Code Mode discovery.
      options: { codemode: false, permission: TOOL },
      execute: pull
    });
  });
  await ctx.session.hook("context", async (event) => {
    if (!(TOOL in event.tools)) {
      offered.delete(event.sessionID);
      sensors.delete(event.sessionID);
      models.delete(event.sessionID);
      pendingReminders.delete(event.sessionID);
      return;
    }
    // Bound transient sensor/model state in a long-running shared service.
    if (offered.size >= 128 && !offered.has(event.sessionID)) {
      const oldest = offered.values().next().value!;
      offered.delete(oldest);
      sensors.delete(oldest);
      sessionLevels.delete(oldest);
      models.delete(oldest);
      pendingReminders.delete(oldest);
    }
    offered.add(event.sessionID);
    models.set(event.sessionID, `${event.model.providerID}/${event.model.id}`);
    const level = await sessionLevel(event.sessionID);
    event.system.push({
      type: "text",
      text: buildRule(level)
    });
  });
  await ctx.tool.hook("execute.after", async (event) => {
    if (!offered.has(event.sessionID)) return;
    try {
      let sensor = sensors.get(event.sessionID);
      if (!sensor) {
        sensor = createSensor();
        sensors.set(event.sessionID, sensor);
      }
      const reminder = sensor.observe({
        tool: event.tool,
        input: event.input,
        failed:
          event.status === "error" ||
          (event.status === "completed" && shellFailed(event.result)),
        level: await sessionLevel(event.sessionID)
      });
      if (!reminder) return;
      if (event.status === "error") {
        // Do not replace Tool.Error or change its permission/cancellation semantics.
        // The next context request will carry the reminder instead.
        pendingReminders.set(event.sessionID, reminder);
      } else {
        const content = event.result.content;
        event.result = {
          ...event.result,
          content:
            typeof content === "string"
              ? `${content}\n\n${reminder}`
              : [...(content ?? []), { type: "text", text: reminder }]
        };
      }
    } catch {
      /* The passive sensor must never break another tool. */
    }
  });
  await ctx.session.hook("context", (event) => {
    const reminder = pendingReminders.get(event.sessionID);
    pendingReminders.delete(event.sessionID);
    if (reminder && TOOL in event.tools)
      event.system.push({ type: "text", text: reminder });
  });
  await ctx.command.transform((editor) => {
    editor.add({
      name: "andon",
      description: "Andon alerts and trigger level",
      execute: async ({ sessionID, prompt }) => {
        const text = await command(prompt.text ?? "", sessionID);
        await ctx.session.synthetic({ sessionID, text });
      }
    });
  });
  const rpc = await ctx.rpc.register(Andon, {
    snapshot: async (input, request) => {
      const { sessionID } = (input ?? {}) as { sessionID?: string };
      const stats = await cliJson<Stats>(
        cli,
        ["stats", "--json"],
        request.signal
      );
      defaultLevel = isLevel(stats.level) ? stats.level : defaultLevel;
      checkedAt = Date.now();
      return {
        alerts: await cliJson<Alert[]>(
          cli,
          ["list", "--json", "--status", "all"],
          request.signal
        ),
        stats,
        level:
          (sessionID ? sessionLevels.get(sessionID) : undefined) ?? defaultLevel
      };
    },
    command: async (input) => {
      const { text, sessionID } = input as { text: string; sessionID?: string };
      return { text: await command(text, sessionID) };
    },
    transition: async (input, request) => {
      const { verb, id } = input as { verb: string; id: string };
      // Also guard dispatch explicitly: never forward an arbitrary CLI verb.
      if (!["resolve", "dismiss", "reopen"].includes(verb))
        throw new Error("Invalid transition");
      await cli(
        [
          verb,
          id,
          "--all-matching",
          "--note",
          `${verb} from the OpenCode Andon board`
        ],
        undefined,
        request.signal
      );
      await notify().catch(() => {});
      return { text: `${verb}: ${id}` };
    },
    prompt: async (input, request) => ({
      text: await cli(
        ["prompt", (input as { id: string }).id],
        undefined,
        request.signal
      )
    })
  });
  notify = () => rpc.events.emit("changed", {});
  await refreshDefault();
  return () => {
    sensors.clear();
    sessionLevels.clear();
    offered.clear();
    models.clear();
    pendingReminders.clear();
  };
}

export default Plugin.define({ id: "andon", setup });

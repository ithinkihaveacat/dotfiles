import type { Plugin } from "@opencode/plugin";
import type { Info, ToolContext } from "@opencode/plugin/promise/tool";
import type { Cli } from "../src/cli.ts";
import { setup } from "../src/index.ts";

export const receipt = {
  ok: true,
  id: "ANDON-20261017-120000-abcd",
  recurrences: 1,
  guidance: "Continue"
};
export const input = {
  color: "yellow",
  kind: "stale_instruction",
  summary: "Removed flag",
  details: "--old is not supported"
};
export type RpcHandler = (
  input: unknown,
  request: { signal: AbortSignal }
) => Promise<unknown>;

export async function harness(
  options: {
    cli?: Cli;
    deny?: boolean;
    brokenEvents?: boolean;
  } = {}
) {
  type Hook = (event: never) => Promise<void> | void;
  const hooks = new Map<string, Hook[]>();
  const tools = new Map<string, Info>();
  const calls: { args: string[]; input?: unknown }[] = [];
  const permissions: unknown[] = [];
  let handlers: Record<string, RpcHandler> = {};
  let defaultLevel = 3;
  let notifications = 0;
  let getSessionFails = false;
  const synthetic: unknown[] = [];
  const commands = new Map<
    string,
    { execute: (input: never) => Promise<void> }
  >();
  function hook(domain: string) {
    return async (name: string, callback: Hook) => {
      const key = `${domain}:${name}`;
      hooks.set(key, [...(hooks.get(key) ?? []), callback]);
      return { dispose: async () => {} };
    };
  }
  const cli: Cli =
    options.cli ??
    (async (args, input) => {
      calls.push({ args, input });
      if (args[0] === "stats")
        return JSON.stringify({ open: 1, open_red: 0, level: defaultLevel });
      if (args[0] === "list")
        return args.includes("--json") ? "[]" : "abcd yellow Removed flag";
      if (args[0] === "pull") return JSON.stringify(receipt);
      if (args[0] === "level") {
        defaultLevel = args[1] === "--reset" ? 3 : Number(args[1]);
        return `${defaultLevel}\n`;
      }
      if (args[0] === "prompt")
        return "Fix the source, then andon resolve abcd";
      return "";
    });
  const ctx = {
    options: {},
    location: { directory: "/plugin/location" },
    permission: {
      hook: hook("permission"),
      assert: async (permission: unknown) => {
        permissions.push(permission);
        if (options.deny) throw new Error("User denied Andon");
      }
    },
    tool: {
      hook: hook("tool"),
      transform: async (
        callback: (editor: { add: (tool: Info) => void }) => void
      ) => {
        callback({
          add: (tool) => {
            tools.set(tool.name, tool);
          }
        });
      }
    },
    session: {
      hook: hook("session"),
      get: async ({ sessionID }: { sessionID: string }) => {
        if (getSessionFails) throw new Error("Session unavailable");
        return {
          id: sessionID,
          parentID: sessionID.startsWith("child") ? "parent" : undefined,
          location: { directory: `/sessions/${sessionID}` },
          model: { providerID: "test", id: "fallback" }
        };
      },
      synthetic: async (input: unknown) => {
        synthetic.push(input);
      }
    },
    command: {
      transform: async (
        callback: (editor: {
          add: (command: {
            name: string;
            execute: (input: never) => Promise<void>;
          }) => void;
        }) => void
      ) => {
        callback({
          add: (command) => {
            commands.set(command.name, command);
          }
        });
      }
    },
    rpc: {
      register: async (
        _definition: unknown,
        registered: Record<string, RpcHandler>
      ) => {
        handlers = registered;
        return {
          events: {
            emit: async () => {
              notifications++;
              if (options.brokenEvents) throw new Error("UI disconnected");
            }
          }
        };
      }
    }
  } as unknown as Plugin.Context;
  const cleanup = await setup(ctx, cli);

  async function emit(key: string, event: unknown) {
    for (const callback of hooks.get(key) ?? []) await callback(event as never);
    return event;
  }
  async function context(sessionID = "one", toolOffered = true) {
    const event = {
      sessionID,
      agent: "build",
      model: { providerID: "test", id: "reasoner" },
      system: [] as { type: string; text: string }[],
      tools: toolOffered ? { andon_pull: {} } : {}
    };
    await emit("session:context", event);
    return event;
  }
  const toolContext = (
    sessionID = "one",
    signal = new AbortController().signal
  ) =>
    ({
      sessionID,
      agent: "build",
      messageID: "msg-1",
      id: "call-1",
      signal,
      progress: async () => {}
    }) as unknown as ToolContext;
  async function pull(
    fields: unknown = input,
    sessionID = "one",
    signal?: AbortSignal
  ) {
    const result = await tools
      .get("andon_pull")!
      .execute(fields, toolContext(sessionID, signal));
    return JSON.parse(result.content as string);
  }
  async function rpc(name: string, input: unknown) {
    return handlers[name](input, { signal: new AbortController().signal });
  }
  return {
    tools,
    calls,
    permissions,
    emit,
    context,
    pull,
    rpc,
    cleanup,
    synthetic,
    commands,
    notifications: () => notifications,
    breakSession: () => {
      getSessionFails = true;
    }
  };
}

import { Rpc } from "@opencode/plugin/rpc";

const optionalSession = {
  type: "object",
  additionalProperties: false,
  properties: { sessionID: { type: "string" } }
} as const;
const response = { type: "object", additionalProperties: true } as const;

// Control-plane operations for UI clients, not extra model-facing tools.
export const Andon = Rpc.define({
  id: "andon",
  methods: {
    snapshot: { input: optionalSession, output: response },
    command: {
      input: {
        ...optionalSession,
        properties: { ...optionalSession.properties, text: { type: "string" } },
        required: ["text"]
      },
      output: response
    },
    transition: {
      input: {
        type: "object",
        additionalProperties: false,
        properties: {
          id: {
            type: "string",
            pattern: "^ANDON-[0-9]{8}-[0-9]{6}-[a-f0-9]{4}$"
          },
          verb: { type: "string", enum: ["resolve", "dismiss", "reopen"] }
        },
        required: ["id", "verb"]
      },
      output: response
    },
    prompt: {
      input: {
        type: "object",
        additionalProperties: false,
        properties: {
          id: {
            type: "string",
            pattern: "^ANDON-[0-9]{8}-[0-9]{6}-[a-f0-9]{4}$"
          }
        },
        required: ["id"]
      },
      output: response
    }
  },
  events: {
    changed: { schema: { type: "object", additionalProperties: false } }
  }
});

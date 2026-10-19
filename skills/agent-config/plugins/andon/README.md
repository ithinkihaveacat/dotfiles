# Andon

Andon gives a coding agent a cheap, always-available way to report "my
instructions or tools are wrong here" while it keeps working, and collects those
reports in one store outside every session so the source can be fixed.

The vocabulary follows the Toyota Production System: the agent _pulls the cord_,
the pull records an _alert_, and _the Andon_ (the board) shows alerts from every
session.

- **Yellow**: a safe workaround exists. The agent pulls in the same parallel
  tool-call batch as the workaround and carries on without telling the user.
- **Red**: the agent is blocked. It pulls, stops on that path, and asks the user
  for a decision. Color is severity metadata: nothing in the harness enforces
  the stop.
- **Levels 1–5** set how readily the agent pulls yellow, from red-only to "do
  not self-filter". The default is 3.

## Layout

```text
plugins/
  .claude-plugin/marketplace.json  the agent-config marketplace (Claude Code)
  andon/
    README.md                      this file
    claude/                        the Claude Code plugin
    opencode/                      the OpenCode V2 server and terminal plugin
../scripts/andon                   the store and triage CLI, shared by every harness
```

The store format and the `andon` command are the shared, harness-neutral half.
CLI commands and MCP tools call the same operations, so validation, locking,
fingerprints and record shapes live in one place. The existing adapters invoke
CLI commands; another harness can use either that interface or MCP.

`andon mcp --stdio` exposes the shared operations through the MCP Python SDK,
using Taskgo's SDK/server and separate-transport pattern. It needs no HTTP
listener or hosted service. See [Andon MCP](../../references/andon-mcp.md) for
tools, client configuration and attribution boundaries. This is the shared API
only; it does not install a Codex adapter. The Claude Code plugin registers its
tool in-process and does not need MCP.

## The Claude Code plugin

`claude/` is a function-hooks plugin. It is TypeScript, not Python, because
Claude Code loads function hooks only from TypeScript or JavaScript modules. It
runs inside Claude Code (no Node, no npm packages) and is thin glue: every read
and write goes through the Python CLI. Each piece of the design maps onto one
hook:

| Need                     | Hook                                                                                                                                                                                                                                            |
| :----------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Always-on rule           | `prompt.compose` adds an `andon:rule` system-prompt section, rendered for the level in force. It is added only to requests that offer the tool, so a subagent without the tool is never told to call it.                                        |
| Eager, pre-approved tool | `$.tool.register` with `isDeferred: false` registers `mcp__andon__pull`, and a `tool.check` hook turns an "ask" into "allow", so it never prompts. A deny from the user's rules or mode still stands.                                           |
| Session attribution      | The `tool.call` handler stamps the session ID, `tool_use_id`, subagent ID, turn, model, workspace and transcript path itself, then writes one complete record. There is no second process and no `args_hash` pairing window.                    |
| Level override           | A message that starts with "andon level 5" sets the level (one that only mentions a level doesn't), and so does `/andon level N`. The level is held in host state, so it survives compaction and is re-rendered into the rule on every request. |
| Passive sensor           | A `tool.call` observer adds a one-line reminder to a tool result when a command fails after the agent read a skill's `SKILL.md`, when `--help` follows a failure, or when the same command fails twice. It never pulls by itself.               |
| Board                    | `/andon` opens a pane on the terminal and desktop surfaces with filters, recurrence badges, and Copy fix prompt / Resolve / Dismiss / Reopen buttons. The status line shows `andon: L3 · 2 open · 1 red`.                                       |
| One unit                 | Disabling the plugin removes the rule, tool, sensor, board and status line together.                                                                                                                                                            |

The plugin finds the CLI at `../../../scripts/andon` (relative to `claude/`),
falling back to `andon` on `PATH`. If uv is missing from the host's `PATH`, it
runs the script with `python3`, since the CLI uses only the standard library.

### Develop

```bash
claude plugin validate skills/agent-config/plugins/andon/claude
claude plugin test skills/agent-config/plugins/andon/claude
prove skills/agent-config/tests/test-andon
```

The repo has no TypeScript tooling of its own. The engine lays the API types in
`.claude-plugin/types/` (ignored by Git) when it loads the plugin from a folder
it watches, and the committed `tsconfig.json` extends them for an editor or
`tsc`. On a fresh clone, `tsc -p` fails until a session has loaded the plugin
from the folder once (for example with `--plugin-dir`).

`claude --plugin-dir skills/agent-config/plugins/andon/claude` loads the working
copy for one session. An install from the folder marketplace (see the
agent-config `SKILL.md`) also reads this folder directly, so `/reload-plugins`
picks up edits without a reinstall.

### Limits

- **Organization-managed installs:** the `prompt.compose` and `classic.*` hooks
  don't run for a plugin a person installs where an organization manages Claude
  Code. There, the rule has to come from a managed plugin or from `CLAUDE.md`.
- **Local install only:** the plugin finds the CLI by its place in this
  repository. An install from a GitHub-sourced marketplace copies only
  `claude/`, and then needs `andon` on `PATH`; the folder install in the
  agent-config `SKILL.md` is the supported route.
- **Plugin API version:** the function-hooks API is early access, and the plugin
  was written against Claude Code 2.1.299.

## The OpenCode plugin

`opencode/` provides an OpenCode V2 adapter over the same CLI and store, with a
directly offered pull tool, an always-on rule, session levels, passive
reminders, and a searchable terminal board. See
[OpenCode installation and usage](opencode/README.md). The Claude adapter and
shared store format are unchanged; differences and the deferred MCP boundary are
recorded in [its changelog](opencode/CHANGELOG.md).

## Porting notes

The design was ported, not the mechanisms. Another harness needs the same five
things: an always-on rule (not a skill), an eagerly loaded tool that doesn't
prompt, session attribution, the shared store, and packaging as one unit. Where
the harness's tools receive session context, write the full record in the tool
handler, as this plugin does. Otherwise, MCP reports omit unavailable session
fields. A future adapter must define reliable host attribution separately; MCP
client identity is not a conversation ID.

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
  .claude-plugin/marketplace.json  the agent-tools marketplace (Claude Code)
  andon/
    README.md                      this file
    claude/                        the Claude Code plugin
../scripts/andon                   the store and triage CLI, shared by every harness
```

The store format and the `andon` CLI are the shared, harness-neutral half. Every
integration writes through the CLI, so the lock, the fingerprint and the record
shape live in one place. An integration for another harness goes beside
`claude/` (for example `codex/` or `opencode/`) and calls the same CLI.

An MCP server is the likely next shared piece, for harnesses whose only tool
extension point is MCP. It would be a thin wrapper over `andon pull --json -`,
paired with that harness's post-tool hook for session attribution. The Claude
Code plugin doesn't need one: it registers the tool in-process.

## The Claude Code plugin

`claude/` is a function-hooks plugin. It is TypeScript, not Python, because
Claude Code loads function hooks only from TypeScript or JavaScript modules. It
runs inside Claude Code (no Node, no npm packages) and is thin glue: every read
and write goes through the Python CLI. Each piece of the design maps onto one
hook:

| Need                     | Hook                                                                                                                                                                                                                              |
| :----------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Always-on rule           | `prompt.compose` adds an `andon:rule` system-prompt section, rendered for the level in force. It is added only to requests that offer the tool, so a subagent without the tool is never told to call it.                          |
| Eager, pre-approved tool | `$.tool.register` with `isDeferred: false` registers `mcp__andon__pull`, and a `tool.check` hook allows it without a prompt.                                                                                                      |
| Session attribution      | The `tool.call` handler stamps the session ID, `tool_use_id`, subagent ID, turn, model, workspace and transcript path itself, then writes one complete record. There is no second process and no `args_hash` pairing window.      |
| Level override           | `prompt.submit` recognizes "andon level 5" in the user's own words, and `/andon level N` does the same. The level is held in host state, so it survives compaction and is re-rendered into the rule on every request.             |
| Passive sensor           | A `tool.call` observer adds a one-line reminder to a tool result when a command fails after the agent read a skill's `SKILL.md`, when `--help` follows a failure, or when the same command fails twice. It never pulls by itself. |
| Board                    | `/andon` opens a pane on the terminal and desktop surfaces with filters, recurrence badges, and Copy fix prompt / Resolve / Dismiss / Reopen buttons. The status line shows `andon: L3 · 2 open · 1 red`.                         |
| One unit                 | Disabling the plugin removes the rule, tool, sensor, board and status line together.                                                                                                                                              |

The plugin finds the CLI at `../../../scripts/andon` (relative to `claude/`),
falling back to `andon` on `PATH`. If uv is missing from the host's `PATH`, it
runs the script with `python3`, since the CLI uses only the standard library.

### Develop

```bash
claude plugin validate skills/agent-tools/plugins/andon/claude
claude plugin test skills/agent-tools/plugins/andon/claude
prove skills/agent-tools/tests/test-andon
```

The repo has no TypeScript tooling of its own. The engine lays the API types in
`.claude-plugin/types/` (ignored by Git) when it loads the plugin from a folder
it watches, and the committed `tsconfig.json` extends them for an editor or
`tsc`.

`claude --plugin-dir skills/agent-tools/plugins/andon/claude` loads the working
copy for one session. An install from the folder marketplace (see the
agent-tools `SKILL.md`) also reads this folder directly, so `/reload-plugins`
picks up edits without a reinstall.

### Limits

- **Organization-managed installs:** the `prompt.compose` and `classic.*` hooks
  don't run for a plugin a person installs where an organization manages Claude
  Code. There, the rule has to come from a managed plugin or from `CLAUDE.md`.
- **Plugin API version:** the function-hooks API is early access, and the plugin
  was written against Claude Code 2.1.299.

## Porting notes

The design was ported, not the mechanisms. Another harness needs the same five
things: an always-on rule (not a skill), an eagerly loaded tool that doesn't
prompt, session attribution, the shared store, and packaging as one unit. Where
the harness's tools receive session context, write the full record in the tool
handler, as this plugin does. Otherwise, write it with a null session from an
MCP server, and stamp it from a post-tool hook matched only on the pull tool.

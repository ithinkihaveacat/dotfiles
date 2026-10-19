# Andon for OpenCode

An OpenCode V2 plugin that lets agents report defects in their own instructions,
skills, rules and tools without interrupting work that has a safe workaround. It
uses the same `andon` CLI and alert store as the Claude Code plugin.

## Install

For a checkout at `~/.dotfiles`, install without editing JSON by linking the
plugin into OpenCode's auto-discovered global plugins directory:

```sh
mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/opencode/plugins"
ln -sn "$HOME/.dotfiles/skills/agent-config/plugins/andon/opencode" \
  "${XDG_CONFIG_HOME:-$HOME/.config}/opencode/plugins/andon"
```

If the destination already exists, inspect it before running `ln`; do not
force-replace an existing installation. The link leaves the source in this
checkout, so the adapter can still find its shared CLI. No marketplace, package
download or JSON edit is required.

OpenCode V2 has `opencode plugin add` for npm and Git package specifications,
but it does not accept local plugin directory paths. Auto-discovery is the local
equivalent. See the [OpenCode plugin guide](https://opencode.ai/v2/docs/plugins)
for package installation and discovery rules.

Alternatively, add this directory to `plugins` in your global
`~/.config/opencode/opencode.jsonc`, preserving existing entries. Replace the
example path with your checkout's absolute path. Use one installation route, not
both:

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "plugins": ["/path/to/dotfiles/skills/agent-config/plugins/andon/opencode"],
}
```

Restart OpenCode's service if the plugin is not picked up automatically:

```sh
opencode service restart
```

The package includes both the server plugin and a terminal UI entrypoint.
OpenCode supplies its plugin and UI runtime; no build or separate MCP process is
needed. The server needs the existing `andon` CLI and either `uv` with Python
3.11+, or `python3` 3.11+ as a fallback. Keeping the plugin in this skill tree
is the supported installation: it finds `../../../scripts/andon` relative to the
plugin directory. A copy elsewhere uses `andon` on the server's `PATH`, or an
explicit CLI path:

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "plugins": [
    {
      "package": "/path/to/andon/opencode",
      "options": { "cli": "/path/to/andon" },
    },
  ],
}
```

On a remote connection, install the server component and CLI on the server. If
the terminal does not automatically load the UI component, add the local plugin
directory to `plugins` in `~/.config/opencode/cli.json` as well. The UI always
reads and changes the server's store through RPC, not a local copy.

## Use

```text
/andon                     open the searchable board
/andon list                list open alerts from every harness
/andon stats               show counts and recurring defects
/andon level               show the active trigger level
/andon level 5             change this session's level
/andon level default       remove this session's override
/andon level 4 --save       change the shared default
/andon level default --save reset the shared default to 3
```

A message starting with `andon level 5` also changes that session's level;
merely asking about a level does not. Session overrides are persisted in
OpenCode plugin storage, independently for each session. They survive
compaction, plugin reloads and server restarts. Child sessions have their own
overrides; they do not implicitly inherit a parent's level.

The board uses native terminal selection dialogs. Choose a filter, switch
between all sessions and the current session, or inspect an alert. Alert actions
show its details or fix prompt, copy the prompt using the terminal's OSC 52
clipboard support, resolve or dismiss matching open alerts, or reopen matching
closed alerts. Escape closes a dialog. The footer shows the active level and
global open/red counts. On non-terminal surfaces, the server command provides a
text list instead of the board.

Levels have the same meanings as the Claude plugin: 1 is red-only, 2 is
conservative, 3 standard, 4 proactive audit, and 5 maximum coverage. A red alert
instructs the agent to stop on the blocked path and ask you; it does not
forcibly interrupt execution.

## Behavior and boundaries

- `andon_pull` is directly offered, outside Code Mode discovery. It is the only
  model-facing tool. An always-on rule is added to each primary request that
  offers it, including tool continuations after compaction. Auxiliary title,
  compaction and transient generation requests are not given the rule.
- Pulls are automatically approved when the permission result is `ask`. Explicit
  user, agent and policy denials still apply. No other permission is
  automatically approved.
- The executor stamps the harness, session, tool-call ID, workspace and model.
  Child sessions also record their session ID as `agent_id`. It never asks the
  model to supply these fields. There is no invented transcript file or turn
  number: OpenCode does not provide equivalents in this execution context.
- Passive reminders recognize skill loads, `SKILL.md` reads, repeated shell
  failures, and help probes after failures. They never create an alert or stop a
  tool. History is session-local, bounded, and reset on plugin reload. The
  sensor only sees calls that OpenCode exposes through its tool hooks; it does
  not inspect arbitrary commands inside a script.
- Store writes and triage go through the unchanged CLI. The default store is
  `${XDG_STATE_HOME:-~/.local/state}/andon`; `ANDON_STATE_DIR` overrides it.
  `ANDON_LEVEL` overrides the saved default, but not a session override. These
  variables belong to the **server's** environment.
- The footer refreshes every 30 seconds and on OpenCode changes. An open board
  refreshes between selections, or with its Refresh item. Shared default changes
  made outside OpenCode are checked on primary requests at most once per minute,
  or when the UI refreshes.
- A failed or interrupted write is not automatically retried: its outcome may be
  uncertain. An unreadable receipt after a successful CLI exit is reported as
  saved, to avoid duplicate pulls.
- Disabling the plugin removes its rule, tool, sensor, commands, RPC and UI
  registrations. It does not delete alerts or saved session levels.

## Develop

Tested against OpenCode **2.0.32**. The development environment needs Node.js
26.4+ for the UI peers and native TypeScript tests. OpenCode itself supplies the
runtime when loading the plugin.

From this directory:

```sh
npm ci --ignore-scripts
npm run typecheck
npm test
npm run format:check
```

From the repository root, with that Node version active:

```sh
prove skills/agent-config/tests/test-andon-opencode skills/agent-config/tests/test-andon
```

The default tests use temporary stores and mocked host APIs, including actual
CLI round trips. To also test the installed OpenCode binary:

```sh
OPENCODE_TEST_BINARY="$(command -v opencode)" npm test
```

The opt-in test starts a private loopback server with isolated home/config/data
directories and a local fake model. It exercises explicit configuration and
symlink auto-discovery, RPC, rule injection, direct tool visibility, alert
attribution, levels and explicit permission denial. No real model credentials or
API calls are used. Terminal dialogs are covered by controller tests and
typechecking, not a visual UI test.

The development dependency override selects Solid 1.9.17 to avoid vulnerable
serializer versions in older SDK dependencies. OpenCode still supplies its own
Solid runtime when loading the plugin; this does not patch OpenCode itself.

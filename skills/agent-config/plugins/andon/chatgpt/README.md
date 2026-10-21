# Andon for ChatGPT desktop

This local plugin exposes the shared Andon MCP server and a live alert board in
ChatGPT desktop. In local Codex, trusted lifecycle hooks also keep automatic
cord-pulling active. Open the board beside a conversation or from the global
sidebar. Alerts recorded by the CLI, Claude Code and OpenCode appear in the same
board.

The panel calls MCP tools directly. It refreshes every three seconds while
visible, supports severity and status filters, shows recurrence counts, and
offers alert details, fix prompts and Resolve / Dismiss / Reopen actions. It
does not need a model turn to refresh.

The board stacks its list and inspector in narrow panels and uses two columns
when space permits. Secondary alert metadata is collapsed beneath the main
details. An inspected alert stays available after filtering or triage removes it
from the results; a notice explains that it is outside the current results.
Empty results use the full panel width. Light and dark themes follow the host.

## Install

Use a local ChatGPT Work or Codex chat with local plugin support. Install this
repository's `andon` command first; `bin/andon` points to its canonical source
at `skills/agent-config/scripts/andon`. The MCP server needs `uv`, Python 3.11
or newer, and the Python packages declared in that script's metadata. `uv`
resolves those packages when it starts the server, so the first launch needs
network access unless they are already cached.

From this repository's root, check the commands and register the included
marketplace:

```bash
command -v andon
command -v uv
andon mcp --help
codex plugin marketplace add "$PWD/skills/agent-config/plugins"
codex plugin marketplace list
```

Choose either installation route:

- **Codex CLI:** with a version that supports plugin installation, run:

  ```bash
  codex plugin add andon@agent-config-desktop
  codex plugin list --marketplace agent-config-desktop --json
  ```

- **Desktop app:** restart the app, open the Plugins Directory, select **Agent
  Config Desktop**, and install and enable **Andon**.

Refresh or reinstall an older installation to pick up the current cached
package. After installation, restart the desktop app and complete the hook
review below. Start a new local chat, then ask "Open the Andon board." This
invokes the `board` MCP tool. The server advertises both a conversation panel
and a global sidebar entry; their availability depends on the host's MCP UI
extension support.

### Enable automatic reporting in Codex

Install and enable the plugin as above, then review and allow its four command
hooks in the desktop app's **Review hooks** dialog. Expand a hook to inspect its
source, event, command and timeout, then allow the selected hooks or all four.
For later changes, open **Settings → Coding → Hooks → Andon**. If the pending
review button beside the composer does not appear after an update, fully quit
and restart the desktop app; it reloads the pending-hook indicator. Codex CLI's
`/hooks` browser is an alternative; CLI use is not required for desktop review.
Installation alone does not trust hooks. Changed hook definitions require review
again. Keep the `hooks` feature enabled; managed policy can restrict plugin
hooks. Review the
[Codex hook trust requirements](https://learn.chatgpt.com/docs/hooks#review-and-trust-hooks)
if the hooks are listed but skipped.

The four hooks have descriptive `statusMessage` labels: **Andon: load reporting
instructions**, **Andon: refresh reporting instructions**, **Andon: check tool
failures and attribute reports**, and **Andon: load reporting instructions for
subagent**. These identify each hook's purpose in clients that display this
metadata, and also supply its running status. The hook file's description
explains the integration as a whole.

No particular working directory is required: the plugin is installed at user
scope. Exit and restart an already-running CLI after installing or refreshing
the plugin. In `/hooks`, PostToolUse, SessionStart, UserPromptSubmit and
SubagentStart should each show one installed Andon hook; select each event to
review its hook. Scroll down to find SubagentStart. Zero installed hooks means
discovery failed, rather than that the hooks merely need trust.

The package uses `.codex-plugin/plugin.json` with explicit hook and MCP paths.
Codex CLI 0.163.0 accepted the portable root `plugin.json` package and marked it
enabled but returned no plugin hooks. Using the Codex manifest without a root
`plugin.json` restores discovery; adding a compatibility overlay beside the
portable root alone did not. Keep this layout until the real-host discovery test
passes for any proposed packaging change.

The hooks run the packaged `hooks/codex-hook` through `uv`. The adapter loads
the installed `andon` CLI as its shared backend; the desktop host must be able
to find both `uv` and `andon` on PATH. The adapter does not approve or rewrite
tool calls. MCP tool approval remains under Codex's normal policy.

Once trusted, `SessionStart` injects an Andon rule as developer context on
startup, resume, clear, fork and compaction. `UserPromptSubmit` refreshes it on
each user turn, and `SubagentStart` supplies it to workers. `PostToolUse` adds
bounded reminders after a command fails following a skill read, repeated failure
or a help probe following a failure. The model decides whether the evidence
warrants a pull; the sensor never creates alerts on its own.

Each session locks in its trigger level from `ANDON_LEVEL`, else the shared
saved default, else level 3. Resume and compaction keep that level; a new or
forked chat, or a cleared session, captures the current default. Chat messages
are not parsed as level commands and cannot change the active session's level.
The rule includes the full 1–5 sensitivity rubric, with the same reporting
policy as the Claude Code and OpenCode adapters.

Change the shared default for new sessions from a terminal:

```bash
andon level 5
andon level --reset
```

The first command saves level 5; the second removes the saved default, falling
back to 3. `ANDON_LEVEL` overrides either saved choice. MCP report arguments do
not include `level`; the trusted tool-result hook stamps each attributed report
with the locked session level. Without a recognized host callback, an MCP report
retains the shared backend's default level and `mcp` attribution.

Session state is stored under `$ANDON_STATE_DIR/codex`, or the default Andon
store's `codex/` directory. Files use hashed session IDs and mode 0600, with
per-session locks and atomic writes. They contain levels, bounded command hashes
and sensor flags, not prompt text or command bodies. State persists while a chat
is closed so resume can restore its locked level.

To disable automatic reporting while keeping the board, disable all four Andon
hooks in the hook browser and start a fresh chat. Disable the plugin to remove
both hooks and MCP tools. Disabling the global `hooks` feature also disables
other plugins' hooks.

### Local source and startup troubleshooting

The included marketplace is local: it registers this checkout as an authoring
source. The app installs a copy of `chatgpt/` into its plugin cache. It does not
copy the shared CLI. The CLI serves the board asset from its canonical
repository location. Keep this repository and its current `andon` command
installed.

If the server fails to start because the GUI cannot find `andon`, replace the
`command` value in this source directory's `mcp.json` with the absolute path
printed by `command -v andon`. Make sure `uv` is also on the desktop host's
`PATH`. Restart the app and refresh or reinstall the local plugin after changes
so its cached copy is updated. The package deliberately contains no
machine-specific path.

## Verify the board

Open the board and record a yellow alert through the CLI or an existing adapter.
The alert should appear at the next refresh. Open its details, copy the fix
prompt, resolve it, then choose the resolved status filter and reopen it. Check
that the CLI shows the same state:

```bash
andon list
andon stats
```

Use a temporary `ANDON_STATE_DIR` in both the desktop MCP server's environment
and the CLI if testing should use a separate store. By default, every process
reads `$ANDON_STATE_DIR`, or `${XDG_STATE_HOME:-~/.local/state}/andon`.
Different environment values create separate boards.

Closing the panel stops its refresh loop. Reopening it loads current data.
Connection errors remain visible so an interrupted server does not look like an
empty store. The plugin does not wake a closed chat or send background
notifications.

## Reporting boundaries

In local Codex with trusted hooks, the reporting rule is always present at the
supported lifecycle boundaries above. Yellow reports accompany safe workarounds;
red reports require stopping on the blocked path and explaining the decision
needed, including when a capability explicitly requested by the user is
unavailable. User instructions and host safety policy retain precedence.

After a successful Andon MCP `pull`, the tool-result hook stamps the matching
stored occurrence with `harness: codex`, the locked session level, the host
session ID, workspace and any host-provided tool-call ID, transcript path and
model. It never accepts these fields from model arguments, reads transcripts, or
creates another occurrence. Repeating the callback does not overwrite existing
attribution. If the host does not deliver a recognizable successful receipt, the
report remains `mcp` with no invented identity. Subagent events use the parent's
session ID; the adapter does not invent a worker identity. The board remains a
shared view across sessions.

Hosted tools and some specialized tool paths do not emit local tool hooks. Their
defects can still be reported by the model under the injected rule, but the
passive sensor cannot observe them. Hook errors are surfaced by Codex; they do
not block ordinary work. This integration requires local orchestration and
supported hooks, not just local execution for a cloud-orchestrated chat. Other
MCP clients retain the board and manual tools without these host rules.

### Verify automatic reporting

Run the deterministic adapter and shared-protocol checks from the repository
root:

```bash
prove skills/agent-config/tests/test-andon-codex \
  skills/agent-config/tests/test-andon-mcp skills/agent-config/tests/test-andon-panel
```

With Codex CLI installed, also run its real loader against an isolated temporary
Codex home and verify the four hooks are discovered, untrusted, from both a
project directory and an unrelated directory:

```bash
ANDON_CODEX_HOST_TEST=1 prove skills/agent-config/tests/test-andon-codex
```

This does not trust hooks, start a model turn, or alter your normal Codex
configuration.

For a host smoke test, use a temporary workspace with a fixture `SKILL.md` that
directs the agent to run a helper with an unsupported flag, plus a safe working
alternative. Start a fresh local Codex chat with the enabled, trusted plugin and
ask it to follow the skill. Do not explicitly request an alert. Verify a yellow
stale-instruction report in `andon list`, with the host chat attribution, while
the original task continues. In a terminal, set `andon level 1`, start a new
chat and repeat with another defect to verify no yellow report; set level 3 and
start another new chat to verify one. Change the saved default while that chat
is active, compact it and repeat to check the rule and locked level survive. Use
a fixture with circular requirements and no safe workaround to check red
reporting and stopping. These host/model checks complement wire-event replay
tests; replay tests alone do not prove model behavior or hook activation.

This package is intended for local marketplace installation. It depends on a
separately installed CLI and is not a self-contained public-directory
submission. There is no hosted service or account authentication.

See the [shared MCP interface](../../../references/andon-mcp.md) for tool
arguments, store behavior and attribution limits, and the
[Andon design](../README.md) for existing host adapters.

## Packaging references

- [OpenAI plugin packaging and local marketplaces](https://developers.openai.com/plugins/build/plugins)
- [Desktop-only MCP server configuration](https://developers.openai.com/plugins/deploy/desktop-only)
- [Conversation panel and sidebar entrypoints](https://developers.openai.com/plugins/build/extensions)

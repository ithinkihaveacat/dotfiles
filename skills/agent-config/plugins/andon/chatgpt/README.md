# Andon for ChatGPT desktop

This local plugin exposes the shared Andon MCP server and a live alert board in
ChatGPT desktop. Open the board beside a conversation or from the global
sidebar. Alerts recorded by the CLI, Claude Code and OpenCode appear in the same
board.

The panel calls MCP tools directly. It refreshes every three seconds while
visible, supports severity and status filters, shows recurrence counts, and
offers alert details, fix prompts and Resolve / Dismiss / Reopen actions. It
does not need a model turn to refresh.

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

Restart ChatGPT desktop, open the Plugins Directory, select **Agent Config
Desktop**, and install and enable **Andon**. Start a local chat, then ask "Open
the Andon board." This invokes the `board` MCP tool. The server advertises both
a conversation panel and a global sidebar entry; their availability depends on
the host's MCP UI extension support.

The included marketplace is local: it registers this checkout as an authoring
source. The app installs a copy of `chatgpt/` into its plugin cache. It does not
copy the shared CLI. The CLI serves the board asset from its canonical
repository location. Keep this repository and its current `andon` command
installed.

If the server fails to start because the GUI cannot find `andon`, replace the
`command` value in this source directory's `mcp.json` with the absolute path
printed by `command -v andon`. Make sure `uv` is also on the desktop host's
`PATH`. Restart the app and refresh or reinstall the local plugin after changes
so its cached copy is updated. The portable manifest deliberately contains no
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

The MCP tools let the agent pull the cord and inspect or triage alerts. This
package does not port the Claude Code or OpenCode always-on rule, passive
failure sensors, level overrides or trusted session attribution. The board shows
the shared store across sessions; it does not claim to filter by the current
chat. Tool approval policy remains under the host's control.

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

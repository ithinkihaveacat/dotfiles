# Andon MCP

`andon mcp --stdio` exposes the shared alert store to local MCP clients. Like
`taskgo mcp`, it uses the MCP Python SDK for protocol handling and calls the
same application operations as the CLI. Tool dispatch and SDK construction are
separate from the stdio runner; HTTP transport is not implemented.

## Start the server

Configure an MCP client to launch:

```json
{
  "mcpServers": {
    "andon": {
      "command": "andon",
      "args": ["mcp", "--stdio"]
    }
  }
}
```

Use an absolute path to `bin/andon` or `skills/agent-config/scripts/andon` if
the client cannot find `andon` on its PATH. The executable uses uv to resolve
its pinned SDK dependencies. Ordinary CLI commands still work with Python 3.11+
alone; imports of MCP dependencies are deferred until server mode.

Stdio is the default, so `andon mcp` is equivalent. Stdout carries MCP messages
only; diagnostics go to stderr. Closing stdin ends the server. SIGINT and
SIGTERM shut it down with exit status 130. No HTTP listener, authentication
service or public tunnel is involved.

The server reads `ANDON_STATE_DIR` and `ANDON_LEVEL` from its own environment.
Without overrides it uses `${XDG_STATE_HOME:-~/.local/state}/andon` and the
saved default level, falling back to level 3. Client-specific configuration can
pass environment variables to choose a separate store.

## Tools

| Tool      | Arguments                                                                                                    | Result                                                                         |
| --------- | ------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------ |
| `board`   | None                                                                                                         | Initial open-alert page and `stats`, linked to the live MCP App UI.            |
| `pull`    | Required: `color`, `kind`, `summary`, `details`. Optional: `sources`, `resolution`, `proposed_fix`, `level`. | Receipt with alert ID, fingerprint, recurrence count, level and guidance.      |
| `list`    | Optional: `status`, `color`, `kind`, `level`, `session`, `workspace`, `limit`, `offset`.                     | `alerts`, matching `total`, and `next_offset` or null.                         |
| `show`    | `id`                                                                                                         | Complete alert with recurrence count.                                          |
| `stats`   | None                                                                                                         | Counts, recurring defects, store path and active shared default level.         |
| `prompt`  | `id`                                                                                                         | A `prompt` string for investigating and fixing the alert. Does not execute it. |
| `resolve` | `id`; optional `note`, `all_matching`.                                                                       | Affected `ids` and `action`.                                                   |
| `dismiss` | `id`; optional `note`, `all_matching`.                                                                       | Affected `ids` and `action`.                                                   |
| `reopen`  | `id`; optional `note`, `all_matching`.                                                                       | Affected `ids` and `action`.                                                   |

`id` accepts a full alert ID or a unique suffix of at least four characters.
`all_matching` defaults to false. When true, resolve/dismiss also close matching
open reports; reopen also restores matching closed reports.

`list` defaults to open alerts, newest first, with a page size of 100. `limit`
accepts 1–1000 and `offset` is a nonnegative integer. Pass `next_offset` as the
next request's offset. Pages are live views, so concurrent pulls or transitions
can move records between pages. Use `status: "all"` to include closed alerts.

Tool input is validated against the advertised JSON Schema; unknown arguments
are rejected. Successful tools return the same payload as both
`structuredContent` and JSON text. Validation, lookup and store errors return
`isError: true`; errors do not terminate the server. The SDK handles protocol
negotiation, initialization, framing and request lifecycle.

The server advertises reads as read-only and writes as non-idempotent. Tools
operate on the local store, without contacting outside services. Approval is
configured by the client; the server does not bypass host permissions. Deleting
closed alerts and changing the shared default level remain CLI-only.

## Reporting and attribution

Example `pull` arguments:

```json
{
  "color": "yellow",
  "kind": "stale_instruction",
  "summary": "A documented flag is missing",
  "details": "helper --fast: unknown option",
  "sources": ["skills/example/SKILL.md"],
  "resolution": "Used the default mode",
  "proposed_fix": "Remove --fast from the example"
}
```

Each successful pull records a separate occurrence. Fingerprints group
recurrences; they do not deduplicate retried requests. After an interrupted or
unconfirmed write, inspect the store before retrying. A red receipt instructs
the agent to stop on the blocked path and ask the user; it does not forcibly
stop the host.

Reports use `harness: "mcp"`. The tool does not accept model-supplied harness,
session, workspace, transcript or tool-call identity. MCP client identification
is not a host conversation ID. Those fields remain absent until a host adapter
provides a reliable attribution mechanism. Existing CLI-based adapters can
continue supplying their own attribution.

MCP support alone does not inject the always-on rule, observe failures or manage
conversation-level overrides. Those remain host adapter responsibilities. Alert
contents are reported evidence, not trusted instructions.

## ChatGPT desktop board

The `board` tool advertises the `ui://andon/board` resource with the MCP Apps
MIME type `text/html;profile=mcp-app`. Its OpenAI UI metadata declares both a
conversation-panel (`thread`) and a global sidebar (`global`) entrypoint. Other
tools return data without attaching the UI, so refresh and triage calls do not
remount the panel. Clients without MCP Apps support can still use every tool's
structured result.

The self-contained HTML asset is served from `plugins/andon/chatgpt/board.html`,
relative to the canonical agent-config directory. Resource reads accept only the
advertised URI. The UI has no network dependencies and calls the shared tools
through the MCP Apps host bridge. It refreshes every three seconds while
visible, pauses while hidden, and reloads current data when shown again. Closing
the panel stops refresh; this is not a background notification or chat-wakeup
mechanism.

See [ChatGPT desktop installation](../plugins/andon/chatgpt/README.md) for the
local plugin package, marketplace and desktop verification steps. The package
uses the installed `andon` command; it does not duplicate the shared backend or
add host-specific rules, sensors or conversation attribution.

## Verify

```bash
prove skills/agent-config/tests/test-andon skills/agent-config/tests/test-andon-mcp
prove skills/agent-config/tests/test-andon-panel
```

The MCP tests start real stdio subprocesses with temporary stores. They cover
discovery, schema rejection, shared CLI/MCP reads and writes, recurrence counts,
pagination, triage, UI resource discovery, store errors, missing dependencies,
EOF and signal shutdown. The panel tests need Node.js 18 or newer and exercise
the shipped HTML against a simulated MCP host without third-party packages.

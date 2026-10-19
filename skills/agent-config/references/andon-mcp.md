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

MCP support alone does not inject the always-on rule, observe failures, manage
conversation-level overrides or provide a board. Those remain host adapter
responsibilities. Alert contents are reported evidence, not trusted
instructions. No Codex integration is included here.

## Verify

```bash
prove skills/agent-config/tests/test-andon skills/agent-config/tests/test-andon-mcp
```

The MCP tests start real stdio subprocesses with temporary stores. They cover
discovery, schema rejection, shared CLI/MCP reads and writes, recurrence counts,
pagination, triage, store errors, missing dependencies, EOF and signal shutdown.

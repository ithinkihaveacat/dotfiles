# Server Request Logs

Every MCP server in this repo (`taskgo mcp`, `pinboard mcp`, `skill mcp`,
`andon mcp`) keeps the same request log, so that one reader works for all of
them, and an operator can see what agents did without a shell on the host. This
file is the contract. A new long-running server follows it too.

## What Is Logged

One JSON record per request the server answers, and one per job it starts by
itself (a scheduled sync). What happened behind a request, such as a fetch of a
remote that failed, goes on that request's record rather than only to stderr. A
record says what was asked for, by whom, and how it ended. It never carries
content.

**Never logged:** titles, bodies, notes, file contents, edits (`old_string`,
`new_string`), search text, tokens, cookies, conversation links, or a JWT's
claims. Keep an allowlist of the arguments that name what a call is about (a
project, a task ID, a path, a URI) and shorten each one; hash anything that is
user text but useful for grouping (a search). A failure's reason is its first
line, with quoted values elided, since those can quote content.

Logging never fails a request. A record the file cannot take is dropped there,
with one warning on stderr; the stderr line remains.

## Where It Goes

- **File:** `--log FILE`, else `<TOOL>_MCP_LOG`, else
  `${XDG_STATE_HOME:-~/.local/state}/<tool>/mcp.jsonl`. Stdio and HTTP servers
  of one tool share the file by default.
- **Format:** JSON Lines, one record per line, UTF-8, compact separators.
- **Rotation:** before an append would take the file past 8 MiB, rename `FILE.3`
  to `FILE.4` and so on, then `FILE` to `FILE.1`, keeping four old files
  (`FILE.1` newest). Readers read `FILE.4` to `FILE` in that order and skip
  lines that are not records, since a write cut short leaves a partial line.
- **Locking:** each append and rotation holds `flock(LOCK_EX)` on the open file,
  then checks that the path still names the same inode (another server may have
  rotated it in between) and reopens if not.
- **Stderr:** the same record as one line, `<prog>: request k=v ...`, where a
  value is bare when it is a plain token (`[\w./:@+-]+`) and JSON-quoted
  otherwise, so client text can neither break nor forge a line.

## Record Fields

Fields with no value are left out. Every tool emits the core fields it can;
other fields are the tool's own, documented in its `--help`, and follow the same
no-content rule.

| Field       | Value                                                                       |
| ----------- | --------------------------------------------------------------------------- |
| `ts`        | When the request came, UTC, ISO 8601 with milliseconds and `Z`              |
| `transport` | `stdio`, `http`, or `background` for a job the server started               |
| `event`     | For `background` only: the job, such as `sync`                              |
| `http`      | The HTTP method                                                             |
| `method`    | The JSON-RPC method (`tools/call`, `resources/read`, …)                     |
| `tool`      | The tool, for `tools/call` (and a background job that runs one)             |
| `args`      | The allowlisted arguments, as strings of at most 60 characters              |
| `outcome`   | `ok`, `tool-error`, `rpc-error`, `refused`, or `error` (below)              |
| `status`    | The HTTP status                                                             |
| `ms`        | Duration in milliseconds                                                    |
| `bytes`     | Size of a tool call's result                                                |
| `reason`    | Why the outcome is not `ok`: a short phrase or code, at most 200 characters |
| `agent`     | The client's `User-Agent`, at most 80 characters                            |
| `caller`    | An opaque 10-hex-digit key for the caller (below)                           |
| `commit`    | The Git commit a call read or wrote, when the tool has one                  |
| `version`   | The server's version                                                        |

Outcomes:

- `ok`: the request was answered as asked.
- `tool-error`: a tool call ran and failed (`isError` in its result).
- `rpc-error`: a JSON-RPC error reply (unknown method, invalid params).
- `refused`: declined before it ran: an HTTP refusal (no token, wrong method,
  too large), or a tool's "not now" (rate limited, a sync already running).
- `error`: the server could not answer (an exception, a client gone).

The caller key is the first 10 hex digits of a SHA-256 over what identifies the
caller: over HTTP with Cloudflare Access, the token's `sub`, `email`,
`client_id`, and `azp` claims joined by NUL; over stdio, the transport, process
ID, and start time. It groups a caller's requests without naming them.

## Over HTTP

- **`/up`** answers `GET` and `HEAD` without a token, for a proxy's health
  check, and is never logged. Its body is JSON:
  `{"status":"ok","version":"...","commit":"..."}`, where `commit` is the
  server's own source commit when it runs from a Git checkout.
- **`/logs`** is a static page, behind the same authentication as the MCP
  endpoint, that shows the latest records and counts per client and tool. Its
  script is pinned by hash in a strict Content-Security-Policy, and every value
  is inserted as text. It polls rather than streams, since a buffering proxy
  (kamal-proxy) holds a stream back.
- **`/logs/records?after=N&server=ID`** returns
  `{"server", "version", "next", "records", "stats"}`: the records after cursor
  `N` from an in-memory ring of the latest 500, and statistics over the ring. A
  different `server` (the process's random ID) means the server restarted, so
  the cursor starts over. Polls are not logged; refusals are.
- Run uvicorn with `access_log=False`: the request log replaces its access log,
  which would otherwise log every poll.

## Summaries

Each tool summarises its log from the command line (`taskgo requests`,
`skill mcp --requests`, `pinboard mcp --requests`) with `--days N` (default 7)
and `--json`: requests and outcomes, then requests, failures, and p50/p95
latency per client and per tool, then the commonest runs of two or three tool
calls by one caller (calls 120 seconds apart or less). Since every log has one
format, any of them reads another's file with `--log FILE`; `andon mcp`, which
serves only stdio, has no summary of its own.

## Implementation

`taskgo`'s `McpEvent` and `McpLog` are where the format came from (its records
add `fetch` and `stale` when a request met a failed fetch of the remote).
`skill-mcp` and `pinboard-mcp` carry a copy of the same block, between the
`--- Request log ---` and `--- End of request log ---` markers, which a test
keeps identical in both; tool-specific parts (the argument allowlist, the
default path, the program name) are defined outside it. Copy that block into a
new server rather than importing it across skills. `andon`, with no HTTP server,
keeps a smaller local logger.

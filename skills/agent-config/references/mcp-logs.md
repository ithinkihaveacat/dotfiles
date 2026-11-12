# MCP Request Logs

The MCP servers in this repository (`taskgo mcp`, `skill mcp`, `pinboard mcp`,
`andon mcp`, `picgo mcp`) each write a request log, and `mcp logs` reads any
number of them. The servers only write; reading, statistics and the web page
belong to the reader. This file is the format both sides follow. Each server's
tests check its records against the tables below, so a field or outcome added
here, or in a server, must be added in both.

## Files

Each server writes to `--log FILE`, else `<TOOL>_MCP_LOG`, else
`${XDG_STATE_HOME:-~/.local/state}/<tool>/mcp.jsonl`. At 8 MiB the file is
rotated to `FILE.1` (newest) through `FILE.4`; every append and rotation holds
an exclusive `flock` on the file, so several processes may share it. A line that
does not parse as JSON, or has no `ts`, is not a record (a write cut short
leaves a partial line); readers skip it.

The server's name is the directory the file is in (`taskgo`, `skill`,
`pinboard`, `andon`, `picgo`), not a field of the record; `mcp logs --json` adds
it to each record it prints, as `server`. The parser is `parse_record()` in
`scripts/mcp-logs`.

## Records

One JSON object per line: one per JSON-RPC message, and one per job the server
starts on its own (a scheduled sync). A field with no value is left out.

<!-- The server tests read the field names from the first column. -->

| Field         | Value                                                                                                                                                                   |
| ------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ts`          | When the request came: UTC, ISO 8601 with milliseconds and `Z`                                                                                                          |
| `transport`   | `stdio`, `http`, or `background` (a job the server started)                                                                                                             |
| `event`       | A background job's name, such as `sync`                                                                                                                                 |
| `http`        | The HTTP method                                                                                                                                                         |
| `method`      | The JSON-RPC method, such as `tools/call`                                                                                                                               |
| `tool`        | The tool called                                                                                                                                                         |
| `args`        | The tool's allowlisted arguments, and identifiers derived from them (pinboard: a written URL's `host`, a `search` hash), as short strings; user text only as a `#` hash |
| `outcome`     | One of the outcomes below                                                                                                                                               |
| `status`      | The HTTP status                                                                                                                                                         |
| `ms`          | Duration in milliseconds                                                                                                                                                |
| `bytes`       | Size of a tool's result                                                                                                                                                 |
| `reason`      | Why it was not `ok`: a short phrase, never quoting input                                                                                                                |
| `agent`       | The client's `User-Agent`                                                                                                                                               |
| `caller`      | 10 hex digits of SHA-256 over the Access token's identifying claims, or over stdio, pid and start                                                                       |
| `commit`      | A Git commit the call made or read                                                                                                                                      |
| `version`     | The server's version                                                                                                                                                    |
| `scope`       | `skill mcp`: the scope the request was made to                                                                                                                          |
| `push`        | `skill mcp`: `ok` or `failed`, for an edit pushed after its commit                                                                                                      |
| `result`      | `pinboard mcp`: a sync's counts                                                                                                                                         |
| `retry_after` | `pinboard mcp`: seconds until a rate-limited call may be retried                                                                                                        |
| `fetch`       | `taskgo mcp`: why a fetch of the remote during the request failed or timed out                                                                                          |
| `stale`       | `taskgo mcp`: `true` when a read was served the last fetched head because the fetch failed                                                                              |

<!-- The server tests read the outcomes from the first column. -->

| Outcome      | Meaning                                                         |
| ------------ | --------------------------------------------------------------- |
| `ok`         | Answered without error                                          |
| `tool-error` | The tool ran and reported an error (`isError`)                  |
| `rpc-error`  | A JSON-RPC error, such as invalid params or an unparsable body  |
| `refused`    | Declined before it ran: authentication, HTTP method, rate limit |
| `error`      | No answer could be given                                        |

`probe` is not a record outcome: the reader groups a `GET` answered 405 under it
in summaries. That is a client checking for a server-initiated stream, which the
transport lets the server decline. Raw lines and `--json` keep the server's
`refused` outcome; the live page hides probe rows unless **Show protocol
probes** is ticked.

## Never Content

A record says what a call was about, never what it carried: no titles, bodies,
notes, file contents, edits, tokens, URLs beyond a host, or conversation links.
Search text is hashed. An error's reason is a fixed phrase, or its first line
with quoted values elided. Logging never fails a request: a record the file
cannot take is dropped, with one warning on stderr.

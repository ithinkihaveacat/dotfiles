# Long-Running Servers

Guidance for servers and daemons (an MCP server, an HTTP service), on top of the
signal rules in `cli-tools.md` ("Exit Codes: Local Extensions"). It says what a
server owes its operator, not how to lay out its data; the format is the
family's to fix (see "Servers of One Kind").

## Request Logs

A server keeps a record of what was asked of it, so that its operator can see
what clients did without attaching a debugger or reading its code.

- **One record per request**, and one per job the server starts on its own (a
  scheduled sync). Work behind a request, such as a failed fetch, belongs on
  that request's record. Use a structured, line-oriented format (JSON Lines).
- **Never content.** Keep an allowlist of the arguments that name what a call is
  about (an ID, a path, a URI), shortened; hash user text that is useful for
  grouping (a search). Error messages can quote input: log a fixed reason, or
  the first line with quoted values elided, never the raw message. Identify a
  caller by an opaque key derived from its credentials, never by its name, email
  or token.
- **Logging never fails a request.** A record the file cannot take is dropped,
  with one warning on stderr.
- **Bounded on disk.** Rotate by size and keep a fixed number of old files; lock
  appends if several processes share the file. The default location is
  `${XDG_STATE_HOME:-~/.local/state}/<tool>/`, overridable by flag and by a
  `<TOOL>_*` variable.
- **Servers write; one reader reads.** A server only appends records. Viewing,
  filtering, statistics and any web page belong to a separate reader that takes
  any number of logs, so the servers stay small and one view covers them all.
  Replace the HTTP framework's access log rather than keeping both.
- **An unauthenticated health check** that reads nothing private and is not
  logged, so a proxy can poll it.

## Servers of One Kind

When a repository has several servers of the same kind, such as its MCP servers,
they look alike to their operator: the same flags and environment variable
shapes, the same paths and endpoints, and records in one format that one reader
can summarise. That consistency is worth more than any one server's local
preference.

- **The existing servers are the specification.** Before writing or changing
  one, read the others and match them; do not design a new format. Where they
  have drifted, bring them back together rather than adding a third variant.
- **Share by copying.** Shared code between self-contained scripts is copied,
  not imported across tools (see "Script Self-Containment" in `cli-tools.md`).
  Mark the copied region, and keep it small enough that the copies are easy to
  keep in step.
- **Document the format beside its reader**, in one place, and test each
  writer's output against it, so that a server that drifts fails its own tests.

In this repository the MCP servers (`taskgo mcp`, `skill mcp`, `pinboard mcp`,
`andon mcp`, `picgo mcp`) are such a family. Each writes a request log;
`mcp logs` reads them, and `skills/agent-config/references/mcp-logs.md` is the
record format that every server's tests check against.

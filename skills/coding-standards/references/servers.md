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
- **Readable where the server runs.** A server reached over the network serves
  its recent records on a page behind the same authentication as its endpoint,
  and the command line can summarise the file. Replace the HTTP framework's
  access log rather than keeping both.
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
- **Share by copying, and test the copies.** Shared code between self-contained
  scripts is copied, not imported across tools (see "Script Self-Containment" in
  `cli-tools.md`). Mark the copied region and add a test that fails when the
  copies differ, so a fix to one reaches the others.
- **Document the format where it is defined**, at the head of the copied region,
  rather than in a separate document that can drift from it.

In this repository the MCP servers (`taskgo mcp`, `skill mcp`, `pinboard mcp`,
`andon mcp`) are such a family. The request log block in
`skills/agent-config/scripts/skill-mcp` (copied verbatim into `pinboard-mcp`) is
the reference: its header describes the record format.

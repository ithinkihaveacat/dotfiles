# MCP Server

`taskgo mcp` serves a control repository's committed state to MCP clients,
read-only. It is for agents that have a checkout of a code repository but not of
the control repository, such as cloud sessions. The server is the CLI script
itself, so its tools call the same functions as the matching subcommands and
their output matches the CLI's.

One server serves one control repository. It never writes.

## Tools

| Tool                 | Returns                                                                                   | CLI equivalent          |
| -------------------- | ----------------------------------------------------------------------------------------- | ----------------------- |
| `list_projects`      | Projects with task counts and in-progress and blocked IDs                                 | `taskgo status --json`  |
| `list_tasks`         | Task rows, by project and state (`ready` included)                                        | `taskgo list --json`    |
| `get_task`           | One task: frontmatter, sections with hashes, unresolved dependencies, Markdown            | the task file           |
| `get_project_status` | `STATUS.md`, its Summary and Next with hashes, the committed and a freshly computed block | `taskgo status PROJECT` |
| `read_file`          | Any UTF-8 file up to 256 KiB                                                              | `git show`              |
| `list_files`         | Files with blob SHAs, optionally under one directory                                      | `git ls-files -s`       |
| `dispatch_task`      | The dispatch note with findings and the data-care rule; paths are repository-relative     | `taskgo dispatch`       |
| `get_task_history`   | Changes of one frontmatter field, following renames                                       | `taskgo history`        |

Each call fetches the branch (`main` by default) from the remote (`origin`),
resolves it once, and reads only that commit, through a Git tree snapshot. It
never reads or changes the working tree. Every response carries `as_of`: the
commit read, its commit time, and today's date in the repository timezone.
Passing `as_of.commit` back as `at` keeps several calls on one commit, and skips
the fetch when that commit is already present.

`wait_for` gates other than dates are reported as `unverified_gates`. The server
does not poll them and, like the CLI, treats them as still holding. `dispatch`
on a checkout also warns about uncommitted changes; the server reads only
commits, so it never does.

## Transports

By default the server speaks MCP Streamable HTTP on `127.0.0.1:8789/mcp`,
statelessly: each POST carries one JSON-RPC message and gets one JSON response.
There is no server-initiated stream and no session. `--stdio` serves one local
client on standard input and output instead, without authentication.

## Authentication

Cloudflare Access is meant to sit in front of the server, for example through a
Cloudflare Tunnel, with Managed OAuth enabled so that MCP clients can sign in
through a browser and then use refreshable tokens. Access forwards each
authorized request with a `Cf-Access-Jwt-Assertion` header. The server verifies
its RS256 signature against the team's certificates, its issuer (the team
domain), its audience (the application's AUD tag), and its expiry, and refuses
anything else: 401 without a token, 403 with a bad one.

Configure the check with `--access-team` and `--access-aud`, or with
`TASKGO_MCP_ACCESS_TEAM` and `TASKGO_MCP_ACCESS_AUD`. The server refuses to
start without them unless given `--auth none`, which serves only requests
addressed to a loopback name and only on a loopback address. Keep `--auth none`
for local testing: a tunnel to a loopback port that preserves the `Host` header
is still refused, but one that rewrites it to `localhost` is not.

## Testing

From the skill directory:

```sh
tests/make-synthetic /tmp/synth                        # a synthetic tracker
scripts/taskgo --root /tmp/synth mcp --no-fetch --auth none &
tests/compare-cli http://127.0.0.1:8789/mcp /tmp/synth # server versus CLI
tests/mcp-call http://127.0.0.1:8789/mcp list_tasks '{"state":"ready"}'
tests/auth-check                                       # Access JWT validation
```

`compare-cli` asks the server for its commit, checks that commit out into a
temporary clone, and compares every tool's output with the CLI's there. It
prints only check names and counts, never file contents, so it is safe to run
against a private tracker. `test-taskgo` runs `compare-cli` on a synthetic
tracker and `auth-check`.

The MCP Inspector works against a local server:

```sh
npx @modelcontextprotocol/inspector --cli http://127.0.0.1:8789/mcp \
  --transport http --method tools/list
```

## Data care

Everything the server returns is private tracker content. Its MCP instructions
and every dispatch note tell the client never to copy it into artifact
repositories. The host running the server holds a clone of the control
repository, so the same care applies to the host.

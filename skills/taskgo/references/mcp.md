# MCP Server

`taskgo mcp` serves a control repository's committed state to MCP clients, and
writes to it on their behalf. It is for agents that have a checkout of a code
repository but not of the control repository, such as cloud sessions. The server
is the CLI script itself, so its tools call the same functions as the matching
subcommands and their output matches the CLI's.

One server serves one control repository.

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
| `create`             | Creates one task or decision as one commit, and returns its ID                            | `taskgo create`         |
| `apply_changes`      | Applies a change set as one commit                                                        | `taskgo apply`, commit  |

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

## Writes

`create` and `apply_changes` take a change set (see
[Change Sets](model.md#change-sets); `create` is a set with one `create`) and
make it one commit on the branch, or nothing:

1. Fetch the branch and apply the set over its head, in memory, as
   `taskgo apply` does: every precondition (expected value, section hash, blob
   SHA) is checked against that head, the whole result is validated, and the
   affected `STATUS.md` blocks are regenerated.
1. Commit the result without a working tree, through a temporary index, with the
   head as the only parent.
1. Push it without force. If the remote refuses (another push got there first),
   fetch again: when the commit is on the branch after all, the push did land;
   otherwise apply the set again over the new head, so its preconditions are
   checked against what is now there. After five refused pushes the write fails
   and nothing is written.

Calls are serialized, so the server's own writes never race each other; pushes
from CLI checkouts race with them on equal terms, through the remote's refusal
of a non-fast-forward push.

Commits read like CLI commits: the configured owner as author and committer (the
server refuses to write without `user.name` and `user.email`, or the
`GIT_AUTHOR_*` and `GIT_COMMITTER_*` variables, and never guesses one), a
Conventional Commits subject scoped to the project (the caller's, or one derived
from the changes), an optional body, and only the trailers the caller asks for:
`Conversation:` for its session URI, which also joins the conversations of every
task the write touches, and `Ref:` for each reference. Writes are refused unless
`AGENTS.md` at the head carries `<!-- taskgo:allow-local-commits -->`, and a
server started with `--no-fetch` does not write.

Every write takes a `request_id`. The server keeps, in memory, the digest of the
request's arguments and each commit it built for it, for a day. A request whose
ID it has seen reports the earlier commit, when that commit is on the branch,
instead of writing again, so a client that lost a reply can retry safely; the
same ID with different arguments is refused. A restart forgets the IDs, which
loses only that recognition, never a write.

Each write logs a line to standard error for each push attempt, with the request
ID, the commit, and the head it was built on, or Git's reason for a refusal, and
for each retry it recognizes.

A push from a checkout that the server has moved past is refused as a
non-fast-forward; `git pull --rebase` brings the checkout up to date. When both
sides changed one project's `STATUS.md`, the rebase stops on its generated
block. Take the upstream file, regenerate it, and continue:

```sh
git checkout --ours alpha/STATUS.md   # during a rebase, ours is upstream
taskgo sync alpha
git add alpha/STATUS.md
git rebase --continue
```

## Transports

By default the server speaks MCP Streamable HTTP on `127.0.0.1:8789/mcp`,
statelessly: each POST carries one JSON-RPC message and gets one JSON response.
There is no server-initiated stream and no session. `GET /up` answers 200
without authentication and without reading the repository, for a reverse proxy's
health check. `--stdio` serves one local client on standard input and output
instead, without authentication.

## Logging

The server logs to standard error. Every request, except the health check,
leaves one line once it is answered:

```text
taskgo mcp: request transport=http http=POST method=tools/call tool=get_task outcome=ok status=200 ms=41 commit=1a2b3c4d5e6f agent=example-client/1.0
taskgo mcp: request transport=http http=POST outcome=refused status=403 ms=1 reason="Access token expired" agent=example-client/1.0
```

Fields appear in that order, and only when they apply: `transport` (`http` or
`stdio`), the HTTP verb, the JSON-RPC `method`, the `tool`, the `outcome`, the
HTTP `status`, the duration in `ms`, the `commit` a tool call read or wrote, the
`reason` for anything but `ok`, and the client's `User-Agent`. The outcome is
`ok`, `tool-error` (the call failed and the client got an error result),
`rpc-error` (an unknown method, a parse error, a malformed message), `refused`
(an HTTP refusal: authentication, a wrong host or path, a request too large), or
`error` (the reply could not be sent). A refused request's body is never read,
so it has no method. A value that is not a plain token, such as an unknown
method or tool name from a client, is quoted as JSON and truncated, so it cannot
break or forge a line.

Lines name requests, never their content: no arguments, task text, file content,
or tokens. An authentication refusal gives its reason (no token, bad signature,
wrong audience or issuer, expired). A tool error gives its message, with every
quoted value elided, since a failed precondition quotes the record's current
value, which can be a title. Write attempts log the lines described under
[Writes](#writes) first. To follow a server:

```sh
grep 'taskgo mcp: request' server.log | grep -v 'outcome=ok'
```

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
tests/auth-check                                       # Access JWTs, log lines
```

`compare-cli` asks the server for its commit, checks that commit out into a
temporary clone, and compares every tool's output with the CLI's there. It
prints only check names and counts, never file contents, so it is safe to run
against a private tracker. `tests/write-check` serves a throwaway tracker pushed
to a local bare repository and checks the writes: concurrent writers, a lost
push reply, a head that moves before every push, refusals, and a stale CLI
checkout that recovers by rebase. `test-taskgo` runs `compare-cli` on a
synthetic tracker, `auth-check`, and `write-check`.

The MCP Inspector works against a local server:

```sh
npx @modelcontextprotocol/inspector --cli http://127.0.0.1:8789/mcp \
  --transport http --method tools/list
```

## Data care

Everything the server returns is private tracker content. Its MCP instructions,
every write tool's description, and every dispatch note tell the client never to
copy it into artifact repositories. The host running the server holds a clone of
the control repository, so the same care applies to the host.

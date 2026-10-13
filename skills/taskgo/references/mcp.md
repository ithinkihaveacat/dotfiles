# MCP Server

`taskgo mcp` serves a control repository's committed state to MCP clients, and
writes to it on their behalf. It is for agents that have a checkout of a code
repository but not of the control repository, such as cloud sessions. The server
is the CLI script itself, so its tools call the same functions as the matching
subcommands and their output matches the CLI's.

One server serves one control repository.

## Tools

| Tool                 | Returns                                                                                                                 | CLI equivalent           |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------- | ------------------------ |
| `list_projects`      | Projects with task counts and in-progress and blocked IDs                                                               | `taskgo status --json`   |
| `list_tasks`         | Task rows, by project and state (`ready` included)                                                                      | `taskgo list --json`     |
| `get_task`           | One task: frontmatter, sections with hashes, unresolved dependencies, Markdown                                          | the task file            |
| `get_project_status` | `STATUS.md`, its Summary and Next with hashes, the committed and a freshly computed block                               | `taskgo status PROJECT`  |
| `read_file`          | A UTF-8 file, whole or lines `start_line`..`end_line`, up to 256 KiB after a whole line                                 | `taskgo read --json`     |
| `search_files`       | `git grep` lines and the files they name, up to 64 KiB; allowlisted options                                             | `taskgo search --json`   |
| `list_files`         | Files with blob SHAs, optionally under one directory                                                                    | `git ls-files -s`        |
| `dispatch`           | For a project or task: the note, findings, the files to read first verbatim, the skills, and the active and ready tasks | `taskgo dispatch --json` |
| `get_task_history`   | Changes of one frontmatter field, following renames                                                                     | `taskgo history`         |
| `create`             | Creates one task or decision as one commit, and returns its ID                                                          | `taskgo create`          |
| `apply_changes`      | Applies a change set as one commit                                                                                      | `taskgo apply`, commit   |
| `edit_file`          | Replaces exact text in one file as one commit; reports lines and the new blob                                           | `taskgo edit`, commit    |

Each call fetches the branch (`main` by default) from the remote (`origin`),
resolves it once, and reads only that commit, through a Git tree snapshot. It
never reads the working tree, and changes it only as a `--local` server's write
does (see [Writing to a checkout](#writing-to-a-checkout)). Every response
carries `as_of`: the commit read, its commit time, today's date in the
repository timezone, and `stale: true` when the commit is a head that could not
be refreshed. Passing `as_of.commit` back as `at` keeps several calls on one
commit, and skips the fetch when that commit is already present.

To spare the remote a round trip per call, a read within `--fetch-ttl` seconds
(5 by default) of the last fetch, or of the server's own push, uses that head
without fetching. Bursts of calls fetch once, and a read after a write sees the
write at once; a push from elsewhere can go unseen for up to the TTL.
`--fetch-ttl 0` fetches for every call, and for every write before it applies.
The cache is the remote-tracking ref and a timestamp in memory, so a restart
only costs a fetch.

When the fetch fails (the remote is unreachable, or it times out after a
minute), an unpinned read is served the head last fetched, or last pushed by
this server, if there is one, and its `as_of` carries `"stale": true`; the
failure is logged on standard error. Unpinned reads within `--fetch-ttl` seconds
of the failure are served the same way without fetching again, so an unreachable
remote costs one fetch (at most a minute) per TTL, not one per call; with
`--fetch-ttl 0`, every read tries. A read with nothing fetched yet, a pinned
read whose commit is not present, and every write fail instead: nothing is
written over a head that may have moved.

`wait_for` gates other than dates are reported as `unverified_gates`. The server
does not poll them and, like the CLI, treats them as still holding. `dispatch`
on a checkout also warns about uncommitted changes; the server reads only
commits, so it never does.

## Dispatch

`dispatch(target)` is the first call of a session: `target` is a project name or
a task ID, and one round trip returns what the workflow reads before acting.

- `note`: the short dispatch note, as `taskgo dispatch` prints it, with
  repository-relative paths and the data-care rule.
- `findings` and `unverified_gates`: readiness and audit findings, and the
  project's unverified gates.
- `frontmatter`: the project `README.md` frontmatter as YAML parses it, with no
  key filtered or renamed (`{}` without one).
- `skills`: the agent skills that frontmatter declares, normalized to a list of
  names as the `skill` CLI resolves them (`[]` without any). The note says how
  to activate them; a client without a skill manager ignores them.
- `readme`, `plan`, `agents_md`: the project `README.md` (or `PROJECT.md`),
  `PLAN.md`, and the root `AGENTS.md`, each `{path, blob, content, truncated}`
  or null when absent. Content is the file's bytes, cut after a whole line at
  256 KiB as `read_file` cuts it.
- `status`: `STATUS.md` the same way, plus its `sections` with hashes (for
  `replace_section`), `committed_block`, `live_block` (the task block computed
  now), and `block_current` (the same projection `get_project_status` returns).
- `tasks`: the project's `in_progress`, `blocked` (as the `STATUS.md` snapshot
  counts them), and `ready` rows, as `list_tasks` returns them.
- `task`: for a task ID, the record as `get_task` returns it; null for a
  project. Done and cancelled tasks are refused.

`blob` values serve as `expected_blob` for `edit_file`, `write_file`, and
`delete_file`. `read_file` content is the file's bytes, so it can be quoted in
`old_string` as it is; `line_numbers: true` prefixes each line with its number
and `: ` (as in `7: text`), counted against the 256 KiB, for citing lines or
choosing a range, and leaves the content no longer the file's bytes.

## Writes

`create`, `apply_changes`, and `edit_file` take a change set (see
[Change Sets](model.md#change-sets); `create` is a set with one `create`, and
`edit_file` a set with one `edit_file`) and make it one commit on the branch, or
nothing:

1. Apply the set over the head, in memory, as `taskgo apply` does: every
   precondition (expected value, section hash, blob SHA) is checked against that
   head, the whole result is validated, and the affected `STATUS.md` blocks are
   regenerated. The head is the cached one when the server has fetched or pushed
   since it started, and `--fetch-ttl` is not 0; otherwise the server fetches it
   first. A refusal over a cached head (a failed precondition or validation, no
   change, no commit authority) fetches and applies the set again over the
   fetched head; a malformed set fails at once.
1. Commit the result without a working tree, through a temporary index, with the
   head as the only parent.
1. Push it without force, which also checks that a cached head is still the
   head: a write in steady state is one round trip. If the remote refuses
   (another push got there first), fetch again: when the commit is on the branch
   after all, the push did land; otherwise apply the set again over the new
   head, so its preconditions are checked against what is now there. After five
   refused pushes, not counting a first push over a cached head, the write fails
   and nothing is written.

Calls are serialized, so the server's own writes never race each other; pushes
from CLI checkouts race with them on equal terms, through the remote's refusal
of a non-fast-forward push.

`edit_file` names its target by text, not by hash: applied again over a moved
head, it matches `old_string` afresh, so an edit lands beside another writer's
change to a different part of the same file, and `old_string` that is no longer
there is a precondition failure. Pass `expected_blob` (from `read_file` or
`list_files`) to refuse any change made since the file was read. A miss returns
a unified diff of `old_string` against the closest lines of the file.

Commits read like CLI commits: the configured owner as author and committer (the
server refuses to write without `user.name` and `user.email`, or the
`GIT_AUTHOR_*` and `GIT_COMMITTER_*` variables, and never guesses one), a
Conventional Commits subject scoped to the project (the caller's, or one derived
from the changes), an optional body, and the trailers the caller asks for:
`Conversation:` for its session URI, which also joins the conversations of every
task the write touches, and `Ref:` for each reference. After those, every commit
carries `Request-Id:`, the write's `request_id`, and `Request-Digest:`, the
first 16 hex digits of the SHA-256 of its other arguments as sorted JSON. Writes
are refused unless `AGENTS.md` at the head carries
`<!-- taskgo:allow-local-commits -->`, and a server started with `--no-fetch`
does not write.

Every write takes a `request_id`. The server keeps, in memory, the digest of the
request's arguments and each commit it built for it, for a day. A request whose
ID it has seen reports the earlier commit, when that commit is on the branch,
instead of writing again, so a client that lost a reply can retry safely; such a
retry always fetches, and does not trust a cached head. The same ID with
different arguments is refused. The table is in memory, but the recognition
survives a restart: a write whose ID is not in memory first looks for its
`Request-Id:` trailer in the last 200 commits behind the head: a commit found
with the same `Request-Digest:` is reported as `replayed: true`, from what the
commit records (its subject, the records it created, and the files it changed,
but not the lines of its edits), and one with another digest is refused as a
reused ID. A retry is thus recorded once across restarts, as long as its commit
is within those 200.

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

### Writing to a checkout

`--local` serves a checkout on the same machine, with no remote: typically a
`--stdio` server pointed at the user's own control repository (`--root`), for
agents working in other workspaces there, which have no clone of it and no
tunnel to a hosted server. Reads see the local branch as it is, for every call,
with no fetch and no cache. A write commits as above, through a temporary index,
and then moves the local branch to the commit instead of pushing it,
compare-and-swap style: the move is refused if the branch is no longer at the
head the set was applied over (a commit from the CLI got there first), and the
server then applies the set again over the new head, as after a refused push.
Before moving, the server requires the checkout to have the branch checked out
and no uncommitted change (staged, unstaged, or untracked) to any path the
commit touches; other dirty paths do not matter. After moving, it brings the
index and working tree from the old head to the new one for the touched paths
only (`git read-tree -m -u`), which also removes files the commit deletes, so
the checkout shows the commit as if it had been made there and the CLI goes on
working with no rebase. The checkout is never pushed; that stays with the user.
`--local` and `--no-fetch` exclude each other.

## Transports

The official MCP Python SDK speaks the protocol, so the server supports every
revision the pinned SDK does: 2026-07-28, whose clients open with
`server/discover`, and the earlier revisions back to 2024-11-05, whose clients
open with `initialize`.

By default the server speaks MCP Streamable HTTP on `127.0.0.1:8789/mcp`,
statelessly: each POST carries one JSON-RPC message and gets one JSON response.
There is no server-initiated stream and no session, so `GET` and `DELETE` on the
endpoint get 405. A POST whose `Accept` header does not admit `application/json`
(`*/*` does) gets 406. `GET /up` answers 200 without authentication and without
reading the repository, for a reverse proxy's health check. `GET /favicon.ico`
and `GET /apple-touch-icon*.png`, which browsers ask for on their own, get 404
without authentication and are not logged. `GET /logs` is a page of the server's
latest requests (see [Logging](#logging)), behind the same check as the
endpoint. `--stdio` serves one local client on standard input and output
instead, without authentication. A stdio server for agents on the same machine
as the user's checkout is usually started with `--local` (see
[Writing to a checkout](#writing-to-a-checkout)), so that their writes land on
the checkout's branch without a remote in between:

```json
{"command": "taskgo", "args": ["--root", "/home/me/projects", "mcp", "--local", "--stdio"]}
```

## Logging

Every request, except the health check and the log page's own, is logged twice
once it is answered: as a line on standard error, and as a JSON record appended
to the request log. The line:

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
break or forge a line. A JSON-RPC error's reason is a fixed phrase for its code
(`method not found`, `parse error`), not the error's message, which can quote
the request.

The record has the same fields, under the same names (`agent` for the
`User-Agent`), plus:

- `ts`: when the request came, in UTC with milliseconds;
- `args`: a tool call's identifying arguments, each shortened to one line of 60
  characters: `target`, `project`, `id`, `state`, `path`, `prefix`, `field`,
  `kind`, `slug`, the line range and flags, the search's `args` and `paths`,
  `at`, and `request_id`, and for `apply_changes`, each change's operation and
  target (`2: set TASK-3A91F status, edit_file proj/PLAN.md`). Arguments that
  carry text (titles, sections, bodies, file content, `old_string` and
  `new_string`, values) and conversation links are left out;
- `bytes`: the size of a successful tool call's result;
- `caller`: an opaque key for the caller, a hash of the Access token's
  identifying claims (`sub`, `email`, and an OAuth client claim if there is
  one), or of a stdio server's process; HTTP with `--auth none` has none;
- `version`: the server's version.

```json
{"ts":"2026-10-13T08:22:11.547Z","transport":"http","http":"POST","method":"tools/call","tool":"list_tasks","args":{"project":"proj","state":"ready"},"outcome":"ok","status":200,"ms":33,"bytes":1597,"commit":"af97eff1c9d2","agent":"Claude-User","caller":"3f9c0a1b2d","version":"0.12.0"}
```

The request log is `--log FILE`, else `TASKGO_MCP_LOG`, else
`$XDG_STATE_HOME/taskgo/mcp.jsonl` (`~/.local/state/taskgo/mcp.jsonl`), over
either transport, so stdio servers keep one too. At 8 MiB the file is renamed
`FILE.1`, and older ones move up to `FILE.4`, which is dropped: at most 40 MiB.
Several servers can share a file, as stdio servers do by default; each append
and rotation locks it. Logging never fails a request: if the file cannot be
written, the server says so once on standard error and keeps logging lines
there.

Lines and records name requests, never their content: no task text, file
content, edits, or tokens. A record's `args` can still hold a short private
detail, such as a project name, a path, or a search pattern; the log stays on
the server's host and behind the endpoint's check, and is not for copying into
artifact repositories. An authentication refusal gives its reason (no token, bad
signature, wrong audience or issuer, expired). A tool error gives its message,
with every quoted value elided, since a failed precondition quotes the record's
current value, which can be a title. Write attempts log the lines described
under [Writes](#writes) first. The first request with each kind of valid Access
token (a browser's, a client's) also logs the names, not the values, of its
claims, which say what a caller key could be built from.

**The log page.** Over HTTP, `GET /logs` is a page of the latest 500 requests,
newest first, with requests, failures, and latency per client and per tool, and
the commonest runs of tool calls. It polls `GET /logs/records?after=N` every
second for the records after its cursor and the stats over those kept, so a
request shows within about a second. The server loads the latest records from
the request log when it starts, so the page survives a restart. Both routes are
plain HTTP, not MCP: no tool, resource, or instruction mentions them. They need
what the endpoint needs (an Access token, or a loopback name with
`--auth none`), so any client that can call the tools can read them too: the log
is less sensitive than the tracker they already read. Their refusals are logged;
the page's polling is not.

**Summaries.** `taskgo requests` reads the request log and its rotated files
(`--log`, else as for the server) and prints requests by outcome, then requests,
failures, latency, and median result size per client and per tool, then the
commonest runs of two or three tool calls by client. A run counts within one
caller's chain: its tool calls, each at most `--gap` seconds (120) after the one
before, since stateless HTTP has no session to group them by. `--days` (7)
limits the records read, and `--json` prints the same as JSON, with client names
in full; the text cuts them at 20 characters, as the page does. The records are
JSON lines, so `jq` reads them too:

```sh
taskgo requests --days 1
jq -r 'select(.outcome != "ok") | [.ts, .agent, .tool, .reason] | @tsv' ~/.local/state/taskgo/mcp.jsonl
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
tests/auth-check                                       # Access JWTs, the log
```

`protocol-check` needs the SDK, so run it with the interpreter of taskgo's own
script environment:

```sh
py=$(uv python find --script scripts/taskgo)
"$py" tests/protocol-check /tmp/synth   # both protocol eras, both transports
```

`compare-cli` asks the server for its commit, checks that commit out into a
temporary clone, and compares every tool's output with the CLI's there. It
prints only check names and counts, never file contents, so it is safe to run
against a private tracker. `tests/test-taskgo-mcp-write` serves a throwaway
tracker pushed to a local bare repository and checks the writes: concurrent
writers, a lost push reply, a head that moves before every push, refusals, a
stale CLI checkout that recovers by rebase, the cached head (reads within the
TTL, writes over a stale cached head, and a retry after a lost reply), a read
served a stale head when the remote cannot be fetched, a retry recognized from
its `Request-Id:` trailer by a new server, and a `--local` server on a checkout
(a write lands on the local branch and in the working tree, is refused over a
dirty touched file or a detached HEAD, and is applied again after a CLI commit
gets in first; one write goes over `--stdio`); run it again with `--fetch-ttl 0`
to check the servers without a cache. `protocol-check` connects the SDK's own
client as a 2026-07-28 client and as a 2025-11-25 one, over HTTP and over
`--stdio`. `auth-check` also checks the log page and its records, with and
without a token, and that the request log holds one record per request and no
token. The test suite (`prove skills/taskgo/tests/test-*`) runs `compare-cli`
and `protocol-check` on a synthetic tracker, `auth-check`, and
`test-taskgo-mcp-write` both ways.

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

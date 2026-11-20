# MCP Server

This page is for people who run or change the server. Callers learn everything
they need from the server itself.

`taskgo mcp` serves a control repository's committed state to MCP clients, and
writes to it on their behalf. It is for agents that have a checkout of a code
repository but not of the control repository, such as cloud sessions. One server
serves one control repository.

`taskgo mcp` delegates to `scripts/taskgo-mcp`, found through the `SKILL.md`
sentinel or `TASKGO_SKILL_DIR`. That script carries the MCP, HTTP, and JWT
dependencies and loads `scripts/taskgo` in-process, so both share one snapshot,
audit, and change-set implementation. Both `taskgo mcp` and `taskgo-mcp` are
listed in `permissions/unsafe`. `taskgo mcp --help` lists every option; see
[command-index.md](command-index.md).

## Running the Server

The official MCP Python SDK speaks the protocol, so the server supports every
revision the pinned SDK does. The tests cover a 2026-07-28 client, which opens
with `server/discover`, and a 2025-11-25 client, which opens with `initialize`.

**HTTP.** By default the server speaks MCP Streamable HTTP on
`127.0.0.1:8789/mcp` (`--host`, `--port`, `--path`), statelessly: each POST
carries one JSON-RPC message and gets one JSON response. There is no
server-initiated stream and no session, so other methods on the endpoint get
405\. `GET /up` answers 200 with the server's version and commit, without
authentication and without reading the repository, for a reverse proxy's health
check. It is not logged.

**stdio.** `--stdio` serves one local client on standard input and output,
without authentication. A stdio server for agents on the same machine as the
user's checkout is usually started with `--local` (see
[Writing to a checkout](#writing-to-a-checkout)), so their writes land on the
checkout's branch with no remote in between:

```json
{"command": "taskgo", "args": ["--root", "/home/me/projects", "mcp", "--local", "--stdio"]}
```

### Configuration

| Option                          | Environment                                       | Default                            |
| ------------------------------- | ------------------------------------------------- | ---------------------------------- |
| `--remote REMOTE`               |                                                   | `origin`                           |
| `--branch BRANCH`               |                                                   | `main`                             |
| `--fetch-ttl SECS`              |                                                   | `5`                                |
| `--no-fetch` or `--local`       |                                                   | fetch from the remote              |
| `--auth {access,none}`          |                                                   | `access`                           |
| `--access-team`, `--access-aud` | `TASKGO_MCP_ACCESS_TEAM`, `TASKGO_MCP_ACCESS_AUD` | none                               |
| `--log FILE`                    | `TASKGO_MCP_LOG`                                  | `$XDG_STATE_HOME/taskgo/mcp.jsonl` |

Flags win over variables. Without `XDG_STATE_HOME`, the log is
`~/.local/state/taskgo/mcp.jsonl`. `--root` (before `mcp`) or `TASKGO_ROOT`
chooses the repository, as for every command.

## Reads

Each call fetches the branch from the remote, resolves it once, and reads only
that commit, through a Git tree snapshot. It never reads the working tree, and
changes it only as a `--local` server's write does. Every response carries
`as_of`: the commit read, its commit time, today's date in the repository
timezone, and `stale: true` when the commit is a head that could not be
refreshed.

A read within `--fetch-ttl` seconds of the last fetch, or of the server's own
push, uses that head without fetching. Bursts of calls fetch once, and a read
after a write sees the write at once; a push from elsewhere can go unseen for up
to the TTL. `--fetch-ttl 0` fetches for every call, and for every write before
it applies. The cache lives in memory, so a restart costs only a fetch.

When a fetch fails (the remote is unreachable, or it times out after a minute),
an unpinned read is served the head last fetched or pushed, marked stale, and
the failure is logged. Reads within the TTL of the failure are served the same
way without trying again. A read with nothing fetched yet, a pinned read whose
commit is not present, and every write fail instead.

`--no-fetch` serves the local branch without fetching, and does not write.

## Writes

`create`, `apply_changes`, and `edit_file` each make one commit on the branch,
or nothing. A write needs:

- `AGENTS.md` at the head declaring `taskgo`;
- a commit identity: `user.name` and `user.email`, or the `GIT_AUTHOR_*` and
  `GIT_COMMITTER_*` variables (the server never guesses one);
- a remote, or `--local`.

The server applies the [change set](change-sets.md) over the head in memory, as
`taskgo apply` does, commits the result through a temporary index with the head
as its only parent, and pushes it without force. If the remote refuses the push
(another writer got there first), the server fetches. When its commit is on the
branch after all, the push did land; otherwise it applies the set again over the
new head, so preconditions are checked against what is there now. After five
refused pushes the write fails and nothing is written.

Calls are serialized, so the server's own writes never race each other. Pushes
from CLI checkouts race with them on equal terms, through the remote's refusal
of a non-fast-forward push.

Each write logs a line to standard error for each push attempt, with the request
ID, the commit, and the head it was built on, or Git's reason for a refusal. It
also logs each retry it recognizes.

### Commit Trailers

Commits read like CLI commits: the configured owner as author and committer, a
Conventional Commits subject scoped to the project, an optional body, and these
trailers:

- `Conversation:` and `Ref:`, when the caller passes a session URI or
  references.
- `MCP-Client:`, on every commit: the client's name and version from its MCP
  `clientInfo` when the session kept it (over stdio), else its HTTP
  `User-Agent`. It makes a write attributable to a client without a
  conversation.
- `Request-Id:`, the write's `request_id`, and `Request-Digest:`, the first 16
  hex digits of the SHA-256 of its other arguments as sorted JSON.

### Retries

The server remembers each `request_id` in memory for a day. A request whose ID
it has seen reports the earlier commit, when that commit is on the branch,
instead of writing again. The same ID with different arguments is refused. After
a restart, the server looks for the `Request-Id:` trailer in the last 200
commits behind the head: a match with the same `Request-Digest:` is reported as
`replayed: true`, and one with another digest is refused as a reused ID.

### Conflicts in a Checkout

A push from a checkout the server has moved past is refused as a
non-fast-forward; `git pull --rebase` brings the checkout up to date. When both
sides changed one project's `STATUS.md`, the rebase stops on its generated
block. Take the upstream file, regenerate it, and continue:

```sh
git checkout --ours alpha/STATUS.md   # during a rebase, ours is upstream
taskgo sync alpha
git add alpha/STATUS.md
git rebase --continue
```

### Writing to a Checkout

`--local` serves a checkout on the same machine, with no remote. It suits a
`--stdio` server pointed at the user's own control repository, for agents in
other workspaces that have no clone of it. `--local` and `--no-fetch` exclude
each other.

Tool calls serialize with the CLI on `<git-dir>/taskgo.lock`. Reads see the
local branch as it is, with no fetch and no cache. A write commits as above,
then moves the local branch to the commit instead of pushing it. The move is
refused if the branch has moved since the write read it (a CLI commit got there
first); the server then applies the set again, as after a refused push.

Before moving, the server requires:

- the branch checked out;
- no unfinished rebase, merge, cherry-pick, or revert, and no unmerged files;
- no uncommitted change (staged, unstaged, or untracked) to any path the commit
  touches. Other dirty paths do not matter.

After moving, it updates the index and working tree for the touched paths only
(`git read-tree -m -u`), so the checkout shows the commit as if it had been made
there. The server never pushes the checkout; that stays with the user.

## Authentication

Cloudflare Access is meant to sit in front of the server, for example through a
Cloudflare Tunnel, with Managed OAuth enabled so that MCP clients can sign in
through a browser and then use refreshable tokens. Access forwards each
authorized request with a `Cf-Access-Jwt-Assertion` header. The server verifies
its RS256 signature against the team's certificates, its issuer (the team
domain), its audience (the application's AUD tag), and its expiry. It answers
401 without a token and 403 with a bad one.

Configure the check with `--access-team` and `--access-aud`, or their
environment variables. The server refuses to start without them unless given
`--auth none`. That serves only requests addressed to a loopback name, and only
on a loopback address. Keep `--auth none` for local testing: a tunnel to a
loopback port that keeps the `Host` header is still refused, but one that
rewrites it to `localhost` is not.

## Request Log

Every request except the health check is logged twice once it is answered: as a
line on standard error, and as a JSON record appended to the request log.

```text
taskgo mcp: request transport=http http=POST method=tools/call tool=get_task outcome=ok status=200 ms=41 commit=1a2b3c4d5e6f agent=example-client/1.0
taskgo mcp: request transport=http http=POST outcome=refused status=403 ms=1 reason="Access token expired" agent=example-client/1.0
```

Fields appear in this order, and only when they apply:

- `transport`: `http` or `stdio`;
- `http`: the HTTP verb;
- `method`, `tool`: the JSON-RPC method and the tool called;
- `outcome`: `ok`, `tool-error` (the client got an error result), `rpc-error`
  (an unknown method, a parse error, a malformed message), `refused` (an HTTP
  refusal: authentication, a wrong host or path, a request too large), or
  `error` (the reply could not be sent);
- `status`, `ms`: the HTTP status and the duration;
- `commit`: the commit a tool call read or wrote;
- `fetch`, `stale`: a fetch that failed during the request, and whether a read
  was served a stale head because of it;
- `reason`: why, for any outcome but `ok`;
- `agent`: the client's `User-Agent`.

A refused request's body is never read, so it has no method. Client-supplied
values that are not plain tokens are quoted as JSON and truncated, so they
cannot break or forge a line.

The record has the same fields, plus:

- `ts`: when the request came, in UTC with milliseconds;
- `args`: a tool call's identifying arguments (project, task, path, search,
  `request_id`, and each `apply_changes` change's operation and target), each
  shortened to one line of 60 characters;
- `bytes`: the size of a successful tool call's result;
- `caller`: an opaque key for the caller, a hash of the Access token's
  identifying claims, or of a stdio server's process; HTTP with `--auth none`
  has none;
- `version`: the server's version.

```json
{"ts":"2026-10-13T08:22:11.547Z","transport":"http","http":"POST","method":"tools/call","tool":"list_tasks","args":{"project":"proj","state":"ready"},"outcome":"ok","status":200,"ms":33,"bytes":1597,"commit":"af97eff1c9d2","agent":"Claude-User","caller":"3f9c0a1b2d","version":"0.16.0"}
```

The log is written over either transport, so stdio servers keep one too. At 8
MiB the file is renamed `FILE.1`, and older ones move up to `FILE.4`, which is
dropped: at most 40 MiB. Several servers can share a file; each append and
rotation locks it. Logging never fails a request: if the file cannot be written,
the server says so once on standard error and keeps logging lines there.

Lines and records name requests, never their content: no task text, file
content, edits, or tokens. A record's `args` can still hold a short private
detail, such as a project name, a path, or a search pattern, so keep the log on
the server's host. The first request with each kind of valid Access token also
logs the names, not the values, of its claims.

**Reading the log.** `mcp logs` (in the `agent-config` skill) reads these
records; its format reference is `skills/agent-config/references/mcp-logs.md`.
The records are JSON lines, so `jq` reads them too:

```sh
mcp logs --summary --since 1d --server taskgo
jq -r 'select(.outcome != "ok") | [.ts, .agent, .tool, .reason] | @tsv' ~/.local/state/taskgo/mcp.jsonl
```

## Caller Surface

The server describes itself to callers, and that is the source of truth. Read
these in the code rather than restating them here:

- `mcp_instructions()` in `scripts/taskgo-mcp`: the `initialize` instructions,
  which carry the workflow, the write rules, and data care. Some clients cache
  the tool list for weeks, so rules that matter also live in the instructions
  and in error messages.
- Each tool's title, description, schema, and annotations, in
  `scripts/taskgo-mcp`.
- The `handoff` payload's `guide`: `MCP_GUIDE` in `scripts/taskgo`.
- Error messages, written so a caller can fix its call in one retry. Tool
  failures return `isError: true` with the message in both `content[0].text` and
  `structuredContent.error.message`.

The tools mirror CLI commands (`get_task` and `taskgo status TASK_ID --json`,
`handoff` and `taskgo handoff --json`, `apply_changes` and `taskgo apply`), and
`tests/compare-cli` checks that they agree. Writes take a change set; see
[change-sets.md](change-sets.md).

## Testing

The test suite runs the server checks: `test-taskgo-mcp`, which runs
`compare-cli` and `protocol-check` on a synthetic tracker and `auth-check`, and
`test-taskgo-mcp-write`, which checks writes against a local bare repository
with and without the fetch cache. From the repository root:

```sh
prove skills/taskgo/tests/test-taskgo-mcp skills/taskgo/tests/test-taskgo-mcp-write
```

To try a server by hand, from the skill directory:

```sh
tests/make-synthetic /tmp/synth
scripts/taskgo --root /tmp/synth mcp --no-fetch --auth none &
tests/compare-cli http://127.0.0.1:8789/mcp /tmp/synth   # server versus CLI
```

`compare-cli` prints only check names and counts, never file contents, so it is
safe to run against a private tracker.

## Data Care

Everything the server returns is private tracker content. The host running the
server holds a clone of the control repository, so the same care applies to the
host.

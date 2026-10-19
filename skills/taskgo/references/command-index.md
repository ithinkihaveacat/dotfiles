# Command Index

<!-- markdownlint-disable MD013 -->

## Contents

- [Help](#help)
- [create](#create)
- [update](#update)
- [apply](#apply)
- [edit](#edit)
- [list](#list)
- [info](#info)
- [skills](#skills)
- [status](#status)
- [handoff](#handoff)
- [sync](#sync)
- [check](#check)
- [doctor](#doctor)
- [fix](#fix)
- [history](#history)
- [read](#read)
- [search](#search)
- [checkpoint](#checkpoint)
- [commit](#commit)
- [schema](#schema)

## Help

The block below is `taskgo --help`, kept in sync by `command-index-format`.

<!-- generated: ../scripts/taskgo --help -->

```text
Usage: taskgo COMMAND [OPTIONS]

Maintain a private Git-backed personal project/task control repo.

Commands:
  id                               Allocate a unique task ID
  root                             Print the active control repository root
  create PROJECT TITLE [OPTIONS]   Create a new task (--slug, --problem, etc.)
  update TASK_ID [OPTIONS]         Update task fields, status, or headings
  apply CHANGES.json [--dry-run]   Apply a change set to the working tree
  edit PATH [OPTIONS]              Replace exact text in a file (--old, --new)
  list [PROJECT] [OPTIONS]         List tasks (--state ready for the frontier)
  info PROJECT [--json]            Show project metadata from README.md frontmatter
  skills PROJECT [--json]          Print the skills a project declares
  status [PROJECT|TASK_ID]         Show a task's or project's status
  handoff PROJECT|TASK_ID          Print agent instructions for a project or task
  sync [PROJECT]                   Update STATUS.md snapshot
  check [PROJECT] [--json]         Sweep wait_for gates and date horizons
  doctor [PROJECT]                 Run mechanical checks (read-only)
  fix [PROJECT] [OPTIONS]          Auto-heal IDs, statuses, and snapshots
  history PATH_OR_TASK_ID [FIELD]  Show frontmatter history
  read PATH [OPTIONS]              Print lines of a file (--start-line, --end-line)
  search [OPTIONS] GREP_ARGS...    Search file contents with git grep (--at, --json)
  checkpoint TASK_ID SUBJECT [...] Commit an authorized tracker checkpoint (--all)
  commit SUBJECT [OPTIONS]         Commit a logical transition
  schema [--json]                  Show the task, decision, and STATUS schema
  mcp [OPTIONS]                    Serve the tracker to MCP clients

Options:
  -R, --root DIR  Operate on the control repository at DIR instead of the
                  default (~/.projects); overrides TASKGO_ROOT. Must appear
                  before COMMAND.
  --offline       Skip remote Git fetch and push (same as AGENT_OFFLINE=1)
  --help, -h      Display this help message and exit

Environment:
  Root: ~/.projects
  Source: default

Examples:
  taskgo id
  taskgo create my-project "Diagnose intermittent disconnects" --slug disconnects
  taskgo create my-project "Add cache layer" --slug cache-layer --problem "High latency"
  taskgo update TASK-3A91F --status in-progress --sketch "Use in-memory dict"
  taskgo handoff TASK-3A91F
  taskgo sync my-project
  taskgo fix my-project
  taskgo checkpoint TASK-3A91F "project: start diagnosis" --all
```

<!-- /generated -->

## create

<!-- generated: ../scripts/taskgo create --help -->

```text
Usage: taskgo create [-h] [--slug SLUG] [--status STATUS] [--problem PROBLEM]
                     [--cost COST] [--goal GOAL] [--criteria CRITERIA]
                     [--sketch SKETCH] [--constraints CONSTRAINTS]
                     [--outcome OUTCOME] [--findings FINDINGS]
                     [--next NEXT_STEPS] [--conv CONV] [--wait-for GATE]
                     [--due YYYY-MM-DD] [--stale-after YYYY-MM-DD]
                     [--add-blocked-by TASK_ID] [--add-wait-for GATE]
                     [--add-conversation URI] [--no-commit] [--dry-run]
                     PROJECT TITLE

Create a new task in PROJECT.

Arguments:
  PROJECT               Project identifier
  TITLE                 Task title

Options:
  -h, --help            Display this help message and exit
  --slug SLUG           Filename mnemonic, max 32 chars (default: derived from
                        TITLE)
  --status, -s STATUS   Initial task state (default: todo)
  --problem, -p PROBLEM
                        Problem description
  --cost COST           Consequences of leaving the task undone
  --goal, -g GOAL       Goal description
  --criteria, -c CRITERIA
                        Observable end condition
  --sketch SKETCH       Implementation sketch
  --constraints CONSTRAINTS
                        Constraints
  --outcome OUTCOME     Outcome description
  --findings FINDINGS   Findings
  --next NEXT_STEPS     Next steps
  --conv, -C, --conversation CONV
                        Active conversation or session ID
  --wait-for GATE       External or temporal gate (YYYY-MM-DD, b/..., cl/...,
                        gh:..., @handle)
  --due YYYY-MM-DD      Committed completion deadline (YYYY-MM-DD)
  --stale-after YYYY-MM-DD
                        Relevance cutoff date (YYYY-MM-DD)
  --add-blocked-by TASK_ID
                        Add to blocked_by (repeatable; repeats are no-ops)
  --add-wait-for GATE   Add to wait_for (repeatable; repeats are no-ops)
  --add-conversation URI
                        Add to conversations (repeatable; repeats are no-ops)
  --no-commit           Do not commit created task
  --dry-run             Preview allocation without modifying files

Examples:
  taskgo create my-project "Diagnose intermittent disconnects" --slug disconnects
  taskgo create my-project "Add a read-through cache layer in front of the resolver" \
    --slug cache-layer --problem "High latency" --goal "Sub-10ms"
  taskgo create --status in-progress my-project "Initial implementation" --slug initial-impl

TITLE is prose for humans (it becomes the H1 and appears in STATUS.md); SLUG is
the filename mnemonic. A slug derived from a long TITLE keeps the leading words,
which are rarely the distinguishing ones, so pass --slug whenever TITLE is longer
than a few words.
```

<!-- /generated -->

## update

<!-- generated: ../scripts/taskgo update --help -->

```text
Usage: taskgo update [-h] [--status STATUS] [--expect-status STATE]
                     [--title TITLE] [--slug SLUG] [--problem PROBLEM]
                     [--cost COST] [--goal GOAL] [--criteria CRITERIA]
                     [--sketch SKETCH] [--constraints CONSTRAINTS]
                     [--outcome OUTCOME] [--findings FINDINGS]
                     [--next NEXT_STEPS] [--conv CONV] [--wait-for GATE]
                     [--due YYYY-MM-DD] [--stale-after YYYY-MM-DD]
                     [--add-blocked-by TASK_ID] [--remove-blocked-by TASK_ID]
                     [--add-wait-for GATE] [--remove-wait-for GATE]
                     [--add-conversation URI] [--remove-conversation URI]
                     TASK_ID

Update task fields, status, or headings.

Arguments:
  TASK_ID               Task ID or relative path

Options:
  -h, --help            Display this help message and exit
  --status, -s STATUS   New task state
  --expect-status STATE
                        Refuse the update unless the current state is STATE
  --title, -t TITLE     New task title
  --slug SLUG           Rename the task file's slug, max 32 chars
  --problem, -p PROBLEM
                        Problem description
  --cost COST           Consequences of leaving the task undone
  --goal, -g GOAL       Goal description
  --criteria, -c CRITERIA
                        Observable end condition
  --sketch SKETCH       Implementation sketch
  --constraints CONSTRAINTS
                        Constraints
  --outcome OUTCOME     Outcome description
  --findings FINDINGS   Findings
  --next NEXT_STEPS     Next steps
  --conv, -C, --conversation CONV
                        Active conversation or session ID
  --wait-for GATE       External or temporal gate (YYYY-MM-DD, b/..., cl/...,
                        gh:..., @handle)
  --due YYYY-MM-DD      Committed completion deadline (YYYY-MM-DD)
  --stale-after YYYY-MM-DD
                        Relevance cutoff date (YYYY-MM-DD)
  --add-blocked-by TASK_ID
                        Add to blocked_by (repeatable; repeats are no-ops)
  --remove-blocked-by TASK_ID
                        Remove from blocked_by (repeatable; absent values are
                        no-ops)
  --add-wait-for GATE   Add to wait_for (repeatable; repeats are no-ops)
  --remove-wait-for GATE
                        Remove from wait_for (repeatable; absent values are
                        no-ops)
  --add-conversation URI
                        Add to conversations (repeatable; repeats are no-ops)
  --remove-conversation URI
                        Remove from conversations (repeatable; absent values
                        are no-ops)

Examples:
  taskgo update TASK-3A91F --status in-progress
  taskgo update TASK-3A91F --expect-status todo --status in-progress
  taskgo update TASK-3A91F --add-blocked-by TASK-1627D --remove-wait-for 2026-10-13
  taskgo update TASK-3A91F --sketch "Use in-memory dict" --findings "Latency reduced by 40%"
```

<!-- /generated -->

## apply

<!-- generated: ../scripts/taskgo apply --help -->

```text
Usage: taskgo apply [-h] [--dry-run] CHANGES.json

Apply a change set to the working tree: the typed operations the MCP
server's writes use (create, set, add, remove, replace_section,
write_file, delete_file, and edit_file), all or none. Preconditions
are checked as each change applies; the state after the whole set is
validated; the affected projects' STATUS.md blocks are regenerated.
Nothing is committed. Prints the created records and changed files
as JSON.

Arguments:
  CHANGES.json  Change set file, or - for standard input

Options:
  -h, --help    Display this help message and exit
  --dry-run     Print the diff the change set would make, and write nothing

Example CHANGES.json:
  {"changes": [
    {"op": "create", "kind": "task", "project": "my-project", "ref": "a",
     "sections": {"title": "Add a cache", "Goal": "Sub-10ms reads"}},
    {"op": "add", "record": "TASK-3A91F", "field": "blocked_by",
     "values": ["$a"]},
    {"op": "set", "record": "TASK-3A91F", "field": "status",
     "value": "blocked", "expected": "todo"}
  ]}

The change-set format is in references/model.md (Change Sets).
```

<!-- /generated -->

## edit

<!-- generated: ../scripts/taskgo edit --help -->

```text
Usage: taskgo edit [-h] [--old TEXT] [--new TEXT] [--old-file FILE]
                   [--new-file FILE] [--replace-all] [--expected-blob SHA]
                   [--dry-run] [--json]
                   PATH

Replace exact text in one file of the working tree, as the MCP
server's edit_file tool does: a change set of one edit_file change.
OLD must occur exactly once unless --replace-all is given. Bytes
match verbatim; only when nothing matches in a CRLF file are both
texts retried with CRLF line endings. Assets are written as
replaced and keep their mode; tasks, decisions, and STATUS.md are
checked and formatted, and the affected STATUS.md blocks are
regenerated. Files up to 256 KiB. Nothing is committed.

Arguments:
  PATH                 Repository-relative path

Options:
  -h, --help           Display this help message and exit
  --old TEXT           Text to replace
  --new TEXT           Replacement text
  --old-file FILE      Read the text to replace from FILE (- for standard
                       input)
  --new-file FILE      Read the replacement from FILE (- for standard input)
  --replace-all        Replace every occurrence, not exactly one
  --expected-blob SHA  Refuse unless the file's Git blob SHA is SHA
  --dry-run            Print the diff the edit would make, and write nothing
  --json, -j           Print the change-set result as JSON

Examples:
  taskgo edit proj/PLAN.md --old 'Phase 1' --new 'Phase 2'
  taskgo edit proj/scripts/run.py --old-file old.txt --new-file new.txt
  taskgo edit proj/decisions/001-x.md --old 'teh' --new 'the' --replace-all
```

<!-- /generated -->

## list

<!-- generated: ../scripts/taskgo list --help -->

```text
Usage: taskgo list [-h] [--state STATE] [--json] [PROJECT]

List tasks in the repository or a specific project.

Arguments:
  PROJECT               Optional project name filter

Options:
  -h, --help            Display this help message and exit
  --state, --status, -s STATE
                        Filter tasks by state (e.g. in-progress, done, or
                        ready)
  --json, -j            Output machine-readable JSON
```

<!-- /generated -->

## info

<!-- generated: ../scripts/taskgo info --help -->

```text
Usage: taskgo info [-h] [--json] PROJECT

Show project metadata from README.md YAML frontmatter.

Arguments:
  PROJECT     Target project name

Options:
  -h, --help  Display this help message and exit
  --json, -j  Output machine-readable JSON
```

<!-- /generated -->

## skills

<!-- generated: ../scripts/taskgo skills --help -->

```text
Usage: taskgo skills [-h] [--json] PROJECT

Print the agent skills a project's README.md frontmatter declares, one per line, for a skill manager to activate.

Arguments:
  PROJECT     Target project name

Options:
  -h, --help  Display this help message and exit
  --json, -j  Output a JSON array

Examples:
  taskgo skills alpha | skill --scope session add -
  taskgo skills alpha --json
```

<!-- /generated -->

## status

<!-- generated: ../scripts/taskgo status --help -->

```text
Usage: taskgo status [-h] [--at REV] [--json] [PROJECT|TASK_ID]

Show a task's or a project's status, or a one-line summary of each project.

Arguments:
  PROJECT|TASK_ID  Project or task; omit for every project

Options:
  -h, --help       Display this help message and exit
  --at REV         Read commit REV instead of the working tree
  --json, -j       Output machine-readable JSON

Examples:
  taskgo status
  taskgo status alpha
  taskgo status TASK-3A91F
  taskgo status TASK-3A91F --at HEAD --json

For a project, prints its STATUS.md. For a task, prints its state, with
what the tracker derives (ready, or the blockers and gates holding it), then
the record; --json prints the record as the MCP get_task tool returns it.
```

<!-- /generated -->

## handoff

<!-- generated: ../scripts/taskgo handoff --help -->

```text
Usage: taskgo handoff [--help] [--at REV] [--json] PROJECT|TASK_ID

Print instructions handing a project or a selected task to an agent.

Arguments:
  PROJECT|TASK_ID  Project or task to assign to the agent

Options:
  --help, -h       Display this help message and exit
  --at REV         Read commit REV instead of the working tree
  --json, -j       Output the full payload as JSON

Examples:
  taskgo handoff TASK-3A91F
  taskgo handoff alpha
  taskgo handover TASK-3A91F --json
  taskgo --root ~/projects handoff TASK-3A91F

The note is generated from the working tree (or commit REV), and ends with
the project's skills when its README declares any. Findings about tracker
readiness, and uncommitted changes an agent reading through MCP cannot see,
are written to stderr. --json prints the
note, the files it names inlined verbatim, the skills list, and the project's
in-progress, blocked, and ready tasks, as the MCP handoff tool returns them.
```

<!-- /generated -->

## sync

<!-- generated: ../scripts/taskgo sync --help -->

```text
Usage: taskgo sync [-h] [PROJECT]

Update STATUS.md snapshot for a project or the workspace.

Arguments:
  PROJECT     Optional target project

Options:
  -h, --help  Display this help message and exit
```

<!-- /generated -->

## check

<!-- generated: ../scripts/taskgo check --help -->

```text
Usage: taskgo check [--help] [--json] [PROJECT]

Evaluate wait_for gates, due deadlines, and stale_after cutoffs.

Arguments:
  PROJECT     Optional target project

Options:
  --help, -h  Display this help message and exit
  --json, -j  Output machine-readable JSON

Examples:
  taskgo check
  taskgo check my-project --json

Scans open tasks declaring wait_for, due, or stale_after against today and each
task file's Git commit watermark, emitting nothing when no tasks trigger.
```

<!-- /generated -->

## doctor

<!-- generated: ../scripts/taskgo doctor --help -->

```text
Usage: taskgo doctor [-h] [PROJECT]

Run mechanical health checks across the workspace or a project.

Arguments:
  PROJECT     Optional target project

Options:
  -h, --help  Display this help message and exit
```

<!-- /generated -->

## fix

<!-- generated: ../scripts/taskgo fix --help -->

```text
Usage: taskgo fix [-h] [--dry-run] [--no-commit] [PROJECT]

Auto-heal IDs, statuses, and snapshot drift.

Arguments:
  PROJECT      Optional target project

Options:
  -h, --help   Display this help message and exit
  --dry-run    Preview repairs without modifying files
  --no-commit  Apply repairs on disk without committing
```

<!-- /generated -->

## history

<!-- generated: ../scripts/taskgo history --help -->

```text
Usage: taskgo history [-h] PATH_OR_TASK_ID [FIELD]

Show frontmatter field history across git revisions.

Arguments:
  PATH_OR_TASK_ID  Task ID or relative path
  FIELD            Frontmatter field to track (default: status)

Options:
  -h, --help       Display this help message and exit
```

<!-- /generated -->

## read

<!-- generated: ../scripts/taskgo read --help -->

```text
Usage: taskgo read [-h] [--start-line N] [--end-line N] [--at REV] [--json]
                   [-n]
                   PATH

Print lines START..END of a UTF-8 file in the control repository, from the working tree or from commit REV, as the MCP server's read_file tool does. Lines are 1-indexed and inclusive and end at newline. At most 256 KiB is printed, cut after a whole line; when the output is truncated, a note on stderr names the line to continue from. Output is the file's bytes unless --line-numbers prefixes each line with 'N: '.

Arguments:
  PATH                Repository-relative path

Options:
  -h, --help          Display this help message and exit
  --start-line N      First line (default 1)
  --end-line N        Last line (default: the last)
  --at REV            Read commit REV instead of the working tree
  --json, -j          Print path, blob, size, line range, truncated, and
                      content as JSON
  -n, --line-numbers  Prefix each line with its number and ': ' (as in '7:
                      text')

Examples:
  taskgo read proj/PLAN.md
  taskgo read proj/logs/logcat.txt --start-line 2001 --end-line 2400
  taskgo read proj/PLAN.md --at HEAD~3 --json
  taskgo read -n proj/PLAN.md --start-line 40 --end-line 60
```

<!-- /generated -->

## search

<!-- generated: ../scripts/taskgo search --help -->

```text
Usage: taskgo search [--at REV] [--json] GREP_ARGS... [-- PATHS...]

Search tracked files in the control repository with git grep, in the working tree or in commit REV, as the MCP server's search_files tool does. GREP_ARGS are git grep arguments: one bare pattern, or patterns given with -e, and these Options: -i -w -v -E -G -F -P -n -I -l -L -c -o -W -p, -A/-B/-C N, -m N, --max-depth N, --and, --or, --not, ( ), --all-match, and their long forms. Other options, abbreviations, and further bare arguments are refused. Pathspecs follow '--'. Output is git grep's, with paths relative to the repository root, lines cut at 1024 bytes, and at most 64 KiB in all. Exits 0 on a match, 1 on none, and 2 on an error; git is stopped after 30 s.

Arguments:
  GREP_ARGS   git grep pattern and options, then optionally -- PATHS

options:
  -h, --help  Display this help message and exit
  --at REV    Search commit REV instead of the working tree
  --json, -j  Print output, files, and truncated as JSON

Examples:
  taskgo search TASK-084C7
  taskgo search -i -C2 'partner name' -- meta/ '*.md'
  taskgo search -l -e b/123456 -e cl/123456
  taskgo search -e TODO --and --not -e done --at HEAD~3 --json
```

<!-- /generated -->

## checkpoint

<!-- generated: ../scripts/taskgo checkpoint --help -->

```text
Usage: taskgo checkpoint [-h] [--all] [--path PATHS] [--body BODY]
                         [--ref REFS] [--conv CONV]
                         TASK_ID SUBJECT

Commit an authorized tracker checkpoint for TASK_ID. Nonconforming subjects are rewritten as 'chore(<project>): <subject>' (truncated to 50 characters). Staged paths must belong to TASK_ID's project; changes spanning projects (such as moving a task) need a plain 'git commit'; see references/workflows.md.

Arguments:
  TASK_ID               Target task ID
  SUBJECT               Conventional Commits subject line (rewritten when
                        nonconforming)

Options:
  -h, --help            Display this help message and exit
  --all, -a             Stage all modified/untracked project files
  --path, -p PATHS      Explicit project files to stage
  --body, -b BODY       Plain-text commit body (hard-wrapped to 72 columns)
  --ref, -r REFS        External references (e.g. artifact@sha)
  --conv, -C, --conversation CONV
                        Active conversation or session ID

Examples:
  taskgo checkpoint TASK-3A91F "chore(proj): start diagnosis" --all
  taskgo checkpoint TASK-3A91F "docs(proj): update task" --path proj/tasks/TASK-3A91F-slug.md
```

<!-- /generated -->

## commit

<!-- generated: ../scripts/taskgo commit --help -->

```text
Usage: taskgo commit [-h] [--body BODY] [--ref REFS] [--conv CONV] SUBJECT

Commit a logical transition with automatic project status synchronization. Staged changes must touch at most one project; changes spanning projects (such as moving a task) need a plain 'git commit'; see references/workflows.md.

Arguments:
  SUBJECT               Conventional Commits subject line (rewritten when
                        nonconforming)

Options:
  -h, --help            Display this help message and exit
  --body, -b BODY       Plain-text commit body (hard-wrapped to 72 columns)
  --ref, -r REFS        External references (e.g. artifact@sha)
  --conv, -C, --conversation CONV
                        Active conversation or session ID
```

<!-- /generated -->

## schema

<!-- generated: ../scripts/taskgo schema --help -->

```text
Usage: taskgo schema [-h] [--json]

Show the record schema: the fields and sections of tasks, decisions,
and STATUS.md. Validation, doctor, and the create/update set options
read it; --json is the conformance form for other implementations.

Options:
  -h, --help  Display this help message and exit
  --json, -j  Output as JSON
```

<!-- /generated -->

## mcp

<!-- generated: ../scripts/taskgo mcp --help -->

```text
Usage: taskgo mcp [-h] [--host HOST] [--port PORT] [--path PATH]
                  [--remote REMOTE] [--branch BRANCH] [--no-fetch | --local]
                  [--fetch-ttl SECS] [--auth {access,none}]
                  [--access-team DOMAIN] [--access-aud TAG] [--stdio]
                  [--log FILE]

Serve the control repository's committed state to MCP clients,
and accept writes from them, over Streamable HTTP (stateless, one
JSON response per message) or, with --stdio, to one local client.

Each tool call fetches BRANCH from REMOTE, resolves it once, and
reads only that commit; it never touches the working tree. A read
within --fetch-ttl seconds of the last fetch, or of the server's
own push, uses that head instead, so it may miss a push from
elsewhere for that long; a read whose fetch fails is served the
last fetched head, marked stale in as_of. Each write commits one
change set on the head and pushes it to REMOTE without force,
retrying on a moved head a few times; with a cached head, the
push alone checks that the head has not moved. Writes need the
commit-authority marker in AGENTS.md, a commit identity
(user.name and user.email), and a remote: with --no-fetch the
server only reads. With --local, for a checkout on this machine,
there is no remote: reads see the local BRANCH as it is, and a
write moves it (only if it has not moved since the write read
it) and refreshes the checked-out files it touched, so it needs
BRANCH checked out and those files unchanged in the checkout.
Cloudflare Access, with Managed OAuth, is meant to sit in front
of the server, and the server checks the Access JWT of every
request (issuer, audience, signature, expiry). --auth none skips
the check and serves only requests addressed to a loopback name.

Each request is logged as a line on stderr and as a JSON record
appended to the request log (rotated at 8 MiB, keeping 4 old
files); a record keeps a tool call's short identifying arguments
(project, task, path, search), never text such as titles, bodies,
or file content. 'taskgo requests' summarises the log.
Over HTTP, GET /logs is a live page of the latest requests, behind
the same check as the endpoint; GET /up is an unauthenticated
health check.

Environment:
  TASKGO_MCP_ACCESS_TEAM  Default for --access-team
  TASKGO_MCP_ACCESS_AUD   Default for --access-aud
  TASKGO_MCP_LOG          Default for --log

Options:
  -h, --help            Display this help message and exit
  --host HOST           Address to listen on (default 127.0.0.1)
  --port PORT           Port to listen on (default 8789)
  --path PATH           Endpoint path (default /mcp)
  --remote REMOTE       Remote to fetch from (default origin)
  --branch BRANCH       Branch to serve (default main)
  --no-fetch            Serve the local BRANCH without fetching; no writes
  --local               Serve the local BRANCH without a remote: writes move
                        it and refresh the checkout
  --fetch-ttl SECS      Seconds a fetched or pushed head serves reads (default
                        5; 0 fetches for every call)
  --auth {access,none}  Check Cloudflare Access JWTs (default) or nothing
                        (loopback only)
  --access-team DOMAIN  Access team domain, such as
                        example.cloudflareaccess.com
  --access-aud TAG      Access application audience (AUD) tag
  --stdio               Serve one client on stdin and stdout instead (no
                        authentication)
  --log FILE            Request log to append to (default
                        $XDG_STATE_HOME/taskgo/mcp.jsonl, or
                        ~/.local/state/taskgo/mcp.jsonl)
```

<!-- /generated -->

## requests

<!-- generated: ../scripts/taskgo requests --help -->

```text
Usage: taskgo requests [-h] [--log FILE] [--days N] [--gap SECS] [--json]

Summarise the request log of 'taskgo mcp': requests by outcome,
then requests, failures, latency, and result size per client and
per tool, then the commonest runs of two or three tool calls in
one caller's chains. A chain is a caller's tool calls, each no
more than --gap seconds after the one before.

Environment:
  TASKGO_MCP_LOG  Default for --log

Options:
  -h, --help  Display this help message and exit
  --log FILE  Request log to read, with its rotated files (default as for mcp)
  --days N    Read the last N days of records (default 7)
  --gap SECS  Longest pause within a chain (default 120)
  --json, -j  Output as JSON

Examples:
  taskgo requests
  taskgo requests --days 1 --gap 60
  taskgo requests --log /data/log/mcp.jsonl --json | jq '.sequences[:3]'
```

<!-- /generated -->

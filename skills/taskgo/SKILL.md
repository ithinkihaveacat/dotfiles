---
name: taskgo
description: >-
  Maintains a private Git-backed personal project and task control repository
  using concise current Markdown, derived Git history, ADRs, and status synchronization.
  Use when tracking tasks, updating project status (STATUS.md), managing ADRs,
  synchronizing tracker state, handing tasks to agents, or generating
  human-facing activity reports (weekly/monthly/quarterly).
compatibility: Requires Python 3.11+ (via uv) and git.
---

# taskgo

taskgo manages a private **control repository** spanning multiple projects.
Humans read current Markdown; agents edit it, operate Git, reconstruct history,
and generate summaries.

## Tool Execution

`taskgo` is bundled in `scripts/taskgo` within this skill directory. Commands
operate on a fixed control repository root, resolved in this order:

1. `--root DIR` / `-R DIR` (must appear before the command)
1. the `TASKGO_ROOT` environment variable
1. the default `~/.projects`

Execution resolution never depends on the current working directory. Run
`taskgo doctor` to see the resolved root. To execute the tool:

1. **Optimal (`$PATH`):** `taskgo <command>`
1. **Dynamic anchor:** `<skill-dir>/scripts/taskgo <command>`

## Core Invariants

1. **Current Truth:** `HEAD` describes current belief. Git owns administrative
   history. Avoid accumulating historical journals in Markdown.
1. **Data Segregation:** Private tracker information must not implicitly flow
   into linked public/shared artifacts. `Conversation:` trailers and session
   URLs belong strictly in the control repository metadata. Artifact path
   references prefer `$HOME`-relative form (`~/...`).
1. **Link Portability:** Internal links must be standard relative Markdown (no
   `file://`). External references must be network URLs (`https://`) or unlinked
   monospace text.
1. **STATUS.md:** This is the self-contained projection of current operational
   state. Reading it directly answers status and next steps.
1. **Commit Authority:** The `<!-- taskgo:allow-local-commits -->` marker in the
   control repo's `AGENTS.md` grants standing authority for guarded local
   checkpoint commits (`create`, `checkpoint`, `commit`, `fix`). Restructuring
   the guarded commands cannot express (such as moving a task between projects)
   may use a plain `git commit`; ask first, or at least report it afterwards.
   See [Commit Authority](references/workflows.md#commit-authority). Never
   rewrite artifact history.
1. **No Administrative Metadata:** Do not invent metadata fields like `created`,
   `updated`, or `blocked_since` in YAML frontmatter. Git owns administrative
   history. Do not duplicate `Project:`, `Task:`, or `Event:` trailers.

## Tasks

IDs are globally unique `TASK-XXXXX` (five hex digits). Task files are
`tasks/TASK-XXXXX-<slug>.md`. Pass `--slug` (max 32 chars) when creating tasks
if the title is long.

Preferred states: `todo`, `in-progress`, `blocked`, `done`, `cancelled`.

### Dependencies & Scheduling

A task may declare internal task graph edges (`blocked_by`) as well as external
or temporal scheduling fields (`wait_for`, `due`, and `stale_after`):

```yaml
blocked_by: [TASK-1627D]
wait_for: [b/123456, 2026-10-13]
due: 2026-10-15
stale_after: 2026-11-01
```

- **`blocked_by`** — Internal `TASK-XXXXX` graph edges only. Record the edge on
  the task that is *held*, never on the blocker; remove resolved edges from open
  tasks when `taskgo doctor` reports them (or re-plan if cancelled).
- **`wait_for`** — External or temporal gates keeping a task off the ready
  frontier: ISO cool-down dates (`YYYY-MM-DD`, resolved once `today >= date`),
  issue/CL URIs (`b/...`, `cl/...`, `gh:owner/repo#num`), or human handles
  (`@reviewer`).
- **`due`** — Committed completion deadline (`YYYY-MM-DD`). `taskgo doctor`
  emits `[FAIL]` when overdue (`due < today`) and `[INFO]` within 48 hours;
  `taskgo list --state ready` sorts approaching `due` dates first.
- **`stale_after`** — Relevance cutoff (`YYYY-MM-DD`) after which
  `taskgo doctor` emits `[WARN]` prompting re-scoping or cancellation.

Dates are floating calendar days with no zone. Only "today" depends on a zone:
`TASKGO_TODAY=YYYY-MM-DD` wins, then an IANA `timezone:` (such as
`Europe/London`) in the root `README.md` frontmatter, then the machine's local
date. Set the repository zone so UTC machines (cloud sessions, servers) agree
with local ones; `taskgo doctor` fails on an unknown zone, and taskgo then uses
the local date.

Edit these lists with `--add-blocked-by`, `--add-wait-for`, and
`--add-conversation` on `create` or `update`, and the matching `--remove-*`
options on `update`; repeats and absent values are no-ops. `update` refuses an
added blocker that is unknown, the task itself, or closes a `blocked_by` cycle.
`taskgo schema` lists every field, its value type, and each record kind's
sections; `doctor` checks frontmatter against it.

`status: blocked` is allowed without warning when either `blocked_by` or
`wait_for` has unresolved entries. Run `taskgo check [PROJECT] [--json]` to
sweep open tasks against `today` and their task-scoped Git commit watermark,
emitting only tasks with elapsed dates, approaching/overdue deadlines, stale
cutoffs, or upstream URI activity/resolution.

### Planning & In-Progress Task Template

```markdown
---
id: TASK-3A91F
status: todo
conversations:
  - <agent>://<conversation-id>
---

# Title as imperative verb phrase

*(Tip: Front-load external stakeholder or impact context)*

**Problem:** (optional) Current behavior and why it is a problem.
**Cost:** (optional) Consequence of leaving the task undone and who absorbs it.
**Goal:** (required) What should be true once done (requirements).
**Criteria:** (required where definable) Observable end condition.
**Sketch:** (optional) Early thinking/pointers.
**Constraints:** (optional) Boundaries on the solution.
```

Use Cost when it adds useful prioritization context. Problem may appear without
Cost; the rationale may already be clear in Problem or Goal.

### Completed Task Template

```markdown
---
id: TASK-3A91F
status: done
conversations:
  - <agent>://<conversation-id>
---

# Title as imperative verb phrase

**Problem:** (kept) As planned.
**Cost:** (kept) As planned.
**Goal:** (kept) As planned.
**Criteria:** (kept) As planned.

## Outcome
Verdict against each criterion, then what shipped, external canonical web URLs, quantitative deltas, and Cost updates.

## Findings
Key technical discoveries, trade-offs, reproduction steps, downstream momentum.

## Next
Immediate follow-up actions.
```

On completion, keep Problem, Cost, Goal, and Criteria as written, so the record
still states what the task set out to do. Replace Sketch and Constraints with
Outcome and Findings. Marking a task done needs Outcome text:
`taskgo update --status done` and `taskgo create --status done` refuse without
`--outcome`, as `apply` and the MCP server do. `taskgo doctor` reports a done
task without Outcome text as `[INFO]`; older records predate the rule and are
repaired when next completed, not migrated in bulk.

## Project README & Decisions

See **[Where Knowledge Lives](references/model.md#where-knowledge-lives)** for
which file, repository, or skill owns each kind of fact.

- **Project README (`<project>/README.md`):** The stable, private description of
  the project, changing over months: **identity** (purpose, scope), **map**
  (where everything lives, and which source is canonical), and **standing
  rules**. Unlike an artifact repository's README, it does not describe the
  code. See [Project README](references/model.md#project-readme) for the
  placement test and skeleton. Optional YAML frontmatter holds project-level
  configuration, such as the agent `skills` to work on the project, named as the
  `skill` CLI resolves them (a catalog short name, optionally `namespace:name`):
  ```markdown
  ---
  skills:
    - coding-standards
    - local:notes
  ---

  # Project Name
  ```
  `taskgo skills <project>` prints the list; `taskgo handoff` carries it in its
  note; `taskgo doctor` warns about a name the catalog does not have.
- **Decisions:** Lightweight Nygard-style ADRs (`decisions/*.md`) for private or
  cross-artifact decisions. Newer ADRs record `supersedes: [<old-adr>]` in YAML
  frontmatter to retire older ADRs; edit an accepted ADR in place only for
  typos, status updates, broken links, or implementation notes.
- **STATUS.md:** The self-contained operational projection.
  - `## Summary`: Human/agent prose for current situation and active session
    citation (`[<conversation-id>](<agent>://<conversation-id>)`). Rewrite it;
    never append a paragraph per session.
  - `<!-- taskgo:begin/end -->`: Mechanically maintained via `taskgo sync`
    (projects `In progress`, `Blocked`, active `Decisions` when `decisions/*.md`
    exist, and task state counts).
  - `## Next`: Immediate next actions.

## Agent Workflow

See **[Agent Workflows & Handoff](references/workflows.md)** for detailed
protocols on commit authority, session attribution, and Agent Handoff. To hand a
task to an isolated worker that cannot read the control repository, see
**[Task Export](references/export.md)**.

- **Before work:** run `taskgo handoff <project|TASK_ID>` and follow its note:
  it names the files to read (`AGENTS.md`, the project `README.md`, `STATUS.md`,
  `PLAN.md`, the task record) and the project's skills.
  1. Read the files it names.
  1. **Activate the project's skills** if your harness has a skill manager:
     ```bash
     taskgo skills <project> | skill --scope session add -
     ```
     Pipe the whole list: a skill that is already active is reported and
     skipped. The session scope leaves `.envrc` and repository files untouched;
     harness details (when the skills become usable, what to do when there is no
     session directory) are the `skill` CLI's, in the `workspace-tools` skill
     and its output.
- **CLI or MCP:** when the control repository is the session's workspace, use
  the CLI. Elsewhere, prefer the `taskgo` MCP tools when the harness has them
  (`handoff` returns the same note and files); otherwise the CLI with `--root`.
- **After work:** update files, task frontmatter (`conversations`), and
  `STATUS.md` prose (`Summary` & `Next`). Update the project `README.md`, or the
  artifact or knowledge skill that owns a fact, only if that fact changed. Run
  `taskgo sync` and `taskgo doctor`. Optionally commit using
  `taskgo checkpoint`. Ensure the project is left in a strict **handoff-ready**
  state.

### Activity Reporting

See **[Activity Reports](references/activity-reports.md)** for generating
external impact summaries.

## CLI

Commands operate on the control repo selected by `--root`, `$TASKGO_ROOT`, or
`~/.projects`. See the **[Command Index](references/command-index.md)** for full
help details and subcommand options.

```text
taskgo id
taskgo root
taskgo create PROJECT TITLE [--slug SLUG] [--conv ID] [--status STATE] [--wait-for GATE] [--add-blocked-by ID] [--add-wait-for GATE] [--add-conversation URI] [--due YYYY-MM-DD] [--stale-after YYYY-MM-DD] [--problem TEXT] [--cost TEXT] [--goal TEXT] [--criteria TEXT] [--sketch TEXT] [--no-commit] [--dry-run]
taskgo update TASK_ID [--slug SLUG] [--conv ID] [--status STATE] [--expect-status STATE] [--wait-for GATE] [--add-|--remove-blocked-by ID] [--add-|--remove-wait-for GATE] [--add-|--remove-conversation URI] [--due YYYY-MM-DD] [--stale-after YYYY-MM-DD] [--title TITLE] [--problem TEXT] [--cost TEXT] [--goal TEXT] [--criteria TEXT] [--sketch TEXT] [--outcome TEXT] [--findings TEXT] [--next TEXT]
taskgo apply CHANGES.json [--dry-run]
taskgo edit PATH (--old TEXT | --old-file F) (--new TEXT | --new-file F) [--replace-all] [--expected-blob SHA] [--dry-run] [--json]
taskgo list [PROJECT] [--state STATE] [--json]
taskgo info PROJECT [--json]
taskgo skills PROJECT [--json]
taskgo status [PROJECT|TASK_ID] [--at REV] [--json]
taskgo handoff PROJECT|TASK_ID [--at REV] [--json]
taskgo sync [PROJECT]
taskgo check [PROJECT] [--json]
taskgo doctor [PROJECT]
taskgo fix [PROJECT] [--dry-run] [--no-commit]
taskgo history PATH_OR_TASK_ID [FIELD]
taskgo read PATH [--start-line N] [--end-line N] [--at REV] [--json] [-n]
taskgo search [--at REV] [--json] GREP_ARGS... [-- PATHS...]
taskgo checkpoint TASK_ID SUBJECT [--conv ID] [--all] [--path PATH]... [--body TEXT] [--ref REF]...
taskgo commit SUBJECT [--conv ID] [--body TEXT] [--ref REF]...
taskgo schema [--json]
taskgo mcp [--host HOST] [--port PORT] [--no-fetch | --local] [--fetch-ttl SECS] [--auth access|none] [--access-team DOMAIN] [--access-aud TAG] [--stdio] [--log FILE]
taskgo requests [--log FILE] [--days N] [--gap SECS] [--json]
```

- `create`: Allocate ID, write record, sync STATUS, optionally commit.
- `create` and `update` accept `--cost TEXT` for the consequences of leaving a
  task undone. Cost is optional, including when Problem is present.
- `update`: Edit task in-place. If using `--slug`, the rename is left
  uncommitted; commit with `checkpoint --all` to stage both old and new paths.
  Field edits replace only the named run-in (such as `**Goal:**`, moved into its
  own paragraph) or the `##` section whose heading matches exactly, and refuse
  when the label or heading appears more than once. `--expect-status STATE`
  makes the update conditional: it changes nothing and exits non-zero unless the
  current state is STATE. Unknown states are refused, not reset to `todo`.
- `apply`: Apply a change set (JSON typed operations: create, set, add, remove,
  replace_section, write_file, delete_file, edit_file) to the working tree, all
  or none, with preconditions, whole-set validation, and STATUS regeneration for
  affected projects. It is the MCP server's write semantics, offline; it does
  not commit. See [Change Sets](references/model.md#change-sets).
- `edit`: Replace exact text in one file (a change set of one `edit_file`):
  Caxton-style `search_and_replace` with verbatim bytes, a CRLF retry, near-miss
  diffs, and record validation. Assets keep their bytes and mode; tasks,
  decisions, and STATUS.md stay valid and are formatted. Does not commit.
- `handoff` (or `handover`; `dispatch`, its former name, still works): Emit
  agent handoff instructions for a project or task in the working tree (or at
  `--at REV`), warning on stderr about uncommitted state or missing scaffolding;
  the note ends with the project's skills and how to activate them; `--json`
  inlines the onboarding files, the `skills` list, a guide to keeping the
  tracker through the MCP tools, and active/ready queues in one payload,
  matching the MCP `handoff` tool.
- `skills`: Print the skills a project's README frontmatter declares, one per
  line (`--json` for an array), for `skill --scope session add -`.
- `read`: Print UTF-8 file slices (`--start-line`, `--end-line`, `-n` /
  `--line-numbers`, `--at REV`, `--json`) up to 256 KiB per read, cut at line
  boundaries, matching the MCP `read_file` tool.
- `search`: Search tracked files in the working tree or `--at REV` via an
  allowlisted `git grep` wrapper with 64 KiB output and 1 KiB line caps, exiting
  0 on match, 1 on no match, and 2 on error, matching `search_files`.
- `schema`: The declarative field and section schema for tasks, decisions, and
  `STATUS.md`. `--json` is the conformance form for other implementations.
- `fix`: Auto-heal IDs, normalize status aliases, generate STATUS, format the
  Markdown of tracker records (root `AGENTS.md`, `INBOX.md`, and `README.md`;
  each project's `README.md`, `PROJECT.md`, `STATUS.md`, `tasks/`, and
  `decisions/`), and commit repairs by default. Other documents are left as
  their owners wrote them.
- `checkpoint`: Safe automatic-commit path requiring
  `taskgo:allow-local-commits`. Enforces 50-char subject limits.
- `mcp`: Serve committed state to MCP clients and write their change sets as
  commits: by default from and to a remote, for cloud agents without a checkout
  of the control repository; with `--local`, on a checkout's own branch, for
  agents in other workspaces on the same machine. See
  [MCP Server](references/mcp.md).
- `requests`: Summarise the MCP server's request log (requests per client and
  tool, failures, latency, and the commonest runs of tool calls). Over HTTP the
  server also shows its latest requests live at `/logs`. See
  [Logging](references/mcp.md#logging).

## Reference Material

- **[Command Index](references/command-index.md)** — Detailed subcommand
  synopsis and options
- **[Model & Architecture](references/model.md)**
- **[Agent Workflows & Handoff](references/workflows.md)**
- **[Activity Reports](references/activity-reports.md)**
- **[MCP Server](references/mcp.md)** — `taskgo mcp` tools, authentication,
  logging, and testing

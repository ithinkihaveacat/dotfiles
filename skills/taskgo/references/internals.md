# taskgo Internals

This page is for people changing taskgo itself: its design reasons and how the
code is put together. You do not need it to use taskgo. For using it, start at
[SKILL.md](../SKILL.md).

## Context Economics

The main reason for current-state Markdown is **context economics**: append-only
journals grow monotonically with project age, whereas rewritten current state
grows mainly with active complexity. Historical reads are queryable on demand
via Git history without cluttering active agent context windows.

`HEAD` reflects current belief and active truth. Git retains earlier states,
diffs, ancestry, and recorded-at metadata; commit prose explains conclusions and
reasoning that diffs alone cannot recover.

## Script Layout and Execution

- `taskgo` is bundled in `scripts/taskgo`. `taskgo mcp` delegates to
  `scripts/taskgo-mcp`, which carries the MCP, HTTP, and JWT dependencies. Both
  `taskgo mcp` and `taskgo-mcp` are listed in `permissions/unsafe`.
  `TASKGO_SKILL_DIR` overrides `SKILL.md` discovery when either script is copied
  outside the skill tree.
- Root resolution never depends on the current working directory.
- Read-only commands (`status`, `list`, `handoff`, `doctor`, `read`, `search`,
  and so on) work when the repository is mounted read-only. Mutating commands
  (`create`, `update`, `apply`, `edit`, `sync`, `fix`, `checkpoint`, `commit`)
  need write access to the working tree, and commands that stage or commit
  changes (`create`, `checkpoint`, `commit`, `fix`) also need write access to
  `.git/`.
- Remote sync by default: when the repository and `.git/` are writable, CLI
  reads and writes serialize on `<git-dir>/taskgo.lock`, fetch the upstream
  tracking branch (`@{u}`), and fast-forward or rebase with `--autostash` when
  behind. Commands that create a commit (`create`, `checkpoint`, `commit`,
  `fix`) also push to the remote. `--offline` (or `AGENT_OFFLINE=1`) skips
  remote Git fetch and push.
- `read` prints UTF-8 file slices up to 256 KiB per read, cut at line
  boundaries, matching the MCP `read_file` tool. `search` is an allowlisted
  `git grep` wrapper with 64 KiB output and 1 KiB line caps, exiting 0 on match,
  1 on no match, and 2 on error, matching `search_files`.
- `taskgo schema --json` is the conformance form of the field and section schema
  for other implementations.

## Telemetry & Dual-Representation

Taskgo deliberately records agent session identifiers (`<agent>://<id>`) in two
distinct locations. This is an intentional architectural pattern, not a
violation of the Single Source of Truth:

1. **YAML Frontmatter (`conversations:`):** Acts as the spatial, fast-read
   manifest of all sessions that have contributed to the task. It guarantees
   context portability during task export (when Git history is severed) and
   provides zero-latency visibility for active (`in-progress`) sessions before
   commits exist.
1. **Git Commit Trailers (`Conversation:`):** Act as the temporal, immutable
   event log linking specific lifecycle transitions to exact agent runs.

Drift between these locations arises in valid workflows (e.g. human
collaborators executing raw `git commit` commands without trailers, or agents
actively iterating in uncommitted working trees before forming a checkpoint).
`taskgo doctor` emits non-blocking `[INFO]` diagnostics for these anomalies, but
agents must prioritize the Markdown files as current state and Git as the
historical record.

## Snapshot Core

Parsing, validation, rendering, formatting, audit, and task edits read and write
repository files only through a `Snapshot`, addressed by repository-relative
POSIX paths:

- **`FsSnapshot`:** The working tree (`WorktreeSnapshot` extends it with
  `HEAD`'s commit SHA and on-demand blob SHAs for `status` and `handoff`). Reads
  and writes go straight to disk; CLI commands operating on the working tree use
  it.
- **`GitTreeSnapshot`:** One commit's tree, read with `git ls-tree` and
  `git cat-file --batch`, without a checkout. Used by `taskgo mcp` and by CLI
  reads passed `--at REV` (`status`, `handoff`, `read`, `search`). It is
  read-only; writes raise `ReadOnlySnapshotError`.
- **`OverlaySnapshot`:** Pending writes held in memory over either of the
  others. A [change set](change-sets.md) is applied to one, so a refused change
  set writes nothing.

Rendering a commit's tree gives the same task rows, `STATUS.md`, and audit
findings as rendering a checkout of it. Git commands that inspect the repository
rather than its files (commit authority, shallow clones, staging, history) stay
in the CLI commands. Task edits are `edit_task_text()` (text in, text out) and
`update_task()` (edit, rename, and sync over a snapshot).

## Unified AuditEngine Architecture (`doctor`, `fix`, and `handoff`)

To eliminate diagnostic and repair drift, `scripts/taskgo` uses a single shared
`AuditEngine`: `audit_snapshot()` over a snapshot, wrapped by
`audit_workspace()`, which adds the repository's shallow-clone check and
`audit_skills()` (checking declared project `skills` against the `skill` CLI
catalog). Remediations write through the audited snapshot:

- **`doctor` (Strictly Read-Only):** Runs the audit engine, renders findings
  with canonical 4-letter plain-ASCII tags (`[PASS]`, `[INFO]`, `[WARN]`,
  `[FAIL]`), and exits non-zero on errors per CLI design standards.
- **`fix` (Auto-Healing Engine):** Runs the same audit engine, executes
  remediation callbacks for auto-fixable findings (assigning missing task IDs,
  normalizing status aliases, synchronizing `STATUS.md` snapshots, writing the
  managed block of the root `AGENTS.md`, formatting the Markdown of tracker
  records), verifies convergence on the touched paths, and auto-commits repairs
  by default with deterministic `COMMIT_SHA` output on `stdout`. Use `--dry-run`
  to preview changes without modifying files or committing, or `--no-commit` to
  apply repairs on disk without committing. Tracker records are the root
  `AGENTS.md`, `INBOX.md`, and `README.md`, and each project's `README.md`,
  `PROJECT.md`, `STATUS.md`, and the Markdown files directly in `tasks/` and
  `decisions/`. Other documents, and files Git ignores, are never reformatted.
- **`handoff` (Tree Projection):** Runs the audit engine with `markdown=False`
  (skipping `[INFO]` formatting checks) over the working tree or `--at REV`
  commit alongside handoff-specific readiness checks, then emits a handoff note
  from the selected project or task record. `[WARN]` and `[FAIL]` findings and
  uncommitted changes are reported on stderr without changing the note on
  stdout.

## Handoff Design

Agent handoff and task export solve different problems. An isolated worker
cannot read the control repository, so an exported brief must inline the task
specification and its dependencies. An agent with the control repository can
read the tracker, artifact repositories, and Git history; it needs a destination
rather than duplicated context. This is true both at the start of a fresh agent
session and when work passes to a successor.

`taskgo handoff TASK_ID` therefore generates a short handoff note containing
only the task ID, project, title, `Goal`, and paths to the project status and
task record. `taskgo handoff PROJECT` names the project, its `README.md` title,
its in-progress and ready tasks (one line each, at most ten), and paths to its
`README.md`, `STATUS.md`, and `PLAN.md`. The task list is what lets the person
passing the note on check it, as the `Goal` does for a task; it lists the
frontier without choosing from it. These values come from the working tree,
which a local agent reads too; `--at REV` reads a commit instead. An agent
reading through the MCP server sees only what has been pushed, so uncommitted
changes in the project raise a warning. The human passing on the note remains
the router: its summary lets that person verify the selected task before pasting
it, while the receiving agent uses the identifier and title as a cross-check
before reading the tracker and choosing an approach.

The note is a destination for a human router. An agent without a checkout, such
as an MCP client, still has to read what the note names, so
`taskgo handoff --json` and the MCP `handoff` tool carry those files beside the
unchanged note: the project `README.md` with its frontmatter, `STATUS.md`,
`PLAN.md`, the root `AGENTS.md`, the active and ready tasks, and the task
record, verbatim, in one round trip. The payload inlines reads; it never widens
the note.

## Root Landing Page (`README.md`)

`AGENTS.md` is strictly machine- and agent-directed. For human developers
browsing the control repository via web interfaces (GitHub, GitLab), a root
`README.md` is optionally useful as an evergreen, zero-maintenance landing page.

To prevent ceremony and drift, a root `README.md` should **not** attempt to
maintain manual project tables or task summaries. Instead, it provides a stable
structural overview and CLI quick reference:

````markdown
# Control Repository

A private project and task control repository maintained with [**`taskgo`**](https://github.com/ithinkihaveacat/dotfiles/tree/main/skills/taskgo).

## Structure

- [`AGENTS.md`](AGENTS.md) — Agent operating instructions, environment rules, and repository authority.
- [`INBOX.md`](INBOX.md) — Unclassified scratchpad and zero-ceremony task capture.
- **Projects (`<project>/`)** — Discrete initiatives containing identity, operational status, and granular task records.

## CLI Quick Reference

```bash
# Check status across all projects
taskgo status

# Create a new task
taskgo create <project> "<task-title>"

# Synchronize status snapshots
taskgo sync <project>

# Auto-heal metadata and synchronize snapshots
taskgo fix

# Verify repository health
taskgo doctor
```
````

## Concurrency

Random globally checked IDs avoid a shared allocator: a new ID is checked
against the current tree and against every ID named in the paths or messages of
any ref's history, so a deleted task's ID or one on an unmerged branch is never
reused. Allocation does not reserve an ID, so two writers can still pick the
same one; `taskgo doctor` reports duplicate IDs after a merge.

## References

- <https://adr.github.io/>
- <https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions>
- <https://git-scm.com/docs/git-log>
- <https://git-scm.com/docs/git-interpret-trailers>

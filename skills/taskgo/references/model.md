# taskgo model & architecture

## Context Economics

The main reason for current-state Markdown is **context economics**: append-only
journals grow monotonically with project age, whereas rewritten current state
grows mainly with active complexity. Historical reads are queryable on demand
via Git history without cluttering active agent context windows.

`HEAD` reflects current belief and active truth. Git retains earlier states,
diffs, ancestry, and recorded-at metadata; commit prose explains conclusions and
reasoning that diffs alone cannot recover.

## Single Developer & Project Scaling Spectrum

`taskgo` is explicitly designed for a **single human developer operating
alongside AI coding agents**. To prevent unnecessary ceremony on small
initiatives while scaling cleanly to large efforts, it supports three tiers of
project scale:

- **Scale 0 (Quick Scratchpad):** `INBOX.md` at the repository root provides
  zero-ceremony capture of unclassified notes, thoughts, and ideas without
  schemas.
- **Scale 1 (Lightweight Project):** A project directory containing `README.md`
  (serving as project manifest, optionally declaring YAML frontmatter such as
  `skills: [...]` for per-project agent skills, and
  `**Domain / Stakeholders:** [Entity]` to anchor thematic grouping for activity
  reporting), `STATUS.md` (operational projection), and `tasks/` containing
  granular task records. `PLAN.md`, `decisions/`, `references/`, `scripts/`, and
  `data/` remain optional.
- **Scale 2 (Multi-Month Initiative):** Extends Scale 1 with explicit roadmap
  sequencing in `PLAN.md`, formal Nygard-style Architecture Decision Records in
  `decisions/*.md`, supporting context in `references/`, custom tooling in
  `scripts/`, datasets in `data/`, evaluation/benchmark runs in `results/`, and
  deployable deliverables in `dist/`.

## Repository Terminology & Boundaries

A **control repository** (interchangeably called a *control repo*, *taskgo
tracker*, *tracker repository*, or *project tracker*) manages initiatives,
tasks, decisions, and exploratory assets across one or more external **artifact
repositories**:

- **Control Repository (`projects/`):** Houses private task tracking
  (`STATUS.md`, `tasks/`), roadmaps (`PLAN.md`), Architecture Decision Records
  (`decisions/`), supporting context (`references/`), and project-scoped working
  artifacts (`scripts/`, `data/`, `results/`, `dist/`). Very large artifacts
  (such as cloned repositories or heavy binary test data) should be referenced
  or fetched on demand rather than checked into Git.
- **Artifact Repositories (e.g. `dotfiles`, product codebases):** House
  permanent production code, reusable libraries, shipping CLIs, and
  contract/regression test suites (`test-*`). Commits in artifact repositories
  must remain strictly free of private control repo metadata.

### Standard Directory Structure

```text
AGENTS.md                 # taskgo declaration + repository instructions
INBOX.md                  # zero-ceremony capture; no schema
<id>/
  README.md               # identity, map, standing rules (optional YAML frontmatter: skills, etc.)
  STATUS.md               # current human view + generated task block
  PLAN.md                 # intended route forward (optional)
  tasks/*.md              # stable task records
  decisions/*.md          # ADRs for private or cross-artifact decisions (optional)
  docs/*                  # authored prose deliverables, specs, guides, or sync mirrors (optional)
  references/*            # current-state supporting context private to the project (optional)
  bugreports/*            # captured bug reports, reproduction logs, triage traces (optional)
  reviews/*               # code, design, or document reviews (optional)
  scripts/*               # automation, audit harnesses, pipelines, report generators (optional)
  data/*                  # input datasets, package lists, static fixtures (optional)
  results/*               # benchmark telemetry, run logs, audit outputs (optional)
  dist/*                  # static dashboards, deployable bundles, HTML reports (optional)
```

`PROJECT.md` is a legacy name for the project README; the CLI still reads it
when `README.md` is absent, but new and renamed projects use `README.md`.

`docs/`, `bugreports/`, and `reviews/` hold authored prose deliverables when the
output is a document, issue report, or review rather than code; when published
externally, the `README.md` map records which copy is canonical. `scripts/`
holds repeatable, project-scoped helpers (queries, audit runners, report
builders) so future sessions reuse them instead of recreating them in scratch;
they need not meet the packaging bar of reusable skill scripts. `references/`
holds stable descriptions that are private to the project and true now, such as
domain notes or source material for a deliverable. Evidence from runs belongs in
`results/`. Material imported from elsewhere and kept for history is labeled as
such in the README map rather than presented as current.

## System & Non-Code Projects

Not every project centers on a code repository. A project's primary output may
be prose deliverables (`docs/`, `bugreports/`, `reviews/`) and supporting
`scripts/`, or it may have no external artifact at all (such as a personal or
household project where `STATUS.md` and `tasks/` carry the work).

A **system project** tracks work on something the user operates, such as
machines and services or a household, whose durable description lives in a
**knowledge skill**: a private skill, loaded by topic, that records current
facts about particular systems, accounts, people, or places. The knowledge skill
plays the role of the artifact repository: tasks change the system and finish by
updating the skill to the new current state, linking the skill repository's
commit with a `Ref:` trailer. The project README names the skill in its map (and
in `skills:` frontmatter) instead of copying its facts. Many knowledge skills
never need a project; create one when a system has enough ongoing work to track.

## Where Knowledge Lives

Each fact has one owner; other locations link to it. Choose the owner by who
needs the fact and how often it changes:

| Kind of fact                                                                | Owner                                                                         |
| --------------------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| How the code works, how to build and run it, code-level invariants and ADRs | Artifact repository (`README.md`, `AGENTS.md`, `docs/`)                       |
| What a system, account, person, or place is and how to reach or operate it  | Knowledge skill                                                               |
| Authored reports, specs, guides, bug reports, or reviews                    | External canonical doc/issue, or `<project>/docs/`, `bugreports/`, `reviews/` |
| Repeatable project-scoped queries, probes, or report helpers                | `<project>/scripts/` (or a skill/artifact repo once promoted)                 |
| Why the project exists, its scope, where everything lives, standing rules   | Project `README.md`                                                           |
| Reasoning behind a private or cross-artifact standing rule                  | Project `decisions/`                                                          |
| Intended route                                                              | `PLAN.md`                                                                     |
| Current situation and next actions                                          | `STATUS.md`                                                                   |
| A unit of work, its outcome, and findings                                   | `tasks/`                                                                      |
| Run evidence, supporting context                                            | `results/`, `references/`                                                     |
| What changed, when, and why                                                 | Git history (commit prose, `Ref:` and `Conversation:`)                        |

The control repository files differ mainly in how often they change: `README.md`
over months, `PLAN.md` over weeks, and `STATUS.md` nearly every commit.

Information architecture drifts, and historical layouts persist. Work with it
using these principles rather than reorganizing everything at once:

1. **One owner per fact; everywhere else links.** Pointers go stale more slowly
   than copies.
1. **Repair opportunistically.** When touching a file, replace a copied fact
   with a link to its owner, or move misplaced content to where it belongs.
1. **The artifact wins.** When a description disagrees with the code or the
   system it describes, the description is wrong.
1. **Declare historical locations and exceptions instead of forcing them to
   move.** An in-repository `TODO.md`, an imported planning document, a staging
   skill that mixes workflows and reference facts, or a project that diverges
   from these defaults can stay where it is; the project `README.md` map (or
   skill header, if useful) says what it is and whether it is canonical.

## Project README

The project `README.md` is the stable, private description of the project. An
artifact repository's own README describes the code to anyone who has it: what
it is, how to build and use it, how it is put together. The project README
describes the user's stewardship of it: things that are true because this
project exists and that a stranger with only the code would not need or should
not see. It has three roles:

- **Identity:** why the project exists, whom it serves, what success looks like,
  and what is in and out of scope. Scope may exclude things the code README
  never mentions ("not the in-repository backlog", "no paid APIs").
- **Map:** where everything lives — checkouts, remotes and forks, deployments,
  data, project `scripts/`, related projects, and the knowledge skills
  describing the systems it runs on — and which source is canonical where
  several overlap.
- **Standing rules:** constraints that govern work and outlast any task,
  especially private ones such as data-safety rules, spending limits, and
  publication boundaries. State each rule briefly and link the ADR that explains
  it, if one exists.

To decide whether a sentence belongs in the project README, ask whether it will
still be true after the next five tasks finish; if not, it belongs in
`STATUS.md`, `PLAN.md`, or a task. Code facts, system facts (host specs, how to
reach a machine), the reasoning behind rules, and history belong to the owners
in the table above; the README links to them.

Suggested skeleton (existing headings such as `## Artifacts` or `## Boundaries`
serve the map role and need not be renamed):

```markdown
---
skills:
  - <skill needed when working on this project>
---

# Project Name

One or two sentences on what the project is and why it exists.

## Scope

In scope, and explicitly out of scope.

## Map

- Repository: <https://github.com/owner/repo>; local checkout: `~/workspace/repo`
- Deployment and host details: the `<knowledge-skill>` skill
- Backlog: this tracker owns <X>; the in-repository `TODO.md` owns <Y>
- Related projects: [other](../other/README.md) owns <Z>

## Constraints

- Standing rule, briefly ([ADR](decisions/001-rule.md)).
```

## Task Records & Archiving

Completed tasks remain as permanent, stable records in `tasks/TASK-XXXXX-*.md`
with `status: done`. They keep Problem, Cost, Goal, and Criteria, and add
`## Outcome` (a verdict against each criterion) and `## Findings`.

Context boundedness is achieved through `STATUS.md`:

- `STATUS.md` projects active `In progress` and `Blocked` tasks alongside counts
  (`Todo: N Done: M`).
- Completed tasks are summarized in `## Summary` prose rather than listed in the
  active task snapshot, preventing `STATUS.md` from bloating as milestones
  accumulate.
- If a task record is ever archived or deleted from the working tree,
  `taskgo history` falls back to querying Git history blobs seamlessly.

## Architecture Decision Records (ADRs) & Supersedes Lifecycle

Projects with durable architectural invariants store Nygard-style ADRs in
`<project>/decisions/NNN-slug.md` with `## Status`, `## Context`, `## Decision`,
and `## Consequences` sections.

To keep accepted ADRs stable while preventing obsolete decisions from polluting
active agent context:

- **Declarative `supersedes` Edges:** When a newer ADR replaces an earlier
  decision, record `supersedes: [001-old-decision.md]` (matching by filename,
  stem, or numeric prefix like `001`) in the *newer* ADR's YAML frontmatter
  rather than rewriting the older file. Edit an accepted ADR in place only for
  typos, status updates, broken links, or implementation notes, never to change
  its decision.
- **Active ADR Projection (`STATUS.md`):** When `<project>/decisions/*.md` is
  non-empty, `taskgo sync` projects a `### Decisions` list inside the generated
  `<!-- taskgo:begin --> ... <!-- taskgo:end -->` snapshot containing only
  *active* (non-superseded) ADRs.
- **Stale-Reference & Graph Auditing (`taskgo doctor`):** The shared
  `AuditEngine` verifies `supersedes` targets and checks for cycles. For active
  ADRs, it warns (`[WARN]`) if an ADR cites a superseded ADR or contains broken
  relative Markdown links within the control repository. Once an ADR is
  superseded, its historical links and ADR references are exempt from staleness
  warnings.

## Telemetry & Dual-Representation

Taskgo deliberately records agent session identifiers (`<agent>://<id>`) in two
distinct locations. This is an intentional architectural pattern, not a
violation of the Single Source of Truth:

1. **YAML Frontmatter (`conversations:`):** Acts as the spatial, fast-read
   manifest of all sessions that have contributed to the task. It guarantees
   context portability during task ejection (when Git history is severed) and
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

- **`FsSnapshot`:** The working tree. Reads and writes go straight to disk;
  every CLI command uses it.
- **`GitTreeSnapshot`:** One commit's tree, read with `git ls-tree` and
  `git cat-file --batch`, without a checkout. It is read-only; writes raise
  `ReadOnlySnapshotError`.
- **`OverlaySnapshot`:** Pending writes held in memory over either of the
  others. A [change set](#change-sets) is applied to one, so a refused change
  set writes nothing.

Rendering a commit's tree gives the same task rows, `STATUS.md`, and audit
findings as rendering a checkout of it. Git commands that inspect the repository
rather than its files (commit authority, shallow clones, staging, history) stay
in the CLI commands. Task edits are `edit_task_text()` (text in, text out) and
`update_task()` (edit, rename, and sync over a snapshot).

## Change Sets

A change set is the unit of a typed write: a list of operations applied in
order, all or none. `taskgo apply CHANGES.json` applies one to the working tree
without committing, so the MCP server's write semantics can be tried offline.
The file is a JSON object with one key, `changes`:

```json
{"changes": [
  {"op": "create", "kind": "task", "project": "my-project", "ref": "a",
   "fields": {"blocked_by": ["TASK-3A91F"]},
   "sections": {"title": "Add a cache", "Goal": "Sub-10ms reads."}},
  {"op": "set", "record": "TASK-3A91F", "field": "status", "value": "done",
   "expected": "in-progress"},
  {"op": "replace_section", "record": "TASK-3A91F", "section": "Outcome",
   "text": "Met.", "expected_hash": null}
]}
```

| Operation         | Keys                                                                          | Precondition                          |
| ----------------- | ----------------------------------------------------------------------------- | ------------------------------------- |
| `create`          | `kind` (`task` or `decision`), `project`, `ref`, `slug`, `fields`, `sections` | none; IDs and numbers are allocated   |
| `set`             | `record`, `field`, `value`, `expected` (optional)                             | `expected`, when given                |
| `add`, `remove`   | `record`, `field`, `values`                                                   | none; repeats and absences are no-ops |
| `replace_section` | `record`, `section`, `text`, `expected_hash`                                  | the section's hash                    |
| `write_file`      | `path`, `content`, `expected_blob` (optional), `executable` (optional)        | absent, or the file's Git blob SHA    |
| `delete_file`     | `path`, `expected_blob`                                                       | the file's Git blob SHA               |
| `edit_file`       | `path`, `old_string`, `new_string`, `replace_all`, `expected_blob` (optional) | `old_string` occurs; `expected_blob`  |

- **Records:** A task ID, a decision path, a project's `STATUS.md`, or `$name`
  for a record an earlier `create` named with `ref`. `$name` also works in
  `blocked_by` and `supersedes` values, so one set can create a task and the
  task it blocks.
- **Fields:** `set` takes a task's `status`, `due`, `stale_after`, or `title`,
  and a decision's `status`; null clears an optional one. `add` and `remove`
  take the set fields of the [schema](command-index.md#schema). Conversations
  need an explicit `<agent>://<id>`.
- **Sections:** `replace_section` takes a task section other than the title, or
  `STATUS.md` Summary or Next. `expected_hash` is the hash `get_task` or
  `get_project_status` reports, or null when the section is absent; a null
  `text` removes an optional section. A new section goes where the schema orders
  it. Text that would add or remove any other section is refused.
- **Files:** `write_file` writes project assets: any file in an existing project
  outside `tasks/`, `decisions/`, and `STATUS.md`, and `INBOX.md`. It refuses
  `.git*` paths, `..`, symbolic links, more than 256 KiB, non-UTF-8 content, and
  a `README.md` whose frontmatter does not parse. Without `expected_blob` (or
  with null) the file must be new; a file that exists is refused with its blob,
  which `expected_blob` must name to overwrite it, so a write never loses a
  change made since the caller read the file. `content` must be a string:
  `delete_file` deletes a file whose blob is `expected_blob`, under the same
  path rules, except a project's `README.md`. A rewritten file keeps its mode
  and a new one is not executable, unless `executable` is `true` or `false`,
  which sets the mode (100755 or 100644). Markdown is formatted, so the result
  reports each written file's new blob SHA.
- **Edits:** `edit_file` replaces exact text in an existing file, as Caxton's
  `search_and_replace` does: `old_string` must occur exactly once, or
  `replace_all` must be true. It edits the assets `write_file` writes and the
  records too: tasks, decisions, and a project's `STATUS.md` outside its
  generated block. Bytes match verbatim; only when nothing matches, the file has
  CRLF line endings, and `old_string` has bare `\n` ones, are both strings
  retried with CRLF. Assets are written exactly as replaced and keep their mode.
  A record must stay valid: its frontmatter parses, a task keeps its `id` and a
  known status, no section appears twice that did not before, and entries added
  to `blocked_by` or `supersedes` are checked as `add` checks them; records are
  formatted once the whole set has applied, so several edits of one record each
  match the text the one before it left. Files and results are limited to 256
  KiB. A miss is a precondition failure, with a unified diff against the closest
  lines; several matches without `replace_all` are invalid. The result's `edits`
  list gives each edit's `occurrences_replaced`, the `start_line` and `end_line`
  of its first replacement (lines end at `\n`), and the file's `total_lines` and
  `blob` after the set.

Each precondition is checked when its change applies, against the state the
changes before it left. Validation then runs on the state after the whole set:
added blockers and superseded decisions exist, no `blocked_by` or `supersedes`
cycle passes through a changed record, task IDs stay unique, and a task that
becomes done, or whose Outcome changes while done, has a non-empty Outcome.
Last, `STATUS.md` is regenerated for each project with a changed task, decision,
or `STATUS.md`, and for each project with a task that a changed task blocks; a
snapshot block shows only direct blockers, so no further project can change.
Other projects' date-driven refreshes stay with `taskgo sync`.

A refusal names the change and its kind: `invalid` (malformed or disallowed),
`precondition` (an expected value, hash, or blob that no longer holds), or
`validation` (the whole set's result breaks a rule). Nothing is written. To read
section hashes offline, run `taskgo mcp --stdio --no-fetch`, which serves the
committed local branch.

## Unified AuditEngine Architecture (`doctor`, `fix`, and `dispatch`)

To eliminate diagnostic and repair drift, `scripts/taskgo` uses a single shared
`AuditEngine`: `audit_snapshot()` over a snapshot, wrapped by
`audit_workspace()`, which adds the repository's shallow-clone check.
Remediations write through the audited snapshot:

- **`doctor` (Strictly Read-Only):** Runs the audit engine, renders findings
  with canonical 4-letter plain-ASCII tags (`[PASS]`, `[INFO]`, `[WARN]`,
  `[FAIL]`), and exits non-zero on errors per CLI design standards.
- **`fix` (Auto-Healing Engine):** Runs the exact same audit engine, executes
  structured remediation callbacks for auto-fixable findings (assigning missing
  task IDs, normalizing status aliases, synchronizing `STATUS.md` snapshots,
  formatting the Markdown of tracker records), verifies convergence, and
  auto-commits repairs by default with deterministic `COMMIT_SHA` output on
  `stdout`. Use `--dry-run` to preview changes without modifying files or
  committing, or `--no-commit` to apply repairs on disk without committing.
  Tracker records are the root `AGENTS.md`, `INBOX.md`, and `README.md`, and
  each project's `README.md`, `PROJECT.md`, `STATUS.md`, and the Markdown files
  directly in `tasks/` and `decisions/`. Other documents, and files Git ignores,
  are never reformatted.
- **`dispatch` (Committed-State Projection):** Uses the audit engine's project
  findings, over the tree committed at `HEAD`, alongside dispatch-specific
  checks, then emits a dispatch note from the selected project or task record at
  `HEAD`. Findings describe working-tree or tracker defects on stderr without
  changing the committed note on stdout.

## Agent Dispatch

Agent dispatch and isolated-worker ejection solve different problems. An
isolated worker cannot read the control repository, so an ejection payload must
inline the task specification and its dependencies. An agent with the control
repository can read the tracker, artifact repositories, and Git history; it
needs a destination rather than duplicated context. This is true both at the
start of a fresh agent session and when work passes to a successor.

`taskgo dispatch TASK_ID` therefore generates a short dispatch note containing
only the task ID, project, title, `Goal`, and paths to the project status and
task record. `taskgo dispatch PROJECT` names the project, its `README.md` title,
and paths to its `README.md`, `STATUS.md`, and `PLAN.md`. These values come from
the records committed at `HEAD`, which keeps the note reproducible even when the
working tree is dirty. The human dispatching the note remains the router: its
summary lets that person verify the selected task before pasting it, while the
receiving agent uses the identifier and title as a cross-check before reading
the tracker and choosing an approach.

The command does not select work. `taskgo list PROJECT --state ready` exposes
the ready frontier, and `STATUS.md` records the intended immediate direction. A
long dispatch note or one requiring extra facts indicates that the tracker is
not handoff-ready; repair the durable state instead of expanding the note.

The note is a destination for a human router. An agent without a checkout, such
as an MCP client, still has to read what the note names, so
`taskgo dispatch --json` and the MCP `dispatch` tool carry those files beside
the unchanged note: the project `README.md` with its frontmatter, `STATUS.md`,
`PLAN.md`, the root `AGENTS.md`, the active and ready tasks, and the task
record, verbatim, in one round trip. The payload inlines reads; it never widens
the note.

## Command Vocabulary

Commands follow the fixed `tool [verb] [noun]` structure with clean,
unhyphenated verbs:

- `taskgo id`: Allocate unique `TASK-XXXXX` identifier.
- `taskgo create PROJECT TITLE [--slug SLUG] [--status STATE] [--no-commit] [--dry-run]`:
  Create a structured task record. `--slug` names the file
  (`TASK-XXXXX-<slug>.md`); when omitted, the slug is derived from `TITLE` and
  shortened at word boundaries to 32 characters, with a warning.
- `taskgo list [PROJECT] [--state STATE] [--json]`: List tasks in tabular or
  JSON format.
- `taskgo status [PROJECT] [--json]`: Display operational status or
  multi-project summary.
- `taskgo dispatch PROJECT|TASK_ID [--at REV] [--json]`: Generate agent
  instructions from the selected project or task record committed at `HEAD` and
  report readiness findings on stderr; `--json` inlines the files the note
  names.
- `taskgo apply CHANGES.json [--dry-run]`: Apply an atomic change set (`create`,
  `set`, `add`, `remove`, `replace_section`, `write_file`, `delete_file`,
  `edit_file`) to the working tree without committing.
- `taskgo edit PATH (--old TEXT | --old-file F) (--new TEXT | --new-file F) [...]`:
  Replace exact text in one file as a single-operation `edit_file` change set.
- `taskgo read PATH [--start-line N] [--end-line N] [--at REV] [--json] [-n]`:
  Read 1-indexed line slices from the working tree or commit `REV`.
- `taskgo search [--at REV] [--json] GREP_ARGS... [-- PATHS...]`: Search tracked
  files with allowlisted `git grep` flags and bounded output.
- `taskgo sync [PROJECT]`: Synchronize `STATUS.md` snapshot block.
- `taskgo doctor [PROJECT]`: Diagnostic health check (read-only).
- `taskgo fix [PROJECT] [--dry-run] [--no-commit]`: Auto-heal task metadata,
  status, and scaffolding.
- `taskgo history PATH_OR_TASK_ID [FIELD]`: Derive state transitions from Git
  ancestry.
- `taskgo checkpoint TASK_ID SUBJECT [...]`: Guarded checkpoint transition
  commit.
- `taskgo commit SUBJECT [...]`: Commit logical transition.

## Root Landing Page (`README.md`)

`AGENTS.md` is strictly machine- and agent-directed. For human developers
browsing the control repository via web interfaces (GitHub, GitLab), a root
`README.md` is optionally useful as an evergreen, zero-maintenance landing page.

To prevent ceremony and drift, a root `README.md` should **not** attempt to
maintain manual project tables or task summaries. Instead, it provides a stable
structural overview and CLI quick reference:

````markdown
# Control Repository

A private project and task control repository maintained with [**`taskgo`**](https://github.com/ithinkihaveacat/dotfiles/tree/master/skills/taskgo).

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

Prefer separate branches/worktrees. Random globally checked IDs avoid a shared
allocator: a new ID is checked against the current tree and against every ID
named in the paths or messages of any ref's history, so a deleted task's ID or
one on an unmerged branch is never reused. Allocation does not reserve an ID, so
two writers can still pick the same one; `taskgo doctor` reports duplicate IDs
after a merge. Resolve merges by reconciling files to one intended current
state; STATUS may be rewritten freely. Stable paths and accepted ADR text are
defaults, not reasons to preserve a broken merge. Avoid squash integration when
intermediate state transitions matter, because squashing can erase
reconstructible states.

## References

- <https://adr.github.io/>
- <https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions>
- <https://git-scm.com/docs/git-log>
- <https://git-scm.com/docs/git-interpret-trailers>

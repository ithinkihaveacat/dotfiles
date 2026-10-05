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

`docs/`, `bugreports/`, and `reviews/` hold authored deliverables when a
project's output is prose rather than (or alongside) code: position papers,
partner guides, design specs, bug reports, or review notes. When a document is
also published externally (such as a Google Doc, internal doc, or filed issue),
the project `README.md` map records which copy is canonical and whether the
local file is a working draft, a sync mirror, or a historical snapshot.
`scripts/` holds project-scoped, often ad-hoc scripts—data collectors, audit
runners, reproduction harnesses, or report builders—especially when a project
has no code repository of its own. These act as executable documentation:
checking them into `scripts/` and listing them in the `README.md` map keeps
future agent sessions from reconstructing the same helper in scratch space every
time. They do not need the packaging or review rigor of scripts in a reusable
skill; if one later graduates into a skill or artifact repository, update the
map to point to the new owner. `references/` holds stable descriptions that are
private to the project and true now, such as domain notes or source material for
a deliverable. Evidence from runs belongs in `results/`. Material imported from
elsewhere and kept for history is labeled as such in the README map rather than
presented as current.

## Project Varieties & Exceptions

While `taskgo` is optimized for technical projects centered on code
repositories, the same structure accommodates other kinds of work without
forcing a uniform mould:

- **Document, Research, and Bug-Report Projects:** Many technical projects
  produce prose deliverables (`docs/`), bug reports (`bugreports/`), or reviews
  (`reviews/`), or coordinate across several upstream repositories and external
  documents. Here the authored documents, filed issues, and supporting
  `scripts/` are the primary artifacts, and the project `README.md` map records
  where each canonical version lives.
- **System Projects:** A **system project** tracks work on something the user
  operates, such as machines and services or a household, whose durable
  description lives in a **knowledge skill**: a private skill, loaded by topic,
  that records current facts about particular systems, accounts, people, or
  places. The knowledge skill plays the role of the artifact repository: tasks
  change the system and finish by updating the skill to the new current state,
  linking the skill repository's commit with a `Ref:` trailer. The project
  README names the skill in its map (and in `skills:` frontmatter) instead of
  copying its facts. Many knowledge skills never need a project; create one when
  a system has enough ongoing work to track.
- **Personal and Non-Technical Projects:** A project like `house` or `taxes`—or
  a task such as booking a personal holiday or figuring out what to do about a
  front gate—may have no external repository or skill at all. The fit with
  engineering-oriented conventions can be slightly loose, and that is fine:
  `STATUS.md` and `tasks/` carry the work without extra ceremony.
- **Staging Skills and Non-Conforming Projects:** Not every skill or project is
  cleanly partitioned. A private or employer skill may act as an intentional
  **staging ground** that mixes capability workflows and reference facts until
  focused skills are ready to be extracted, and some projects may diverge from
  these guidelines. Treat these rules as helpful defaults rather than rigid
  requirements. A project or skill may self-identify its role or exceptions in
  its documentation so agents and linters do not flag them, though even explicit
  declaration is optional.

## Where Knowledge Lives

Each fact has one owner; other locations link to it. Choose the owner by who
needs the fact and how often it changes:

| Kind of fact                                                                | Owner                                                                                            |
| --------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| How the code works, how to build and run it, code-level invariants and ADRs | Artifact repository (`README.md`, `AGENTS.md`, `docs/`)                                          |
| What a system, account, person, or place is and how to reach or operate it  | Knowledge skill (or a staging skill's reference files)                                           |
| Authored reports, specs, guides, bug reports, or reviews                    | External canonical doc/issue, or `<project>/docs/`, `bugreports/`, `reviews/` (per `README` map) |
| Repeatable project-specific queries, probes, or report/audit helpers        | `<project>/scripts/` (listed in `README` map; or a skill/artifact repo once promoted)            |
| Why the project exists, its scope, where everything lives, standing rules   | Project `README.md`                                                                              |
| Reasoning behind a private or cross-artifact standing rule                  | Project `decisions/`                                                                             |
| Intended route                                                              | `PLAN.md`                                                                                        |
| Current situation and next actions                                          | `STATUS.md`                                                                                      |
| A unit of work, its outcome, and findings                                   | `tasks/`                                                                                         |
| Run evidence, supporting context                                            | `results/`, `references/`                                                                        |
| What changed, when, and why                                                 | Git history (commit prose, `Ref:` and `Conversation:`)                                           |

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
1. **Declare historical locations and intentional exceptions instead of forcing
   them to move.** An in-repository `TODO.md`, an imported planning document, a
   hybrid staging skill, or an unconventional project can stay where it is; the
   project `README.md` map (or skill header) says what it is and whether it is
   canonical.

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
with `status: done` (including `## Outcome` and `## Findings`).

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

To keep accepted ADRs immutable while preventing obsolete decisions from
polluting active agent context:

- **Declarative `supersedes` Edges:** When a newer ADR replaces an earlier
  decision, record `supersedes: [001-old-decision.md]` (matching by filename,
  stem, or numeric prefix like `001`) in the *newer* ADR's YAML frontmatter
  rather than rewriting the older file.
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

## Unified AuditEngine Architecture (`doctor`, `fix`, and `dispatch`)

To eliminate diagnostic and repair drift, `scripts/taskgo` uses a single shared
`AuditEngine` (`audit_workspace()`):

- **`doctor` (Strictly Read-Only):** Runs the audit engine, renders findings
  with canonical 4-letter plain-ASCII tags (`[PASS]`, `[INFO]`, `[WARN]`,
  `[FAIL]`), and exits non-zero on errors per CLI design standards.
- **`fix` (Auto-Healing Engine):** Runs the exact same audit engine, executes
  structured remediation callbacks for auto-fixable findings (assigning missing
  task IDs, normalizing status aliases, synchronizing `STATUS.md` snapshots),
  verifies convergence, and auto-commits repairs by default with deterministic
  `COMMIT_SHA` output on `stdout`. Use `--dry-run` to preview changes without
  modifying files or committing, or `--no-commit` to apply repairs on disk
  without committing.
- **`dispatch` (Committed-State Projection):** Uses the audit engine's project
  findings alongside dispatch-specific checks, then emits a dispatch note from
  the selected task record at `HEAD`. Findings describe working-tree or tracker
  defects on stderr without changing the committed note on stdout.

## Agent Dispatch

Agent dispatch and isolated-worker ejection solve different problems. An
isolated worker cannot read the control repository, so an ejection payload must
inline the task specification and its dependencies. An agent with the control
repository can read the tracker, artifact repositories, and Git history; it
needs a destination rather than duplicated context. This is true both at the
start of a fresh agent session and when work passes to a successor.

`taskgo dispatch TASK_ID` therefore generates a short dispatch note containing
only the task ID, project, title, `Goal`, and paths to the project status and
task record. These values come from the task record committed at `HEAD`, which
keeps the note reproducible even when the working tree is dirty. The human
dispatching the note remains the router: its summary lets that person verify the
selected task before pasting it, while the receiving agent uses the identifier
and title as a cross-check before reading the tracker and choosing an approach.

The command does not select work. `taskgo list PROJECT --state ready` exposes
the ready frontier, and `STATUS.md` records the intended immediate direction. A
long dispatch note or one requiring extra facts indicates that the tracker is
not handoff-ready; repair the durable state instead of expanding the note.

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
- `taskgo dispatch TASK_ID`: Generate agent instructions from the selected task
  record committed at `HEAD` and report readiness findings on stderr.
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
allocator. Resolve merges by reconciling files to one intended current state;
STATUS may be rewritten freely. Stable paths and accepted ADR text are defaults,
not reasons to preserve a broken merge. Avoid squash integration when
intermediate state transitions matter, because squashing can erase
reconstructible states.

## References

- <https://adr.github.io/>
- <https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions>
- <https://git-scm.com/docs/git-log>
- <https://git-scm.com/docs/git-interpret-trailers>

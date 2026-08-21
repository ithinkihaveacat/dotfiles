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
  (serving as project manifest), `STATUS.md` (operational projection), and
  `tasks/` containing granular task records. `PLAN.md`, `decisions/`,
  `references/`, and `experiments/` remain optional.
- **Scale 2 (Multi-Month Initiative):** Extends Scale 1 with explicit roadmap
  sequencing in `PLAN.md`, formal Nygard-style Architecture Decision Records in
  `decisions/*.md`, supporting context in `references/`, and candidate
  prototypes or evaluation suites in `experiments/`.

## Repository Terminology & Boundaries

A **control repository** (interchangeably called a *control repo*, *taskgo
tracker*, *tracker repository*, or *project tracker*) manages initiatives,
tasks, decisions, and exploratory assets across one or more external **artifact
repositories**:

- **Control Repository (`projects/`):** Houses private task tracking
  (`STATUS.md`, `tasks/`), roadmaps (`PLAN.md`), Architecture Decision Records
  (`decisions/`), supporting context (`references/`), and project-scoped
  exploratory research (`experiments/` holding disposable prototypes, competing
  optimization variants, synthetic benchmark fixtures, and raw trial
  logs/telemetry).
- **Artifact Repositories (e.g. `dotfiles`, product codebases):** House
  permanent production code, reusable libraries, shipping CLIs, and
  contract/regression test suites (`test-*`). Commits in artifact repositories
  must remain strictly free of private control repo metadata.

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

## Unified AuditEngine Architecture (`doctor` & `fix`)

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

## Command Vocabulary

Commands follow the fixed `tool [verb] [noun]` structure with clean,
unhyphenated verbs:

- `taskgo id`: Allocate unique `TASK-XXXXX` identifier.
- `taskgo create PROJECT TITLE [--status STATE] [--no-commit] [--dry-run]`:
  Create a structured task record.
- `taskgo list [PROJECT] [--state STATE] [--json]`: List tasks in tabular or
  JSON format.
- `taskgo status [PROJECT] [--json]`: Display operational status or
  multi-project summary.
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

## References

- <https://adr.github.io/>
- <https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions>
- <https://git-scm.com/docs/git-log>
- <https://git-scm.com/docs/git-interpret-trailers>

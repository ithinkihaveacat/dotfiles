---
name: taskgo
description: >-
  Maintains a private Git-backed personal project and task control repository
  using concise current Markdown, derived Git history, ADRs, and status synchronization.
  Use when tracking tasks, updating project status (STATUS.md), managing ADRs,
  synchronizing tracker state, delegating tasks to external agents, or generating
  human-facing activity reports (weekly/monthly/quarterly).
compatibility: Requires Python 3.11+ (via uv) and git.
---

# taskgo

taskgo manages a private **control repository** spanning multiple technical
projects. Humans read current Markdown; agents edit it, operate Git, reconstruct
history, and generate summaries.

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
   checkpoint commits (`create`, `checkpoint`, `fix`). Never rewrite artifact
   history.
1. **No Administrative Metadata:** Do not invent metadata fields like `created`,
   `updated`, or `blocked_since` in YAML frontmatter. Git owns administrative
   history. Do not duplicate `Project:`, `Task:`, or `Event:` trailers.

## Tasks

IDs are globally unique `TASK-XXXXX` (five hex digits). Task files are
`tasks/TASK-XXXXX-<slug>.md`. Pass `--slug` (max 32 chars) when creating tasks
if the title is long.

Preferred states: `todo`, `in-progress`, `blocked`, `done`, `cancelled`.

### Dependencies

A task may declare what is holding it up with an optional `blocked_by` list of
task IDs:

```yaml
blocked_by: [TASK-1627D]
```

`status: blocked` is set manually. `blocked_by` is read-only scheduling data.
Record the edge on the task that is *held*, never on the blocker; otherwise a
new dependency requires editing an unrelated, already `done` task.

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

**Problem:** (optional) Mechanics of current problem, not consequences.
**Cost:** (required if Problem is present) Currency, consequence, and who absorbs it.
**Goal:** (required) What should be true once done (requirements).
**Criteria:** (required where definable) Observable end condition.
**Sketch:** (optional) Early thinking/pointers.
**Constraints:** (optional) Boundaries on the solution.
```

### Completed Task Template

```markdown
---
id: TASK-3A91F
status: done
conversations:
  - <agent>://<conversation-id>
---

# Title as imperative verb phrase

## Outcome
Summary of what shipped, external canonical web URLs, terminal verdicts, quantitative deltas, and Cost updates.

## Findings
Key technical discoveries, trade-offs, reproduction steps, downstream momentum.

## Next
Immediate follow-up actions.
```

## Decisions & STATUS.md

- **Decisions:** Lightweight Nygard-style ADRs (`decisions/*.md`).
- **STATUS.md:** The self-contained operational projection.
  - `## Summary`: Human/agent prose for current situation and active session
    citation (`[<conversation-id>](<agent>://<conversation-id>)`).
  - `<!-- taskgo:begin/end -->`: Mechanically maintained via `taskgo sync`.
  - `## Next`: Immediate next actions.

## Agent Workflow

See **[Agent Workflows & Handoff](references/workflows.md)** for detailed
protocols on commit authority, session attribution, External Agent Handoff, and
Agent Dispatch.

- **Before work:** read `AGENTS.md`, project `README.md`, `STATUS.md`, and
  `PLAN.md`.
- **After work:** update files, task frontmatter (`conversations`), and
  `STATUS.md` prose (`Summary` & `Next`). Run `taskgo sync` and `taskgo doctor`.
  Optionally commit using `taskgo checkpoint`. Ensure the project is left in a
  strict **handoff-ready** state.

### Harbor Task Execution

See **[Harbor Lifecycle](references/harbor.md)** for delegating tasks to
unattended, isolated agents (`taskgo harbor prepare / run / verify`).

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
taskgo create PROJECT TITLE [--slug SLUG] [--conv ID] [--status STATE] [--problem TEXT] [--goal TEXT] [--criteria TEXT] [--sketch TEXT] [--no-commit] [--dry-run]
taskgo update TASK_ID [--slug SLUG] [--conv ID] [--status STATE] [--title TITLE] [--problem TEXT] [--goal TEXT] [--criteria TEXT] [--sketch TEXT] [--outcome TEXT] [--findings TEXT] [--next TEXT]
taskgo list [PROJECT] [--state STATE] [--json]
taskgo status [PROJECT] [--json]
taskgo dispatch TASK_ID
taskgo sync [PROJECT]
taskgo doctor [PROJECT]
taskgo fix [PROJECT] [--dry-run] [--no-commit]
taskgo history PATH_OR_TASK_ID [FIELD]
taskgo checkpoint TASK_ID SUBJECT [--conv ID] [--all] [--path PATH]... [--body TEXT] [--ref REF]...
taskgo commit SUBJECT [--conv ID] [--body TEXT] [--ref REF]...
taskgo harbor prepare [TASK_ID] -o DIR [--instruction TEXT] [--workspace DIR] [--skills SKILL...] [--dry-run]
taskgo harbor run [TARGET]
taskgo harbor verify --base-file BASE --candidate-file CAND -o DIR [--tool-cmd CMD] [--json]
```

- `create`: Allocate ID, write record, sync STATUS, optionally commit.
- `update`: Edit task in-place. If using `--slug`, the rename is left
  uncommitted; commit with `checkpoint --all` to stage both old and new paths.
- `fix`: Auto-heal IDs, normalize status aliases, generate STATUS, and commit
  repairs by default.
- `checkpoint`: Safe automatic-commit path requiring
  `taskgo:allow-local-commits`. Enforces 50-char subject limits.

## Reference Material

- **[Command Index](references/command-index.md)** — Detailed subcommand
  synopsis and options
- **[Model & Architecture](references/model.md)**
- **[Agent Workflows & Handoff](references/workflows.md)**
- **[Harbor Lifecycle](references/harbor.md)**
- **[Activity Reports](references/activity-reports.md)**

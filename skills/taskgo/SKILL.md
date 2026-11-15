---
name: taskgo
description: >-
  Tracks projects and tasks in a private Git-backed control repository of
  Markdown records (STATUS.md, tasks/TASK-XXXXX-*.md, decisions/, INBOX.md)
  through the taskgo CLI or MCP tools. Use when the user wants to add, start,
  update, block, close, or hand off a task; asks what to work on next or what is
  blocked or due; mentions a TASK-XXXXX ID, a tracked project, or the control
  repo; records a decision (ADR); or wants a weekly, monthly, or quarterly
  activity report from tracked work. Use at the start and end of work on a
  tracked project even if taskgo is not named.
compatibility: Requires Python 3.11+ (via uv) and git.
---

# taskgo

taskgo keeps a private **control repository** of projects and tasks in Markdown.

Run `taskgo <command>` if it is on `$PATH`, or
`<skill-dir>/scripts/taskgo <command>`, where `<skill-dir>` holds this
`SKILL.md`. The root is `-R DIR` (before the command), else `$TASKGO_ROOT`, else
`~/.projects`; `taskgo root` prints it. When the control repository is not your
workspace and your harness has the taskgo MCP tools, you may use those instead.

## Core Rules

1. **Current truth.** Files describe what is true now; Git holds the history.
   Rewrite files to the new state; never append journal entries.
1. **Data segregation.** Tracker notes, `Conversation:` trailers, and session
   links stay in the control repository. Never put them in artifact repository
   files, commits, or PRs.
1. **Links.** Relative Markdown links inside the tracker (no `file://`), `~/...`
   for local checkouts, canonical `https://` URLs elsewhere.
1. **No invented metadata.** No `created`, `updated`, or `blocked_since`
   frontmatter; no `Project:` or `Task:` trailers.
1. **One owner per fact.** Link to the
   [owner](references/model.md#where-knowledge-lives) instead of copying.
1. **Local policy.** The root `AGENTS.md` holds a taskgo-managed block and,
   outside it, this repository's own rules (time zone, report format,
   environment, data care). Follow both.
1. **Guarded commits.** That block authorises `create`, `checkpoint`, `commit`,
   and `fix` to commit. Changes across projects need a plain `git commit`; see
   [Workflows](references/workflows.md#plain-git-commit).

## Tasks

IDs are `TASK-XXXXX` (five hex digits), in `tasks/TASK-XXXXX-<slug>.md`. Pass
`--slug` (32 characters at most) when the title is long. States are `todo`,
`in-progress`, `blocked`, `done`, and `cancelled`.

Use only the labels and sections in these templates. Do not add one-off headings
or bold labels; put that text under the nearest section.

### Open Task Template

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

Add Cost when it helps set priority. An `in-progress` or `blocked` task that
spans sessions may add `## Findings` and `## Next` for the next agent.

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

**On completion,** keep Problem, Cost, Goal, and Criteria as written. Delete
Sketch and Constraints (`update` cannot; use `taskgo edit` or your file tools):
Outcome and Findings replace them. Marking a task done needs `--outcome`; the
CLI refuses without it.

## STATUS.md

- `## Summary`: where the project stands now, for a reader arriving cold. Say
  what it is, its current state, what is in flight, and what blocks it, in a few
  sentences (about 100 words). Rewrite it whole each time. Delete sentences
  about finished work: done tasks and Git history keep that. Link to tasks
  rather than restating them. Never narrate versions or sessions. `doctor` notes
  a Summary over 1,200 characters.

  Bad: "Done so far: parser, cache. The server now streams. The server now
  retries." Good: "The compiler streams manifests; cold start is the open
  question ([TASK-3A91F](tasks/TASK-3A91F-cold-start.md)). Nothing is blocked."

- The block between `<!-- taskgo:begin -->` and `<!-- taskgo:end -->` is
  generated (in-progress, blocked, due-soon tasks, active decisions, counts). Do
  not edit it by hand; `taskgo sync` and the commit commands refresh it.

- `## Next`: the next few concrete actions, not a backlog.

Sessions are recorded in commit trailers and each task's `conversations`, not in
the Summary.

## Start and Finish

**Before work:**

1. Run `taskgo handoff <project|TASK_ID>`. Read the root `AGENTS.md`, the
   project `README.md`, and the files the note names. Task handoff accepts only
   unfinished work; to investigate a completed or cancelled task, hand off its
   project and read the task record directly.
1. Reuse the project's skills already available in your environment. Load
   missing ones through a supported discovery/loading mechanism, or locate and
   read their `SKILL.md` files directly. If the optional `skill` CLI is
   installed and supports session scope in your launcher, you can use
   `taskgo skills <project> | skill --scope session add -`. Its
   `skill resolve <NAME>` command may also help locate local skills. Neither
   command is required by taskgo.
1. For work that may span sessions, mark the task `in-progress` and commit that
   first (`taskgo update TASK --status in-progress`, then
   `taskgo checkpoint TASK "chore(<project>): start …"`). A small task finished
   in one go may go straight from `todo` to `done`.

**After work:**

1. Update the task: `--findings` and `--next` while open, or `--status done`
   with `--outcome` (a verdict against each criterion) when finished.

1. Fold durable findings into `<project>/references/`, or into the artifact
   repository or skill that owns them, and link them from the task. Change the
   project `README.md` only if its identity, map, or rules changed, and
   `PLAN.md` only if the direction changed.

1. Rewrite the Summary and Next of `<project>/STATUS.md` with `taskgo edit` or
   your file tools.

1. Commit the task change and the `STATUS.md` prose together, in one commit:

   ```bash
   taskgo checkpoint TASK-3A91F "feat(compiler): stream manifests" --all \
     --ref compiler@1a2b3c4
   ```

   `checkpoint` syncs the generated block, formats the records, records the
   session, and refuses while `taskgo doctor` reports problems in the files it
   commits; other findings in the project are counted, not refused. Subjects are
   Conventional Commits of at most 50 characters, prefix included.

1. Leave the project [handoff-ready](references/workflows.md#handoff-ready).

## Common Commands

| Command                                        | Use                                                  |
| ---------------------------------------------- | ---------------------------------------------------- |
| `taskgo handoff PROJECT\|TASK_ID`              | Onboarding note: files to read, skills to activate   |
| `taskgo status [PROJECT\|TASK_ID]`             | Current state of a task or project                   |
| `taskgo list [PROJECT] --state ready`          | Tasks ready to start                                 |
| `taskgo create PROJECT TITLE --goal …`         | New task (commits)                                   |
| `taskgo update TASK --findings … --next …`     | Change state (`--status`) or sections in place       |
| `taskgo update TASK --status done --outcome …` | Close a task                                         |
| `taskgo edit PATH --old … --new …`             | Exact-text edit; validates and formats records       |
| `taskgo sync [PROJECT]`                        | Refresh generated `STATUS.md` blocks                 |
| `taskgo doctor [PROJECT]`                      | Read-only checks; non-zero on problems               |
| `taskgo checkpoint TASK SUBJECT`               | Guarded commit for one task (`commit`: staged files) |

Everything else, including every option, is in
[the command index](references/command-index.md) and `taskgo <command> --help`.
`read`, `search`, `edit`, and `apply` mirror the MCP tools for agents without a
checkout; with a checkout, your own file tools are fine for reading.

## Scheduling

Most tasks need none of `blocked_by` (tasks holding this one; set it on the task
that is held), `wait_for` (a date, issue, person, or condition), `due`, or
`stale_after`. Read [Scheduling Fields](references/model.md#scheduling-fields)
before you set them.

## Reference Material

| Read                                               | When                                                                             |
| -------------------------------------------------- | -------------------------------------------------------------------------------- |
| [Command index](references/command-index.md)       | You need a command or option not shown above                                     |
| [Model](references/model.md)                       | Placing a file or fact, writing a project README or ADR, setting schedule fields |
| [Workflows](references/workflows.md)               | Plain `git` commits (renaming or removing a project), handoff, tracing sessions  |
| [Change sets](references/change-sets.md)           | Writing a file for `apply`, or the exact `edit` and MCP write rules              |
| [Activity reports](references/activity-reports.md) | Writing a weekly, monthly, or quarterly report                                   |
| [Task export](references/export.md)                | Handing a task to a worker without the control repository                        |
| [MCP server](references/mcp.md)                    | Running, debugging, or changing `taskgo mcp`                                     |

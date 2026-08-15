---
name: taskgo
description: Maintain a private Git-backed personal project/task control repo using concise current Markdown, derived Git history, ADRs, status synchronization, and external artifact references.
---

# taskgo

Use for one user's private control repo spanning multiple technical projects and artifacts. Humans mainly read current Markdown; agents mainly edit it, operate Git, reconstruct history, and generate summaries.

## Model

**HEAD is optimized for resuming work; Git history explains how HEAD came to be.** Rewritten current state keeps routine agent context bounded; do not append journals just to retain history.

```text
AGENTS.md
INBOX.md                  # zero-ceremony capture; no schema
projects/<id>/
  PROJECT.md              # identity, scope, constraints, artifacts
  STATUS.md               # current human view + generated task block
  PLAN.md                 # intended route forward
  tasks/*.md              # stable task records
  decisions/*.md          # ADRs
```

### Invariants

1. `HEAD` describes current belief; currently applicable knowledge belongs in the tree.
2. Git owns administrative history. Avoid routine `created`, `updated`, `blocked_since`, etc. Domain dates are fine. `reviewed:` is fine when deliberate review freshness matters.
3. Derive lifecycle transitions from historical frontmatter values. Do not duplicate `Project:`, `Task:`, or `Event:` trailers.
4. Commit prose preserves conclusions/reasoning that state and diffs cannot. `Ref:` trailers may link external revisions, PRs, docs, deployments, etc.
5. Metadata is optional enrichment. Missing/old fields degrade automation, not validity.
6. Keep semantic object paths stable normally. Renaming/reconciliation is allowed for conflicts or genuine corrections.
7. Canonical history is append-oriented. Rewrite unpublished work if useful; normally correct integrated history with new commits.
8. Private tracker information must not implicitly flow into linked public/shared artifacts.
9. `STATUS.md` is a projection: generated task state must match tasks; prose requires agent semantic review.
10. Graceful degradation beats ceremony. Humans may edit useful Markdown imperfectly.

## Tasks

IDs are exactly `TASK-XXXXX`, with five uppercase hexadecimal digits (`0-9`, `A-F`), e.g. `TASK-3A91F`. They should be globally unique within the control repo. Use random IDs, not a counter:

```bash
scripts/taskgo id
scripts/taskgo new-task PROJECT "Diagnose intermittent disconnects"
```

Preferred task form:

```markdown
---
id: TASK-3A91F
status: in-progress
---

# Diagnose intermittent disconnects

## Outcome
...
## Findings
...
## Next
...
```

Preferred states: `todo`, `in-progress`, `blocked`, `done`, `cancelled`. Unknown/missing values remain readable but should be reported.

## Decisions

Use lightweight Nygard-style ADRs with `Status`, `Context`, `Decision`, `Consequences`. Prefer `proposed` -> `accepted`. When an accepted decision changes, preserve it, mark it `superseded`, and refer to the replacement ADR. Do not rewrite accepted rationale merely because the decision later changed; corrections and merge reconciliation are allowed.

## STATUS.md

Human/agent prose such as `## Summary` and `## Next` stays concise. `taskgo` owns only:

```markdown
<!-- taskgo:begin -->
## Task snapshot
...
<!-- taskgo:end -->
```

Run `scripts/taskgo sync-status PROJECT`; the commit helper also synchronizes the affected project. `doctor` catches mechanical drift, but the invoking agent must compare Summary/Next with current tasks, plan, decisions, and recent work.

## Agent workflow

Before work: read root `AGENTS.md`, then project `PROJECT.md`, `STATUS.md`, relevant tasks/ADRs, and `PLAN.md` when direction matters. Inspect linked artifact repos under their own instructions.

After meaningful work:

1. Rewrite specific files to the new current truth.
2. Update STATUS prose if the human-facing situation changed; PLAN only if intended direction changed.
3. Run `scripts/taskgo doctor PROJECT` and perform its semantic review.
4. Commit a coherent transition when practical. Subject = what became true, not what file changed.

Examples:

```text
home-automation/TASK-3A91F: rule out coordinator firmware
home-automation/TASK-3A91F: block testing pending replacement router
compiler: defer parser migration until v3
```

Use commit bodies for useful reasoning not recoverable from state/diff. Add repeatable `Ref:` trailers for non-derivable external relationships.

## CLI

Requires Bash + Git; it remains a thin layer over ordinary files/history:

```text
taskgo id
taskgo new-task PROJECT TITLE [--status STATE]
taskgo tasks [PROJECT] [--state STATE]
taskgo status [PROJECT]
taskgo sync-status PROJECT
taskgo doctor [PROJECT]
taskgo history PATH_OR_TASK_ID [FIELD]
taskgo commit SUBJECT [--body TEXT] [--ref REF]...
```

`history` compares a frontmatter field (default `status`) across historical blobs. `doctor` performs mechanical checks and prints a semantic checklist; **the agent invoking the skill is the semantic part of doctor**.

## Concurrency

Prefer separate branches/worktrees. Random globally checked IDs avoid a shared allocator. Resolve merges by reconciling files to one intended current state; STATUS may be rewritten freely. Stable paths and accepted ADR text are defaults, not reasons to preserve a broken merge. Avoid squash integration when intermediate state transitions matter, because squashing can erase reconstructible states.

See `references/model.md` for rationale and prototype caveats.

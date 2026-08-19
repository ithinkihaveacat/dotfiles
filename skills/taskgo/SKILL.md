---
name: taskgo
description: >-
  Maintain a private Git-backed personal project/task control repo using concise
  current Markdown, derived Git history, ADRs, status synchronization, and
  external artifact references.
---

# taskgo

Use for one user's private control repo spanning multiple technical projects and
artifacts. Humans mainly read current Markdown; agents mainly edit it, operate
Git, reconstruct history, and generate summaries.

## Model

**HEAD is optimized for resuming work; Git history explains how HEAD came to
be.** Rewritten current state keeps routine agent context bounded; do not append
journals just to retain history.

```text
AGENTS.md                  # taskgo declaration + repository instructions
INBOX.md                  # zero-ceremony capture; no schema
<id>/
  README.md               # identity, scope, constraints, artifacts (or PROJECT.md)
  STATUS.md               # current human view + generated task block
  PLAN.md                 # intended route forward (optional)
  tasks/*.md              # stable task records
  decisions/*.md          # ADRs (optional)
  docs/*.md               # reference docs (optional)
```

The root `AGENTS.md` must state that the repository follows taskgo and include
the canonical specification URL:
<https://github.com/ithinkihaveacat/dotfiles/tree/master/skills/taskgo>. This
ensures agents can discover the governing process from the repository itself.
`doctor` reports a missing declaration or URL.

A control repo may grant standing authority for guarded local checkpoint commits
by adding this marker to its committed root `AGENTS.md`:

```markdown
<!-- taskgo:allow-local-commits -->
```

This authority applies only to `taskgo create`, `taskgo checkpoint`, and
`taskgo fix` operations in that control repo. It never authorizes commits in
linked artifact repos, pushes, amendments, rebases, or other history rewriting.

### Invariants

1. `HEAD` describes current belief; currently applicable knowledge belongs in
   the tree.
1. Git owns administrative history. Avoid routine `created`, `updated`,
   `blocked_since`, etc. Domain dates are fine. `reviewed:` is fine when
   deliberate review freshness matters.
1. Derive lifecycle transitions from historical frontmatter values. Do not
   duplicate `Project:`, `Task:`, or `Event:` trailers.
1. Commit prose preserves conclusions/reasoning that state and diffs cannot.
   `Ref:` trailers may link external revisions, PRs, docs, deployments, etc.
1. Metadata is optional enrichment. Missing/old fields degrade automation, not
   validity.
1. Keep semantic object paths stable normally. Renaming/reconciliation is
   allowed for conflicts or genuine corrections.
1. Canonical history is append-oriented. Rewrite unpublished work if useful;
   normally correct integrated history with new commits.
1. Private tracker information must not implicitly flow into linked
   public/shared artifacts. `Conversation:` trailers and `conversation://` URLs
   belong strictly in control repository metadata (`STATUS.md`, task
   frontmatter, and control repo commits); they must never be added to commits
   in linked artifact repositories. Artifact path references prefer
   `$HOME`-relative form (`~/...`) to remain portable across machines (list
   multiple checkout paths when locations vary per environment).
1. `STATUS.md` is the self-contained projection of current operational state:
   reading `STATUS.md` directly answers status, recent progress, and immediate
   next steps without traversing individual task files. Generated task state
   must match tasks; prose requires agent semantic review.
1. `taskgo` tracks work forward from adoption. Historical context predating
   tracker setup remains in external artifact repositories and is not
   retroactively backfilled.
1. Graceful degradation beats ceremony. Humans may edit useful Markdown
   imperfectly.

## Tasks

IDs are exactly `TASK-XXXXX`, with five uppercase hexadecimal digits (`0-9`,
`A-F`), e.g. `TASK-3A91F`. They should be globally unique within the control
repo. Use random IDs, not a counter:

```bash
scripts/taskgo id
scripts/taskgo create PROJECT "Diagnose intermittent disconnects"
```

Preferred states: `todo`, `in-progress`, `blocked`, `done`, `cancelled`.
Unknown/missing values remain readable but should be reported.

### Planning & In-Progress Task Template

For new and in-flight tasks, use bold run-in labels to capture the brief for
future implementers without hardening into a rigid step-by-step plan:

```markdown
---
id: TASK-3A91F
status: todo
conversations:
  - conversation://<conversation-id>
---

# Title as imperative verb phrase

**Problem:** (optional) How the current system behaves and why that is a
problem — the mechanics, not just the motivation.

**Goal:** (required) The outcome — what should be true once the item is done,
stated as requirements rather than implementation.

**Criteria:** (required where definable) The end condition — an observable,
checkable state (e.g. metrics, test outputs, specific behavior).

**Sketch:** (optional) Early thinking on a candidate approach, research
findings, pointers to relevant code, or approaches ruled out.

**Constraints:** (optional) Boundaries on the solution: simplest thing that
works, no new dependencies, must keep existing APIs, etc.
```

### Completed Task Template

Once a task is completed, rewrite the body as a concise past-tense record of
what was implemented and discovered:

```markdown
---
id: TASK-3A91F
status: done
conversations:
  - conversation://<conversation-id>
---

# Title as imperative verb phrase

## Outcome
Summary of what shipped, where it lives (commits, files, endpoints), and
outcomes. Completed in [<conversation-id>](conversation://<conversation-id>).

## Findings
Key technical discoveries, trade-offs, reproduction steps, or unexpected
behavior.

## Next
Immediate follow-up actions or subsequent tasks.
```

## Decisions

Use lightweight Nygard-style ADRs with `Status`, `Context`, `Decision`,
`Consequences`. Prefer `proposed` -> `accepted`. When an accepted decision
changes, preserve it, mark it `superseded`, and refer to the replacement ADR. Do
not rewrite accepted rationale merely because the decision later changed;
corrections and merge reconciliation are allowed.

## STATUS.md

`STATUS.md` is the self-contained operational projection for humans and agents.
Reading it directly (or running `scripts/taskgo status PROJECT`) answers project
status, recent outcomes, and immediate direction without inspecting individual
task records.

Structure:

- `## Summary`: Human/agent prose describing the current situation and the key
  outcome/findings of the most recently completed task(s). The active session
  must be cited using full identifier syntax:
  `Active session ([<conversation-id>](conversation://<conversation-id>)): ...`.
  "Conversation ID" refers to the globally unique session, conversation, or
  thread identifier used by the host agent platform (e.g. at least 16
  characters). Do not abbreviate the identifier in the link text or target, and
  never invent fake placeholder IDs. Replace older transition notes rather than
  accumulating a journal.
- `<!-- taskgo:begin -->` to `<!-- taskgo:end -->`: Mechanically maintained
  snapshot (`In progress`, `Blocked`, task counts).
- `## Next`: Immediate next actions (the active horizon of `PLAN.md`).

Keep prose complementary to the generated snapshot: do not repeat task counts or
generic lifecycle facts such as "no task is in progress." When changing a task
status, update its frontmatter and any affected Summary, Next, or PLAN prose as
one logical transition before running `sync`; never leave a new snapshot beside
prose that describes the previous state.

Run `scripts/taskgo sync PROJECT`; the commit helper also synchronizes the
affected project. `doctor` catches mechanical drift, but the invoking agent must
compare Summary/Next with current tasks, plan, decisions, and recent work.

## Agent workflow

Querying status: to answer questions about project status, recent
accomplishments, or next steps, read `STATUS.md` (or run
`scripts/taskgo status PROJECT`). Inspect `PLAN.md`, individual `tasks/`, or Git
history only if deeper detail or historical transitions are requested.

Before work: read root `AGENTS.md`, then project `README.md` (or `PROJECT.md`),
`STATUS.md`, relevant tasks/ADRs, and `PLAN.md` when direction matters. Inspect
linked artifact repos under their own instructions.

Commit authority, before starting (when reconstructible lifecycle history
matters):

1. Committed `taskgo:allow-local-commits` marker present -> authorized for
   guarded `create`, `checkpoint`, and `fix` operations in this control repo
   only.
1. Authorized: commit a meaningful `in-progress` transition before artifact work
   that may span sessions; commit completion with `Ref:` trailers for linked
   artifact commits. A small task completed atomically may go directly `todo` ->
   `done`. Pass `--conv <conversation-id>` or verify `conversations` frontmatter
   and `STATUS.md` cite the full active session identifier.
1. Not authorized: keep changes uncommitted; state clearly that intermediate
   transitions will not be retained. Never create retrospective state commits
   that did not reflect reality at the time.

After meaningful work:

1. Rewrite specific files to the new current truth.
1. Update affected task record(s) (e.g. mark `done` with `## Outcome` and
   `## Findings`, recording
   `[<conversation-id>](conversation://<conversation-id>)`).
1. Update `STATUS.md` prose (`## Summary` captures the new baseline, active
   session link, and recent outcome; `## Next` reflects immediate next actions);
   `PLAN.md` only if intended direction changed.
1. Run `scripts/taskgo sync PROJECT` after the semantic edits are coherent.
1. Run `scripts/taskgo doctor PROJECT` and perform its semantic review.
1. Commit a coherent transition when practical. Use `checkpoint` with `--conv`
   when standing authority is present. Subject = what became true, not what file
   changed.

Before leaving or completing a task, double-check:

1. Handoff: state, findings, decisions, and full session/conversation IDs
   (`[<conversation-id>](conversation://<conversation-id>)`) needed to resume
   are written into the task/STATUS/PLAN, not left only in conversation.
1. Consistency: tracker claims match actual artifact-repo state (e.g. a task is
   not `done` while its artifact-repo commit remains uncommitted).

Examples:

```text
home-automation/TASK-3A91F: rule out coordinator firmware
home-automation/TASK-3A91F: block testing pending replacement router
compiler: defer parser migration until v3
```

Use commit bodies for useful reasoning not recoverable from state/diff. Add
repeatable `Ref:` trailers for non-derivable external relationships and
`Conversation:` trailers for session traceability (in control repo commits only;
never in external artifact repos).

## CLI

Requires Python 3.11+ (via `uv`) and Git; it remains a thin layer over ordinary
files/history:

```text
taskgo id
taskgo create PROJECT TITLE [--conv ID] [--status STATE] [--problem TEXT] [--goal TEXT] [--criteria TEXT] [--sketch TEXT] [--no-commit] [--dry-run]
taskgo update TASK_ID [--conv ID] [--status STATE] [--title TITLE] [--problem TEXT] [--goal TEXT] [--criteria TEXT] [--sketch TEXT] [--outcome TEXT] [--findings TEXT] [--next TEXT]
taskgo list [PROJECT] [--state STATE] [--json]
taskgo status [PROJECT] [--json]
taskgo sync [PROJECT]
taskgo doctor [PROJECT]
taskgo fix [PROJECT] [--dry-run] [--no-commit]
taskgo history PATH_OR_TASK_ID [FIELD]
taskgo checkpoint TASK_ID SUBJECT [--conv ID] [--all] [--path PATH]... [--body TEXT] [--ref REF]...
taskgo commit SUBJECT [--conv ID] [--body TEXT] [--ref REF]...
```

`create` is the atomic task creation command: it allocates a unique ID, writes
the initial task record, synchronizes `STATUS.md`, and when the
`taskgo:allow-local-commits` marker is present, commits the transition
automatically. Use `--no-commit` to keep the created task uncommitted in the
working tree, or `--dry-run` to preview the task path without creating files.

`history` compares a frontmatter field (default `status`) across historical
blobs. `doctor` performs strictly read-only mechanical checks and prints a
semantic checklist.

`fix` is the auto-healing command: it assigns missing IDs, normalizes status
aliases, creates missing scaffolding, and regenerates `STATUS.md`. By default,
`fix` commits the repairs to maintain tracker integrity and outputs
machine-readable commit metadata (`COMMIT_SHA: <hash>`) on stdout. Use
`--dry-run` to preview changes without modifying files or committing, or
`--no-commit` to apply repairs on disk without committing.

`checkpoint` is the safe automatic-commit path. It requires the authorization
marker in the committed root `AGENTS.md`, an initially empty index, a target
task ID, and at least one modified file in the project. It always includes that
task and its synchronized `STATUS.md`; use repeatable `--path` options for other
changed files in the same project, such as `PLAN.md`. It refuses unlisted
changes in that project with actionable `--path` hints, and never stages files
outside it. Unrelated changes elsewhere in the control repo remain unstaged. The
command validates the project before making one local commit and does not
contact a remote.

## Concurrency

Prefer separate branches/worktrees. Random globally checked IDs avoid a shared
allocator. Resolve merges by reconciling files to one intended current state;
STATUS may be rewritten freely. Stable paths and accepted ADR text are defaults,
not reasons to preserve a broken merge. Avoid squash integration when
intermediate state transitions matter, because squashing can erase
reconstructible states.

See `references/model.md` for rationale and prototype caveats.

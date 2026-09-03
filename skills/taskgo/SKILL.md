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

Use for one user's private **control repository** (also called the **control
repo**, **taskgo tracker**, or **project tracker**) spanning multiple technical
projects and external artifacts. Humans mainly read current Markdown; agents
mainly edit it, operate Git, reconstruct history, and generate summaries.

## Model

**HEAD is optimized for resuming work; Git history explains how HEAD came to
be.** Rewritten current state keeps routine agent context bounded; do not append
journals just to retain history.

```text
AGENTS.md                  # taskgo declaration + repository instructions
INBOX.md                  # zero-ceremony capture; no schema
<id>/
  README.md               # identity, scope, domain/stakeholders, constraints, artifacts (or PROJECT.md)
  STATUS.md               # current human view + generated task block
  PLAN.md                 # intended route forward (optional)
  tasks/*.md              # stable task records
  decisions/*.md          # ADRs (optional)
  references/*            # supporting context, schemas, design tokens, external docs (optional)
  bugreports/*            # captured bug reports, reproduction logs, triage traces (optional)
  scripts/*               # automation, audit harnesses, pipelines, report generators (optional)
  data/*                  # input datasets, package lists, static fixtures (optional)
  results/*               # benchmark telemetry, run logs, audit outputs (optional)
  dist/*                  # static dashboards, deployable bundles, HTML reports (optional)
```

The root `AGENTS.md` explicitly states that the repository follows taskgo and
includes the canonical specification URL:
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
   in linked artifact repositories. Artifact repositories host permanent
   production code, tools, and regression test suites; project-scoped working
   scripts, datasets, and run results belong in the control repo alongside their
   project. Very large artifacts (such as cloned Git repositories or heavy
   binary test data) should not be checked into Git; reference them or download
   on demand. Artifact path references prefer `$HOME`-relative form (`~/...`) to
   remain portable across machines (list multiple checkout paths when locations
   vary per environment).
1. `STATUS.md` is the self-contained projection of current operational state:
   reading `STATUS.md` directly answers status, recent progress, and immediate
   next steps without traversing individual task files. Synchronize generated
   task state with current tasks; prose requires agent semantic review.
1. `taskgo` tracks work forward from adoption. Historical context predating
   tracker setup remains in external artifact repositories and is not
   retroactively backfilled.
1. Graceful degradation beats ceremony. Humans may edit useful Markdown
   imperfectly.

## Tool Execution

`taskgo` is bundled in `scripts/taskgo` within this skill directory. Commands
operate on a fixed control repository root, resolved in this order:

1. `--root DIR` / `-R DIR` (must appear before the command),
1. the `TASKGO_ROOT` environment variable,
1. the default `~/.projects`.

The root must be an existing Git repository; resolution never depends on the
current working directory, so commands work identically from any workspace. Run
`taskgo root` to print the resolved root (for raw Git operations or direct file
edits), or `taskgo doctor` to see it with the source that selected it. To
execute the tool:

1. **Optimal (`$PATH`):** If `taskgo` is installed on your system `$PATH`,
   invoke it directly: `taskgo <command>`.
1. **Dynamic anchor:** Otherwise, execute the bundled script relative to the
   directory containing this `SKILL.md`: `<skill-dir>/scripts/taskgo <command>`.

## Tasks

IDs are exactly `TASK-XXXXX`, with five uppercase hexadecimal digits (`0-9`,
`A-F`), e.g. `TASK-3A91F`. They should be globally unique within the control
repo. Use random IDs, not a counter:

```bash
<skill-dir>/scripts/taskgo id
<skill-dir>/scripts/taskgo create PROJECT "Diagnose intermittent disconnects" --slug disconnects
```

Task files are named `TASK-XXXXX-<slug>.md`. The slug is a filename mnemonic,
not the title: `create` derives one from `TITLE` when `--slug` is omitted, but a
derived slug keeps the *leading* words of the title, which are rarely the
distinguishing ones ("Generate readable task filename slugs with clean length
limits" derives `generate-readable-task-filename`, where `filename-slugs` is
wanted). Pass `--slug` (at most 32 characters after normalization) whenever the
title runs longer than a few words; `create` warns when it had to shorten a
derived slug. Nothing resolves tasks by filename — IDs and titles carry that —
so slugs exist purely for humans reading `tasks/`, `git log`, and fuzzy finders.
Rename an existing task file with `update --slug`.

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

*(Tip: Front-load external stakeholder or impact context where applicable, e.g.
"Unblock Partner X via token parser refactor" rather than bare "Refactor token parser".)*

**Problem:** (optional) How the current system behaves and why that is a
problem — the mechanics, not just the motivation. Leave the consequences to
Cost.

**Cost:** (required whenever Problem is present) What leaving this undone
costs — never the effort to fix it. Name the currency, then the concrete
consequence and who absorbs it. Correctness, ergonomics, performance,
maintenance and reputation cover most of it; invent a currency where one of
those would misname the harm, and do not force a task into a listed one to be
consistent with other tasks. A magnitude word is fine when evidence follows it
("Low. Confirmed on 2 of ~107 listings"); a bare "High" or "Critical" is not.
Say whether the cost is paid loudly or silently, since a fault that announces
itself is cheaper than one that does not.

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
Summary of what shipped, where it lives, and explicit verdicts. Completed in
[<conversation-id>](conversation://<conversation-id>).
- **External deliverables & links:** Cite direct canonical URLs (PRs, CLs, issue
  tickets, published docs/dashboards) alongside any local repository commits.
- **Triage verdicts:** When triaging claims or defects, record an explicit
  terminal verdict (e.g. `Verified Bug`, `Tooling Discrepancy`, `Working As Intended (WAI)`,
  `Invalid/Disproven`) to prevent ambiguous summarization.
- **Quantitative deltas:** For performance, optimization, or scale tasks, record
  numerical metrics (e.g. `reduced latency from 400ms to 45ms`) rather than
  qualitative claims.
Where the task declared a Cost, say whether it is now gone, reduced, or still
being paid — the last is a legitimate outcome and worth stating plainly.

## Findings
Key technical discoveries, trade-offs, reproduction steps, or unexpected
behavior.
- **Downstream momentum:** For external issues, PRs, or partner handoffs, append
  subsequent lifecycle transitions (acknowledged, reproduced upstream, release
  scheduled) to `Findings` as they occur, even after marking the task `done`.

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
Reading it directly (or running `<skill-dir>/scripts/taskgo status PROJECT`)
answers project status, recent outcomes, and immediate direction without
inspecting individual task records.

Structure:

- `## Summary`: Human/agent prose describing the current situation and the key
  outcome/findings of the most recently completed task(s). Cite the active
  session using full identifier syntax:
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

Run `<skill-dir>/scripts/taskgo sync PROJECT`; the commit helper also
synchronizes the affected project. `doctor` catches mechanical drift, but the
invoking agent must compare Summary/Next with current tasks, plan, decisions,
and recent work.

## Agent workflow

Querying status: to answer questions about project status, recent
accomplishments, or next steps, read `STATUS.md` (or run
`<skill-dir>/scripts/taskgo status PROJECT`). Inspect `PLAN.md`, individual
`tasks/`, or Git history only if deeper detail or historical transitions are
requested.

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
1. Run `<skill-dir>/scripts/taskgo sync PROJECT` after the semantic edits are
   coherent.
1. Run `<skill-dir>/scripts/taskgo doctor PROJECT` and perform its semantic
   review.
1. Commit a coherent transition when practical. Use `checkpoint` with `--conv`
   when standing authority is present. Subject = what became true, not what file
   changed. Subjects follow the workspace commit standard (Conventional Commits,
   `type(scope): description`, at most 50 characters); nonconforming subjects
   are rewritten deterministically with a `[WARN]`.

Before leaving or completing a task (especially when marking a task `done`),
double-check that the project is left in a strict **handoff-ready** state. A
reader must be able to understand the state of the project and what needs to be
done next without referencing anything else, as they will have no outside
information or context from your current session. Both the task tracker and any
artifacts (including code repos) must reflect this state. Ensure that:

1. Handoff-ready tracker: state, findings, decisions, and full
   session/conversation IDs
   (`[<conversation-id>](conversation://<conversation-id>)`) needed to resume
   are fully written into the task/STATUS/PLAN, not left only in the
   conversation.
1. Handoff-ready artifacts: tracker claims match actual artifact-repo state
   (e.g. a task is never `done` while its artifact-repo commit remains
   uncommitted).

Examples:

```text
chore(home-automation): rule out firmware risk
chore(home-automation): block firmware testing
chore(compiler): defer parser migration until v3
```

Use commit bodies for useful reasoning not recoverable from state/diff. Add
repeatable `Ref:` trailers for non-derivable external relationships and
`Conversation:` trailers for session traceability (in control repo commits only;
never in external artifact repos).

### Task Export and Ejection (External Agent Handoff)

When delegating a task to an isolated agent or contributor—one operating
strictly within a single artifact repository with no access to the control
repository—execute the **three-phase delegation lifecycle**:

1. **Phase 1: Export (Control Repo Agent):** Evaluate isolation feasibility,
   resolve path drift, and generate a self-contained task brief (ejection
   payload).
1. **Phase 2: Implementation (Isolated Worker):** Execute the task on an
   isolated branch utilizing explicit implementer latitude. Rely exclusively on
   repo-native validation. Report findings out-of-band.
1. **Phase 3: Reconciliation & Integration (Control Repo Agent):** Review the
   isolated branch, apply workspace-level tooling (formatters/linters), polish
   commit formatting to strictly enforce metadata segregation, and commit the
   finalized tracker state.

#### Feasibility & Sanity Check (Phase 1)

Before generating the brief, verify feasibility and correctness:

- **Isolation Feasibility:** The task must be entirely executable within a
  single target repository. Decline requests requiring active multi-repository
  orchestration or control repo edits.
- **Sanity Pass:** Validate that all cited target files, directories, and test
  scripts currently exist in the target repository. Resolve any legacy paths or
  phantom targets in the task prose before export.

#### Payload Construction

Construct the exported brief to be completely self-contained, portable, and
ready for worker execution:

1. **Strict Path Portability:** Use repository-relative paths (e.g.
   `src/parser.py`) so instructions resolve cleanly in isolated worker
   environments. Never output absolute host paths (`/Users/...`), home directory
   expansions (`~/...`), or `file:///` URLs.
1. **Component Orientation:** Synthesize a concise 1–2 sentence overview of the
   target subsystem, defining its role within the broader artifact codebase.
1. **Core Specification & Implementer Latitude:** Embed the Title, Problem,
   Goal, Constraints, and Criteria directly from the task record. Explicitly
   instruct the worker that they possess **implementer latitude**: the autonomy
   to deviate from specific file paths or outdated sketches to accommodate
   current codebase realities, provided the core goal and acceptance criteria
   are met.
1. **Inlined Dependencies:** Resolve and inline all referenced ADRs
   (`decisions/`), references, and exemplary codebase patterns. Strip
   tracker-relative Markdown links (e.g. `[ADR-001](../decisions/001.md)`) and
   replace them with raw text to prevent dangling references.
1. **Secrets and Credentials:** Inline necessary API keys or secrets into the
   exported brief. Emit a visible warning in your chat response prompting the
   user to verify or redact sensitive data.
1. **Repo-Native Verification:** Specify exact repo-native commands (e.g.
   `prove tests/...`, `npm test`) for validation. Do not assume the presence of
   workspace-level tools or `taskgo` in the isolated environment.

#### Handoff & Reconciliation Protocol

Append these operational instructions to the exported brief to govern worker
execution:

1. **Opaque Task ID Preservation:** Define the `TASK-XXXXX` identifier as an
   opaque routing key that must be preserved verbatim.
1. **Commit Conventions:** Instruct the worker to commit to an isolated feature
   branch (e.g. `<agent>/<task-id>-<slug>`). The commit message must append the
   Task ID as a Git trailer (e.g. `Resolves: TASK-XXXXX`). Final commit message
   polishing is reserved for Phase 3 reconciliation.
1. **Out-of-Band Reporting:** Instruct the worker to report completion or
   permanently blocked states exclusively via chat response, including:
   - The verbatim Task ID.
   - The exact integration target (branch name, PR URL, or commit hashes).
   - Its active session record or link (e.g.
     `conversation://<conversation-id>`).
   - Key technical findings or architectural trade-offs.
1. **Strict Data Segregation:** Explicitly warn the worker: The Task ID belongs
   in public commit trailers. Branch references, conversation links, telemetry,
   and internal reasoning belong strictly in the out-of-band chat response.
   Private metadata must never leak into artifact commits.

### Activity Reporting

When requested to produce an activity report (e.g. "produce an activity report
of the last week/month/quarter", standup update, or newsletter item), transform
the internal operational ledger into an outward-facing impact summary:

1. **Acknowledge Audience & Scope:** Determine the target time horizon (weekly,
   monthly, quarterly) and external audience from the prompt.
1. **Extract State:** Query the Git log (`git log --since="<timeframe>"`) and
   task records (`taskgo list [PROJECT]`). Actively parse the `## Outcome` and
   `## Findings` blocks of relevant `done` and `cancelled` tasks to extract
   external entity transitions (e.g. partner reproductions or upstream reviews).
1. **Apply Guidelines:** Follow the transformation principles, sub-linear
   scaling rules, and Standard Output Template defined in
   [`references/activity-reports.md`](references/activity-reports.md).
1. **Enforce Segregation:** Strip private `conversation://` URLs, local branch
   names, and internal repository file paths from the final report. Link
   explicitly to published external artifacts (PRs, issues, dashboards).

## CLI

Requires Python 3.11+ (via `uv`) and Git; it remains a thin layer over ordinary
files/history. Commands operate on the control repository selected by
`--root`/`-R`, `$TASKGO_ROOT`, or the default `~/.projects`, independent of the
working directory. In the command list below, `taskgo` refers to either the
`$PATH` binary or `<skill-dir>/scripts/taskgo`:

```text
taskgo id
taskgo root
taskgo create PROJECT TITLE [--slug SLUG] [--conv ID] [--status STATE] [--problem TEXT] [--goal TEXT] [--criteria TEXT] [--sketch TEXT] [--no-commit] [--dry-run]
taskgo update TASK_ID [--slug SLUG] [--conv ID] [--status STATE] [--title TITLE] [--problem TEXT] [--goal TEXT] [--criteria TEXT] [--sketch TEXT] [--outcome TEXT] [--findings TEXT] [--next TEXT]
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
automatically. Use `--slug` to name the task file (see "Tasks" above),
`--no-commit` to keep the created task uncommitted in the working tree, or
`--dry-run` to preview the task path without creating files.

`update --slug` renames the task file in place, keeping its ID prefix. The
rename is left uncommitted (as with every other `update` edit); commit it with
`checkpoint --all`, which stages both the old and new paths.

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
contact a remote. Both `checkpoint` and `commit` enforce the workspace commit
standard on their messages: nonconforming subjects are rewritten to
`chore(<project>): <subject>` (truncated to 50 characters), and bodies — which
are plain text, not Markdown — are hard-wrapped to 72 characters (URLs are never
split; indented or fenced lines pass through verbatim). Both rewrites emit a
`[WARN]`, so unattended runs never fail on formatting.

## Concurrency

Prefer separate branches/worktrees. Random globally checked IDs avoid a shared
allocator. Resolve merges by reconciling files to one intended current state;
STATUS may be rewritten freely. Stable paths and accepted ADR text are defaults,
not reasons to preserve a broken merge. Avoid squash integration when
intermediate state transitions matter, because squashing can erase
reconstructible states.

## Reference Material

- **[Model & Architecture](references/model.md)** — Context economics, project
  scaling spectrum (Scale 0/1/2), repository boundaries, and Unified AuditEngine
  rationale (`doctor` and `fix`).
- **[Activity Reports](references/activity-reports.md)** — Guidelines,
  transformation principles, downstream lifecycle tracking, and output templates
  for outward-facing reports (weekly/monthly/quarterly).

# Agent Workflows & Handoff

This document details the standard agent operational workflows, commit authority
checks, session attribution, and task handoff protocols for `taskgo`.

## Standard Agent Workflow

Before starting work, an agent must:

1. Read the root `AGENTS.md`, then project `README.md` (or `PROJECT.md`),
   `STATUS.md`, relevant tasks/ADRs, and `PLAN.md` when direction matters.
1. Inspect linked artifact repos under their own instructions.

### Commit Authority

Check standing authority before starting (when reconstructible lifecycle history
matters):

1. **Committed `taskgo:allow-local-commits` marker present:** Authorized for
   guarded `create`, `checkpoint`, and `fix` operations in this control repo
   only.
1. **Authorized:** Commit a meaningful `in-progress` transition before artifact
   work that may span sessions; commit completion with `Ref:` trailers for
   linked artifact commits. A small task completed atomically may go directly
   `todo` -> `done`. Pass `--conv <conversation-id>` or verify `conversations`
   frontmatter and `STATUS.md` cite the full active session identifier.
1. **Not authorized:** Keep changes uncommitted; state clearly that intermediate
   transitions will not be retained. Never create retrospective state commits
   that did not reflect reality at the time.

### After Meaningful Work

1. Rewrite specific files to the new current truth.
1. Update affected task record(s) (e.g. mark `done` with `## Outcome` and
   `## Findings`, recording `[<conversation-id>](<agent>://<conversation-id>)`).
1. Update `STATUS.md` prose (`## Summary` captures the new baseline, active
   session link, and recent outcome; `## Next` reflects immediate next actions);
   `PLAN.md` only if intended direction changed.
1. Run `<skill-dir>/scripts/taskgo sync PROJECT` after semantic edits are
   coherent.
1. Run `<skill-dir>/scripts/taskgo doctor PROJECT` and perform its semantic
   review.
1. Commit a coherent transition when practical using `checkpoint` with `--conv`
   when standing authority is present. Subjects follow the workspace commit
   standard (Conventional Commits, `type(scope): description`, at most 50
   characters).

### Handoff-Ready State

Before leaving or completing a task, double-check that the project is left in a
strict **handoff-ready** state. A reader must be able to understand the state of
the project and what needs to be done next without referencing anything else.

1. **Handoff-ready tracker:** State, findings, decisions, and full
   session/conversation IDs (`[<conversation-id>](<agent>://<conversation-id>)`)
   needed to resume are fully written into the task/STATUS/PLAN, not left only
   in the conversation.
1. **Handoff-ready artifacts:** Tracker claims match actual artifact-repo state.

## Session Attribution & Environment Variables

When creating tasks or committing checkpoints (`--conv`), `taskgo` automatically
detects the active session ID and agent scheme from runtime environment
variables in priority order:

1. `CLAUDE_CODE_SESSION_ID` / `CLAUDE_CODE_REMOTE_SESSION_ID` (`claude://`)
1. `JETSKI_CONVERSATION_ID` (`jetski://`)
1. `ANTIGRAVITY_CONVERSATION_ID` / `ANTIGRAVITY_SESSION` (`antigravity://`)
1. `CODEX_SESSION_ID` (`codex://`)
1. `OPENCODE_SESSION_ID` (`opencode://`)
1. Generic `AI_SESSION_ID` / `CONVERSATION_ID` paired with `AI_AGENT` platform
   name

To inspect session history or correlate commits with agent sessions, query Git:

```bash
# Find all commits associated with a specific session ID
git log --grep='Conversation:.*<conversation-id>'

# List commits and associated session URIs for a specific task
git log --grep='TASK-XXXXX' --format='%h %s %(trailers:key=Conversation,valueonly)'
```

## Task Export and Ejection (External Agent Handoff)

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

### Feasibility & Sanity Check (Phase 1)

- **Isolation Feasibility:** The task must be entirely executable within a
  single target repository.
- **Sanity Pass:** Validate that all cited target files and test scripts
  currently exist in the target repository.

### Payload Construction

Construct the exported brief to be completely self-contained:

1. **Strict Path Portability:** Use repository-relative paths (e.g.
   `src/parser.py`). Never output absolute host paths or `file:///` URLs.
1. **Component Orientation:** Synthesize a concise 1–2 sentence overview of the
   target subsystem.
1. **Core Specification & Implementer Latitude:** Embed Title, Problem, Goal,
   Constraints, and Criteria. Explicitly instruct the worker that they possess
   **implementer latitude**.
1. **Inlined Dependencies:** Resolve and inline all referenced ADRs and design
   tokens.
1. **Secrets and Credentials:** Inline necessary API keys or secrets into the
   exported brief. Emit a visible warning in your chat response.
1. **Repo-Native Verification:** Specify exact repo-native commands (e.g.
   `npm test`) for validation.

### Handoff & Reconciliation Protocol

Append operational instructions to the brief:

1. **Opaque Task ID Preservation:** Define `TASK-XXXXX` as an opaque routing
   key.
1. **Commit Conventions:** Commit to an isolated feature branch. Append the Task
   ID as a Git trailer (`Resolves: TASK-XXXXX`).
1. **Out-of-Band Reporting:** Instruct the worker to report completion
   exclusively via chat response, including the verbatim Task ID, integration
   target, active session record, and key findings.
1. **Strict Data Segregation:** The Task ID belongs in public commit trailers.
   Branch references, conversation links, and internal reasoning belong strictly
   in the out-of-band chat response. Private metadata must never leak into
   artifact commits.

## Agent Dispatch

When assigning a selected task to an agent that can read the control repository,
generate its instructions with `taskgo dispatch TASK_ID`. Choose the task
deliberately; `taskgo list PROJECT --state ready` shows the ready frontier,
while `## Next` in `STATUS.md` normally identifies the intended next action.

Use the generated output without embellishment. It projects the task ID,
project, title, and `Goal` from the task record committed at `HEAD`. The command
writes the note to stdout and readiness findings to stderr. Repair `[WARN]` or
`[FAIL]` findings before dispatching.

When yielding after substantial work with a clear successor task, leave the
tracker and artifact repositories handoff-ready and include the generated note
in the final response. The note remains chat output rather than a tracked
artifact.

```console
$ taskgo dispatch TASK-3A91F
Next is taskgo TASK-3A91F (compiler): Replace the manifest loader with the
streaming parser.

Cold start stops scaling with manifest size.

Read /path/to/compiler/STATUS.md and the task record
(/path/to/compiler/tasks/TASK-3A91F-manifest-loader.md) before acting, and form your
own view of the approach.
```

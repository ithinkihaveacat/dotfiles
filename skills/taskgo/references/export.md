# Task Export

When delegating a task to an isolated agent or contributor working strictly in a
single artifact repository without access to the control repository, follow this
three-phase workflow. (An agent that can read the control repository needs a
handoff instead; see [Agent Handoff](workflows.md#agent-handoff).)

1. **Export (Control Repo Agent):** Check that the task can be completed inside
   one repository, verify cited paths, and write a self-contained task brief.
1. **Implementation (Isolated Worker):** Implement the task on an isolated
   branch with implementer latitude, verify with repo-native checks, and report
   findings out-of-band.
1. **Reconciliation & Integration (Control Repo Agent):** Review the branch, run
   workspace formatters and linters, verify that commits contain no private
   tracker metadata, and record the completed state in the tracker.

## Phase 1: Feasibility & Brief Construction

Before exporting, confirm that:

- The task is self-contained within a single target repository.
- Every cited file and test script exists in that repository.

Write a self-contained brief:

1. **Relative Paths Only:** Use repository-relative paths (such as
   `src/parser.py`), never absolute host paths or `file://` URLs.
1. **Subsystem Context:** Open with 1–2 sentences orienting the worker to the
   target subsystem.
1. **Specification & Latitude:** Include Title, Problem, Goal, Constraints, and
   Criteria, and state that the worker has implementer latitude on the approach.
1. **Inlined Context:** Inline any needed ADR decisions or design tokens from
   the control repository.
1. **Secrets & Credentials:** If the task needs API keys or credentials, inline
   them into the brief and warn the user in chat.
1. **Repo-Native Verification:** Give the exact test and lint commands to run in
   the target repository.

## Return & Reconciliation Protocol

End the brief with these instructions for the worker:

1. **Task ID Trailer:** Treat `TASK-XXXXX` as an opaque routing key and include
   `Resolves: TASK-XXXXX` as a Git commit trailer on the feature branch.
1. **Out-of-Band Report:** Report completion in chat with the `TASK-XXXXX` ID,
   branch or commit, active session ID, and key findings.
1. **Data Segregation:** Keep branch notes, conversation links, and tracker
   context strictly in the chat response—never in artifact repository files or
   commits.

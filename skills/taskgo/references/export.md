# Task Export

When delegating a task to an isolated agent or contributor—one operating
strictly within a single artifact repository with no access to the control
repository—execute the **three-phase delegation lifecycle**. (An agent that can
read the control repository needs a handoff instead; see Agent Handoff in
[workflows.md](workflows.md).)

1. **Phase 1: Export (Control Repo Agent):** Evaluate isolation feasibility,
   resolve path drift, and generate a self-contained task brief (the exported
   brief).
1. **Phase 2: Implementation (Isolated Worker):** Execute the task on an
   isolated branch utilizing explicit implementer latitude. Rely exclusively on
   repo-native validation. Report findings out-of-band.
1. **Phase 3: Reconciliation & Integration (Control Repo Agent):** Review the
   isolated branch, apply workspace-level tooling (formatters/linters), polish
   commit formatting to strictly enforce metadata segregation, and commit the
   finalized tracker state.

## Feasibility & Sanity Check (Phase 1)

- **Isolation Feasibility:** The task must be entirely executable within a
  single target repository.
- **Sanity Pass:** Validate that all cited target files and test scripts
  currently exist in the target repository.

## Brief Construction

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

## Return & Reconciliation Protocol

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

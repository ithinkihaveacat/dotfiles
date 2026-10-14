# Agent Workflows & Handoff

This document details the standard agent operational workflows, commit authority
checks, session attribution, and task handoff protocols for `taskgo`.

## Standard Agent Workflow

Before starting work, an agent must:

1. Run `taskgo handoff <project|TASK_ID>` (or the MCP `handoff` tool) and read
   what its note names: the root `AGENTS.md`, then project `README.md`,
   `STATUS.md` (using its generated `### Decisions` block to identify active,
   non-superseded ADRs in `decisions/`), relevant tasks, and `PLAN.md` when
   direction matters.
1. **Activate the project's skills**, as the note lists them, if the harness has
   a skill manager:
   ```bash
   taskgo skills <project> | skill --scope session add -
   ```
   Pipe the whole list; the `skill` CLI reports and skips a skill the workspace
   already links, and says when the new ones become usable. The session scope
   leaves `.envrc` and repository files untouched. If `skill --scope session`
   reports that the session has no directory of its own, ask before adding the
   skills to the workspace instead. Without a skill manager, read each skill's
   `SKILL.md` directly.
1. Inspect linked artifact repos under their own instructions, and check
   `<project>/scripts/` before writing new scratch helpers.

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

1. Rewrite specific files to the new current truth, saving repeatable scratch
   helpers in `<project>/scripts/` (and the `README.md` map).
1. Update affected task record(s) (e.g. mark `done` with `## Outcome` and
   `## Findings`, recording `[<conversation-id>](<agent>://<conversation-id>)`).
   A completed task keeps Problem, Cost, Goal, and Criteria; Outcome and
   Findings replace Sketch and Constraints, and the Outcome gives a verdict
   against each criterion.
1. Update `STATUS.md` prose (`## Summary` captures the new baseline, active
   session link, and recent outcome; `## Next` reflects immediate next actions);
   `PLAN.md` only if intended direction changed. Rewrite the Summary rather than
   appending a paragraph per session: outcomes of earlier sessions belong in
   their task records and commit history.
1. Update the project `README.md` only if identity, map, or standing rules
   changed. If the work changed a system described by a knowledge skill or an
   artifact repository's documentation, update that owner and record its commit
   with a `Ref:` trailer rather than copying the new facts into the tracker.
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

## Agent Handoff

When assigning a selected task to an agent that can read the control repository,
generate its instructions with `taskgo handoff TASK_ID`
(`taskgo handoff PROJECT` points an agent at a project without choosing a task).
Choose the task deliberately; `taskgo list PROJECT --state ready` shows the
ready frontier, while `## Next` in `STATUS.md` normally identifies the intended
next action.

Use the generated output without embellishment. It projects the task ID,
project, title, and `Goal` from the task record in the working tree (or at
`--at REV`), and ends with the project's skills when its README declares any,
with the command that activates them. The command writes the note to stdout and
readiness findings to stderr. Repair `[WARN]` or `[FAIL]` findings before
handing off. `--json` prints the payload the MCP `handoff` tool returns: the
note with the files it names inlined, and the `skills` list.

When yielding after substantial work with a clear successor task, leave the
tracker and artifact repositories handoff-ready and include the generated note
in the final response. The note remains chat output rather than a tracked
artifact.

```console
$ taskgo handoff TASK-3A91F
Next is taskgo TASK-3A91F (compiler): Replace the manifest loader with the
streaming parser.

Cold start stops scaling with manifest size.

Read /path/to/compiler/STATUS.md and the task record
(/path/to/compiler/tasks/TASK-3A91F-manifest-loader.md) before acting, and form your
own view of the approach.

Skills: coding-standards, local:notes. If your harness has a skill manager,
activate them for this session with the command below (adding one that is
already active is harmless); otherwise read each skill's SKILL.md.

  taskgo skills compiler | skill --scope session add -
```

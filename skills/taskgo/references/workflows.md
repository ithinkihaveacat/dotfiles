# Agent Workflows & Handoff

Standard agent workflows, commit authority rules, session attribution, and
handoff protocols for `taskgo`.

## Standard Agent Workflow

Before starting work:

1. Run `taskgo handoff <project|TASK_ID>` (or the MCP `handoff` tool) and read
   the onboarding files it names (`STATUS.md` and the task record for an
   unfinished task, or `README.md`, `STATUS.md`, and `PLAN.md` for a project;
   `--json` and the MCP `handoff` tool inline those files plus the root
   `AGENTS.md`). Check the generated `### Decisions` block in `STATUS.md` for
   active ADRs in `decisions/`.
1. **Activate the project's skills** if the harness has a skill manager:
   ```bash
   taskgo skills <project> | skill --scope session add -
   ```
   Pipe the whole list; `skill` skips skills already linked in the workspace and
   leaves repository files untouched. If `skill --scope session` reports no
   session directory, ask before adding skills to the workspace. Without a skill
   manager, read each skill's `SKILL.md` directly.
1. Inspect linked artifact repositories under their own instructions, consult
   relevant `<project>/references/` pages linked from the project map or task,
   and check `<project>/scripts/` before writing new scratch helpers.

### Commit Authority

A control repository whose committed `AGENTS.md` declares `taskgo` (maintained
by `taskgo fix`) grants standing authority for guarded `create`, `checkpoint`,
`commit`, `fix`, and `mcp` write operations in the control repository:

1. Commit a meaningful `in-progress` transition before artifact work that may
   span sessions; commit completion with `Ref:` trailers for linked artifact
   commits. A small task completed atomically may go directly `todo` -> `done`.
   Pass `--conv <conversation-id>` or verify `conversations` frontmatter and
   `STATUS.md` cite the full active session identifier.
1. When `--no-commit` is requested (or before a brand-new repository's initial
   `AGENTS.md` is committed), keep changes uncommitted; never create
   retrospective state commits that did not reflect reality at the time.

#### Plain `git commit`

Prefer the guarded commands; they enforce subject rules, sync `STATUS.md`, and
add trailers. Some legitimate restructuring cannot be expressed through them
(for example, `checkpoint` and `commit` refuse changes spanning more than one
project, so moving a task or merging projects needs something else). For such
operations, use a plain `git commit`. Work out what the change requires from the
invariants in this skill rather than waiting for a documented procedure.

Plain `git commit` is outside the guarded commands, so tell the human: ask
before committing when practical, and otherwise say clearly afterwards what you
committed and why the guarded commands could not do it. Leave the tracker as
coherent as a guarded commit would (`taskgo sync` and `taskgo doctor` clean for
every affected project, only the affected paths staged, a Conventional Commits
subject, and a `Conversation:` trailer).

### After Meaningful Work

1. Rewrite specific files to the new current truth, saving repeatable scratch
   helpers in `<project>/scripts/` (and the `README.md` map).
1. Update affected task record(s) (e.g. mark `done` with `## Outcome` and
   `## Findings`, recording `[<conversation-id>](<agent>://<conversation-id>)`).
   A completed task keeps Problem, Cost, Goal, and Criteria; Outcome and
   Findings replace Sketch and Constraints, and the Outcome gives a verdict
   against each criterion. If the task produced domain findings, playbooks, or
   architectural syntheses that future tasks in the project will need, fold them
   into a topic page in `<project>/references/`, or update the existing owner in
   an artifact repository or skill. Update maintained claims in place and keep
   pages discoverable from the `README.md` map, directly or through a reference
   index, rather than leaving them buried in a completed task record. When a
   task relies on or updates a reference page, link that path from the task's
   `Sketch` or `Findings`.
1. Update `STATUS.md` prose (`## Summary` captures the new baseline, active
   session link, and recent outcome; `## Next` reflects immediate next actions);
   `PLAN.md` only if intended direction changed. Rewrite the Summary rather than
   appending a paragraph per session: outcomes of earlier sessions belong in
   their task records and commit history.
1. Update the project `README.md` only if identity, map (including new
   `references/` or `docs/` pages), or standing rules changed. If the work
   changed or corrected understanding of a system described by a knowledge skill
   or an artifact repository's documentation, update that owner and record its
   commit with a `Ref:` trailer rather than copying the new facts into the
   tracker.
1. Run `taskgo sync PROJECT` after semantic edits are coherent.
1. Run `taskgo doctor PROJECT` and review any affected reference pages for
   outdated claims or broken links.
1. Commit a coherent transition when practical using `checkpoint` with `--conv`
   when standing authority is present. Subjects follow the workspace commit
   standard (Conventional Commits, `type(scope): description`, at most 50
   characters).

### Handoff-Ready State

Before leaving or completing a task, double-check that the project is left in a
strict **handoff-ready** state. A reader can understand the operational state
and find the information needed to resume without recovering the conversation.
Keep state and next actions in the tracker; link to reference pages for
supporting knowledge.

1. **Handoff-ready tracker:** State, next actions, and full session/conversation
   IDs (`[<conversation-id>](<agent>://<conversation-id>)`) needed to resume are
   written into the task/STATUS/PLAN. Supporting findings and decisions are
   recorded there or linked from it, not left only in the conversation.
1. **Handoff-ready artifacts:** Tracker claims match actual artifact-repo state.

## Session Attribution & Environment Variables

When creating tasks or committing (`create`, `checkpoint`, `commit` with or
without `--conv`), `taskgo` automatically detects the active session ID and
agent scheme from runtime environment variables in priority order:

1. `CLAUDE_CODE_SESSION_ID` / `CLAUDE_CODE_REMOTE_SESSION_ID` (`claude://`)
1. `JETSKI_CONVERSATION_ID` (`jetski://`)
1. `ANTIGRAVITY_CONVERSATION_ID` / `ANTIGRAVITY_SESSION` (`antigravity://`)
1. `CLAUDE_SESSION_ID` (`claude://`)
1. `OPENCODE_SESSION_ID` (`opencode://`)
1. `CODEX_SESSION_ID` (`codex://`)
1. `INVOKER_INFO_ROOT_SESSION_ID` / `CONVERSATION_ID` paired with `AI_AGENT` or
   `INVOKER_INFO_NAME` platform name (falling back to `conversation://` when no
   canonical agent scheme is detected)

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
(`taskgo handoff PROJECT` points an agent at a project and lists its in-progress
and ready tasks without choosing one). Choose the task deliberately;
`taskgo list PROJECT --state ready` shows the ready frontier, while `## Next` in
`STATUS.md` normally identifies the intended next action.

Use the generated output without embellishment. It projects the task ID,
project, title, and `Goal` from the task record in the working tree (or at
`--at REV`), and ends with the project's skills when its README declares any,
with the command that activates them. The command writes the note to stdout and
readiness findings to stderr. Repair `[WARN]` or `[FAIL]` findings before
handing off. `--json` prints the payload the MCP `handoff` tool returns: the
note with the onboarding files (`AGENTS.md`, `README.md`, `STATUS.md`,
`PLAN.md`, and the task record) inlined, the `guide`, the `skills` list, and the
active and ready task queues.

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

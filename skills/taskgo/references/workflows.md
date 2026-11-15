# Commits, Handoff, and Sessions

Read this before committing anything the guarded commands cannot express, when
you hand a task to another agent, or when you need to trace which session made a
change. The everyday start and finish steps are in [SKILL.md](../SKILL.md).

## Commit Authority

A control repository whose committed root `AGENTS.md` declares taskgo grants
standing authority for the guarded commits: `create`, `checkpoint`, `commit`,
`fix`, and MCP writes. taskgo manages only the block between
`<!-- taskgo:begin -->` and `<!-- taskgo:end -->` in that file: `taskgo fix`
writes it and `taskgo doctor` checks it. Everything outside the block is the
repository's own local policy, such as timezone notes, report audience and
format, environment rules, default skills, and data-care rules. taskgo preserves
it; read it before you work.

- Commit state as it really was. When the user asks for `--no-commit`, or the
  repository's first `AGENTS.md` is not yet committed, leave changes
  uncommitted. Never create retrospective commits for states that did not exist
  at the time.
- Never rewrite artifact repository history.

### Commit Subjects

Guarded commits use Conventional Commits: `type(scope): description`, at most 50
characters *including* the prefix, with the project as the scope
(`fix(compiler): stream manifest parsing`). The CLI refuses an over-long subject
and reports its length; shorten it and run the command again. A subject with an
unknown type is rewritten as `chore(<project>): …`. Bodies are plain text,
wrapped at 72 columns. Put linked artifact commits in `--ref` trailers
(`--ref repo@sha`).

### Plain `git commit`

Prefer the guarded commands: they enforce subject rules, sync `STATUS.md`,
format the Markdown they commit, run the doctor checks, and add trailers. Raw
Git on the control repository is still supported, and it is the right tool when
a change cannot be expressed through them. `checkpoint` and `commit` refuse
changes that span more than one project, so these need a plain `git commit`:

- moving a task between projects;
- renaming, merging, or removing a project;
- other large restructuring across the tree.

Work out what the change needs from the invariants in SKILL.md rather than
waiting for a documented procedure. Then:

1. Run `taskgo doctor`, and `taskgo fix` to repair what it can (IDs, status
   aliases, `STATUS.md` blocks, formatting).
1. Stage only the affected paths. Use a Conventional Commits subject and a
   `Conversation: <agent>://<id>` trailer.
1. Tell the user. Ask before committing when practical; otherwise say clearly
   afterwards what you committed and why the guarded commands could not do it.

### Branches and Merges

Separate branches or worktrees are fine for parallel work. Resolve a merge by
reconciling files to one intended current state; `STATUS.md` may be rewritten
freely. Stable paths and accepted ADR text are defaults, not reasons to keep a
broken merge. `taskgo doctor` reports duplicate task IDs after a merge. Avoid
squash merges when intermediate state changes matter, because squashing erases
them.

## Agent Handoff

To point an agent that can read the control repository at work, run
`taskgo handoff TASK_ID`. `taskgo handoff PROJECT` names the project and lists
its in-progress and ready tasks without choosing one. (An isolated worker that
cannot read the tracker needs a [task export](export.md) instead.)

- Choose the task yourself. `taskgo list PROJECT --state ready` shows the ready
  tasks; `## Next` in `STATUS.md` usually names the intended next action.
- Pass the note on unchanged. It gives the task ID, project, title, `Goal`, the
  files to read, and the project's skills with the command that activates them.
  The note goes to stdout; readiness findings go to stderr.
- Fix `[WARN]` and `[FAIL]` findings before handing off.
- A long note, or one that needs extra facts, means the tracker is not
  handoff-ready. Repair the tracker; do not add to the note.
- When you stop after substantial work and a successor task is clear, leave
  everything handoff-ready and include the note in your final reply. The note is
  chat output, not a tracked file.

`--json` prints the payload the MCP `handoff` tool returns: the same note with
the files it names inlined, plus the root `AGENTS.md`, the `skills` list, a
guide to the MCP tools, and the active and ready task queues.

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

### Handoff-Ready

A project is handoff-ready when a reader can understand its state and resume
without the conversation:

1. **Tracker:** state and next actions are in the task, `STATUS.md`, or
   `PLAN.md`. Findings and decisions are recorded there or linked from there,
   not left only in the chat. Sessions are recorded in commit trailers and each
   task's `conversations`.
1. **Artifacts:** tracker claims match the real state of the artifact
   repositories.

## Session Attribution

`create`, `checkpoint`, and `commit` record the active session in the task's
`conversations` frontmatter and a `Conversation:` commit trailer. The CLI
detects the session ID from the agent's environment, for example
`CLAUDE_CODE_SESSION_ID` (`claude://`) or `CODEX_SESSION_ID` (`codex://`). To
teach it another agent, set `TASKGO_SESSION_VARS` to space-separated
`SCHEME=VARIABLE` entries, such as `myagent=MYAGENT_SESSION_ID`; those are
checked first, in order. Pass `--conv <id>` only when the harness exports no
session ID. Any `<scheme>://<id>` URI is valid, including a chat URL.

To trace sessions through Git:

```bash
# Commits made in one session
git log --grep='Conversation:.*<conversation-id>'

# Commits for one task, with their session URIs
git log --grep='TASK-XXXXX' --format='%h %s %(trailers:key=Conversation,valueonly)'
```

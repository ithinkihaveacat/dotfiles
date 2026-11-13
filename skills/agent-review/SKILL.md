---
name: agent-review
description: >-
  Conducts independent, read-only code reviews of changes (branches, diffs,
  commits, working trees, or pull requests) and two-stage complexity audits of
  working projects or subsystems using external CLI agents (Codex, Claude, agy)
  or an in-session workflow. Focuses strictly on actionable defects and proved,
  disproportionate accreted complexity. Use when reviewing code changes,
  requesting a second opinion on diffs, checking PRs, auditing for bugs, or
  checking a working codebase for overengineering and accidental complexity. Do
  not use for implementing fixes in place or reviewing prose or design
  documents.
compatibility: >-
  Requires git. Optional external review agents: codex, claude, agy.
---

# Agent Review

This skill covers two kinds of independent, read-only review:

- **Code review** of a change: a branch, diff, commit, working tree, or pull
  request. Return only defects that the author would likely fix. Treat findings
  as claims that need evidence, not suggestions to improve code in general. See
  [Perform a synthesized review](#perform-a-synthesized-review).
- **Complexity audit** of a working project or subsystem: find anything whose
  cost in maintainer machinery, runtime work, or footprint is bonkers next to
  what the project is for, and prove a safe fix. See
  [Perform a complexity audit](#perform-a-complexity-audit).

The two do not overlap. A code review takes the design as given and looks for
defects in a change. A complexity audit takes the code as correct and questions
whether it should have this shape.

## Choose the execution role

Determine which role this invocation has before doing anything else:

- **Reviewer or auditor session:** The current agent was asked to review or
  audit the repository, or the prompt says this is a synthesized session. For a
  code review, perform the workflow below yourself and do not launch another
  agent. For a complexity audit, run Stage 1 across the whole project first,
  then run Stage 2 in isolated scratch copies—delegating one fresh subagent or
  worker per candidate problem when available, or testing each candidate
  sequentially in clean scratch copies when working alone.
- **Delegating session:** The user asked to obtain an independent review or
  audit from a named CLI agent. For code reviews, run
  `scripts/review-with-agent` from this skill; the launcher uses native review
  commands where possible and invokes this skill for synthesized fallbacks. For
  complexity audits, launch the target CLI agent non-interactively with an
  external scratch directory and a prompt naming this skill and
  [references/complexity-audit.md](references/complexity-audit.md).

Native review commands are process entry points, not tools a reviewer session
must recursively call. Do not launch a second copy of the current agent merely
because its CLI has native review support.

## Delegate non-interactively

For code reviews, run the launcher from the repository being reviewed:

```bash
scripts/review-with-agent --agent codex --base main
scripts/review-with-agent --agent claude --base main
scripts/review-with-agent --agent agy --commit HEAD
scripts/review-with-agent --agent agy --uncommitted
```

Paths beginning with `scripts/` are relative to this skill directory. Use
`--dry-run` to inspect the selected command without starting an agent. Use
`--synthesized` to test the portable workflow even when a native route exists.
See [Command Index](references/command-index.md) for full launcher options.

For a direct CLI code review without the launcher, use the same distinction:

```bash
codex exec review --base main
claude -p "/code-review main...HEAD" --permission-mode dontAsk --no-session-persistence
agy --print "Use the installed agent-review skill to review the current branch against main. Perform the review yourself; do not delegate." --mode plan --sandbox
```

The launcher currently selects:

| Agent  | Direct route                                           | Synthesized fallback             |
| ------ | ------------------------------------------------------ | -------------------------------- |
| Codex  | Native base-to-HEAD, commit, and uncommitted review    | Explicit `$agent-review` prompt  |
| Claude | Local `/code-review` for a base range or single commit | Explicit `/agent-review` prompt  |
| agy    | None                                                   | Explicit natural-language prompt |

The `agent-review` name is intentionally distinct from Claude's bundled
`/code-review`, so Claude can keep using that local reviewer as its direct
route. Do not add `ultra` or substitute `claude ultrareview`: those launch a
cloud-hosted multi-agent service with materially different execution and cost.
agy has no documented forced skill-invocation syntax, so its fallback names the
`agent-review` skill explicitly; verify skill loading in verbose logs when
activation matters.

The launcher routes code reviews only. To delegate an unattended complexity
audit, pass an external scratch directory so the agent can clone, build, and
test candidate fixes without modifying the target project:

```bash
codex exec 'Use $agent-review (references/complexity-audit.md) to run an unattended complexity audit on <target-path>. Use <scratch-dir> for scratch copies and trials; do not modify <target-path>.'
claude -p "/agent-review Run an unattended complexity audit on <target-path> following references/complexity-audit.md. Use <scratch-dir> for scratch copies and trials; do not modify <target-path>." --permission-mode dontAsk --no-session-persistence
agy --print "Use the installed agent-review skill (references/complexity-audit.md) to run an unattended complexity audit on <target-path>. Use <scratch-dir> for scratch copies and trials; do not modify <target-path>."
```

## Perform a synthesized review

Read [references/review-rubric.md](references/review-rubric.md) completely
before reviewing a change.

1. Confirm the repository and requested target. Support these target shapes:
   - **Base branch:** changes from the merge base of the requested base and
     `HEAD` through the current working tree.
   - **Base plus head revision:** committed changes from the merge base through
     the requested head revision.
   - **Commit:** changes introduced by one commit.
   - **Uncommitted:** staged, unstaged, and untracked changes.
1. Read every applicable repository instruction file before judging a changed
   file. More-specific instructions override broader ones.
1. Inspect repository state and the diff summary before reading the full diff.
   Review large diffs in bounded sections rather than truncating one large
   command result.
1. Read surrounding implementation, callers, tests, schema, and history as
   needed to prove or disprove each candidate finding. The diff identifies
   scope; it is not the only context available.
1. Run focused tests, type checks, linters, or small reproductions when they
   materially increase confidence. Do not edit source files. Normal disposable
   build and test outputs are acceptable.
1. Re-check every candidate against the rubric, deduplicate overlapping
   findings, and ensure each reported location overlaps changed lines.
1. Return the findings in the rubric's output format. If none qualify, say so
   explicitly.

## Perform a complexity audit

Read [references/complexity-audit.md](references/complexity-audit.md) completely
before auditing a project or subsystem.

Single-pass audits fail when one pass tries to read a whole codebase and guess
what a fix will save. Separate discovery from proof:

1. **Stage 1 — Find the problems.** Read practically every source and test file,
   the docs and rules, the build config, and the commit and review history. Map
   the project's purpose, outward entry points, and constraints, and write down
   the candidate bonkers problems grouped by root cause—without designing
   patches yet.
1. **Stage 2 — Build and prove each fix.** Test each candidate in its own clean
   scratch copy (one fresh subagent per candidate when available, or clean
   sequential scratch copies otherwise). Implement the complete fix, run the
   build and tests, measure the net saving and side effects directly from the
   working diff, and drop any candidate that saves little or bloats the code or
   test suite.
1. **Combine and report.** Verify that the surviving fixes build and pass tests
   together in one clean scratch copy so overlaps are never counted twice. Write
   a plain-English report separating fixes that need no owner decision from
   explicit owner-decision forks.

Never modify the target project; run all builds, benchmarks, and edits inside an
external scratch directory.

## Handle review results

Treat every finding from any reviewer as unverified until checked against the
code.

- **Code reviews:** When the user asks to act on findings, record each
  disposition as accepted, rejected with evidence, or partially adopted. Re-run
  a fresh review after fixes instead of resuming the earlier reviewer session.
- **Complexity audits:** Fixes that preserve outward behavior and carry no
  trade-off can land first, one revertible step at a time, re-running the
  project's build and tests after each step. Fixes gated on an owner fork wait
  until the owner settles the fork.

## Reference Material

- **Command Index**: Detailed launcher synopsis, options, and arguments. See
  [references/command-index.md](references/command-index.md).
- **Complexity Audit**: Two-stage problem scan and scratch proof workflow,
  constraint questioning, owner forks, and plain-English report guidance. See
  [references/complexity-audit.md](references/complexity-audit.md).
- **Review Rubric**: Finding thresholds, severity definitions, comment formats,
  and verdict reporting for code reviews. See
  [references/review-rubric.md](references/review-rubric.md).

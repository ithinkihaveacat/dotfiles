---
name: agent-review
description: >-
  Conducts independent, read-only code reviews of changes (branches, diffs,
  commits, working trees, or pull requests) and multi-pass complexity audits of
  working projects or subsystems using external CLI agents (Codex, Claude, agy)
  or an in-session workflow. Focuses strictly on actionable defects and proved,
  disproportionate accreted complexity. Use when reviewing code changes,
  requesting a second opinion on diffs, checking PRs, auditing for bugs, or
  checking a working codebase for overengineering and accidental complexity. Do
  not use for editing prose or reviewing design documents.
compatibility: >-
  Requires git. Optional external review agents: codex, claude, agy.
---

# Agent Review

This skill covers two kinds of independent review:

- **Code review** of a change: a branch, diff, commit, working tree, or pull
  request. Return only defects that the author would likely fix. Treat findings
  as claims that need evidence, not suggestions to improve code in general. See
  [Perform a synthesized review](#perform-a-synthesized-review).
- **Complexity audit** of a working project or subsystem: find anything whose
  cost in maintainer machinery, runtime work, or footprint is bonkers next to
  what the project is for, build and verify clean fixes in isolated copies, and
  report what was wrong and what fixing it brings. See
  [Perform a complexity audit](#perform-a-complexity-audit).

The two keep separate concerns. A code review takes the design as given and
looks for correctness defects in a change. A complexity audit takes the starting
code as working and questions whether it should have this shape—then uses a
correctness-only review pass to verify its candidate fixes.

## Choose the execution role

Determine which role this invocation has before doing anything else:

- **Reviewer or auditor session:** The current agent was asked to review or
  audit the repository, or the prompt says this is a synthesized session. For a
  code review, perform the workflow below yourself and do not launch another
  agent. For a complexity audit, work through the four passes in isolated
  scratch copies—delegating subagents or workers for parallelizable passes when
  helpful—without modifying the original repository or letting passes interfere
  with each other.
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
audit, pass an external scratch directory so all copies, builds, candidate
fixes, and review passes stay outside the target project:

```bash
codex exec 'Use $agent-review (references/complexity-audit.md) to run an unattended complexity audit on <target-path>. Use <scratch-dir> for isolated copies and trials; do not modify <target-path>.'
claude -p "/agent-review Run an unattended complexity audit on <target-path> following references/complexity-audit.md. Use <scratch-dir> for isolated copies and trials; do not modify <target-path>." --permission-mode dontAsk --no-session-persistence
agy --print "Use the installed agent-review skill (references/complexity-audit.md) to run an unattended complexity audit on <target-path>. Use <scratch-dir> for isolated copies and trials; do not modify <target-path>."
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
what a fix will save, and unreviewed changes routinely break subtle edges even
when existing tests stay green. Work in four passes across isolated copies of
the repository or source artifacts so nothing touches the original checkout,
creates branches or pull requests unless explicitly requested, or lets
concurrent passes interfere with each other:

```text
Audit Progress:
- [ ] Pass 1: Scan the whole codebase for what looks bonkers
- [ ] Pass 2: Investigate and test candidate fixes in isolated copies
- [ ] Pass 3: Review surviving fixes strictly for correctness
- [ ] Pass 4: Evaluate net payoff and write a plain-English summary
```

1. **Pass 1 — Scan for what looks bonkers.** Read practically every source and
   test file, the docs and rules, the build config, and the commit and review
   history. Map what the project is for and its constraints, and flag anything
   that looks bogus, overbuilt, or embarrassing—grouped by root cause—without
   designing patches yet.
1. **Pass 2 — Investigate and test each fix.** Explore each candidate deeply in
   its own isolated copy (one subagent per candidate when helpful, or separate
   copies sequentially) to see whether the cost is real and can be cleanly
   removed—whether by changing a setting or dependency, switching algorithms,
   relaxing a constraint, or deleting dead machinery. Build, run tests, measure
   the real payoff (in runtime work, power, footprint, build/test time, or
   code), drop anything messy or low-payoff, and merge surviving fixes cleanly
   without stacking two fixes for one problem.
1. **Pass 3 — Review strictly for correctness.** In practice, simplifying
   accreted code, changing settings or dependencies, replacing polling with
   events, or adding caches and batching almost always introduces subtle
   bugs—lifecycle or destroy races, config side effects, dropped flags,
   non-hermetic caches, weakened test checks—that existing tests miss. Run a
   correctness review (via a fresh subagent, CLI reviewer, or dedicated pass; no
   fixed rubric required) on the merged fixes by default, or per fix when
   changes are large and independent. Keep concerns separate: take the new
   design as given and check only for correctness defects, not whether the
   change was worth making or whether to restore speculative fallbacks. Fix
   confirmed defects surgically in the copy.
1. **Pass 4 — Evaluate and summarize.** Re-assess after Pass 3 repairs land: if
   fixing edge cases wiped out a fix's payoff or made it messier than what it
   replaced, drop it. Present the report (separating no-decision fixes from
   owner forks), opening with a plain-English summary of the embarrassing
   mistakes found and what fixing them brings—power, wake-ups, latency, memory,
   or binary/dependency size saved, leaks or UI glitches fixed, build or test
   speedups, dead branches removed, and the honest diff footprint.

## Handle review results

Treat every finding as unverified until checked against the code, and do not
modify the target checkout or open pull requests unless the user explicitly asks
to apply changes:

- **Code reviews:** Record each disposition as accepted, rejected with evidence,
  or partially adopted. Re-run a fresh review after fixes instead of resuming
  the earlier reviewer session.
- **Complexity audits:** When asked to land proven fixes into a repository,
  apply no-decision fixes in revertible steps (holding owner forks until
  settled), run a correctness-only review pass if anything had to adapt to
  current `HEAD`, and close with a plain-English summary of the mistakes
  removed, concrete benefits gained (runtime, power, size, reliability, and
  code/dependency changes), and full `git diff` breakdown.

## Reference Material

- **Command Index**: Detailed launcher synopsis, options, and arguments. See
  [references/command-index.md](references/command-index.md).
- **Complexity Audit**: Four-pass complexity scan, isolated fix verification,
  correctness review, constraint questioning, owner forks, and plain-English
  summary guidance. See
  [references/complexity-audit.md](references/complexity-audit.md).
- **Review Rubric**: Finding thresholds, severity definitions, comment formats,
  and verdict reporting for code reviews. See
  [references/review-rubric.md](references/review-rubric.md).

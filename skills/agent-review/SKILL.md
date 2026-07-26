---
name: agent-review
description: Use this skill whenever the user asks to review code changes, a branch against a base branch, a commit, a working tree, or a pull request, including requests for an independent or second-opinion review. Select a native non-interactive review entry point when the chosen external agent supports the requested target; otherwise perform the synthesized read-only workflow in this skill. Trigger on code review, review branch, review diff, review commit, review PR, second opinion, check my changes, and look for bugs. Do not use for implementing fixes or reviewing prose or design documents.
---

# Code Review

Review changes independently and return only defects that the author would
likely fix. Treat findings as claims that need evidence, not suggestions to
improve code in general.

## Choose the execution role

Determine which role this invocation has before doing anything else:

- **Reviewer session:** The current agent was asked to review the repository, or
  the prompt says this is a synthesized reviewer session. Perform the workflow
  below yourself. Do not launch another agent.
- **Delegating session:** The user asked to obtain an independent review from a
  named CLI agent. Run `scripts/review-with-agent` from this skill. The launcher
  uses native review commands where possible and explicitly invokes this skill
  for synthesized fallbacks.

Native review commands are process entry points, not tools a reviewer session
must recursively call. Do not launch a second copy of the current agent merely
because its CLI has native review support.

## Delegate non-interactively

Run the launcher from the repository being reviewed:

```bash
scripts/review-with-agent --agent codex --base main
scripts/review-with-agent --agent claude --base main
scripts/review-with-agent --agent agy --commit HEAD
scripts/review-with-agent --agent agy --uncommitted
```

Paths beginning with `scripts/` are relative to this skill directory. Use
`--dry-run` to inspect the selected command without starting an agent. Use
`--synthesized` to test the portable workflow even when a native route exists.

For a direct CLI invocation without the launcher, use the same distinction:

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

## Perform a synthesized review

Read [references/review-rubric.md](references/review-rubric.md) completely
before reviewing.

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

## Handle review results

Treat every finding from any reviewer as unverified until checked against the
code. When the user asks to act on findings, record each disposition as
accepted, rejected with evidence, or partially adopted. Re-run a fresh review
after fixes instead of resuming the earlier reviewer session.

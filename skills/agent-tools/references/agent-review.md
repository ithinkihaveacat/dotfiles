# Consulting Other Agents for Review

Recipes for getting a second opinion from another AI agent on work you have
produced or are about to produce: a plan, a branch, a PR, or a document. The
value comes from independence — a reviewer with no attachment to the approach,
ideally from a **different model family** than the agent that produced the work
(e.g. a Claude-based agent asking Codex or the Gemini-backed Oracle).

## When to Consult Another Agent

- **Before implementation (plan review):** designs for risky or hard-to-reverse
  work — production data migrations, schema changes, anything with a "run once"
  step. Use the Oracle with a session brief and broad source context.
- **After implementation (code review):** non-trivial branches, especially code
  that will run unattended or against production. Use Codex or Claude against
  the diff.
- **Before publishing (prose review):** essays, documentation, reports. Use
  emerson (closed-book) or the Oracle (when claims need external verification).

## Choosing a Mechanism

| Task               | Input                      | Tool                                                     |
| ------------------ | -------------------------- | -------------------------------------------------------- |
| Code review        | local branch/diff          | `codex exec` (or `claude -p`) run in the repo            |
| Code review        | GitHub PR URL              | `scripts/gh-markdown URL` piped to `claude -p`           |
| Plan/design review | files/dirs + session brief | `scripts/oracle`                                         |
| Prose review       | document on stdin          | `scripts/emerson`; `scripts/oracle` if it needs research |

`oracle`, `emerson`, and `gh-markdown` are this skill's scripts. `codex`,
`claude`, and `agy` are external CLIs — install steps are in
[software-installation.md](software-installation.md).

## Writing the Review Prompt

The same principles apply to every mechanism:

1. **Supply facts the reviewer cannot derive.** Constraints that live outside
   the diff — production-only schema differences, operational context, why an
   odd-looking design is deliberate — must be stated, or the reviewer wastes its
   findings re-litigating settled decisions.
1. **Specify the deliverable.** Ask for a numbered list of findings, each with a
   severity (critical/major/minor/nit), file/line, and a concrete failure
   explanation. Ask it to say explicitly when it finds no critical issues.
1. **Forbid modifications.** Reviews are read-only; say "do not modify any
   files."

## Recipe: Codex (`codex`)

Best for code review of a local branch or working tree. Runs sandboxed in the
current directory and can run `git`, read files, and execute tests itself.

Built-in review mode (no custom context possible — `--base` cannot be combined
with a prompt argument):

```bash
codex exec review --base main          # branch diff vs. main
codex exec review --uncommitted        # staged + unstaged + untracked
codex exec review --commit SHA         # a single commit
```

When the review needs context the diff doesn't carry, use plain `codex exec`
with a heredoc prompt and let it drive git itself:

```bash
cd /path/to/repo && codex exec - <<'EOF'
You are doing a code review. Review the diff of this branch against main:
run `git diff main...HEAD` and read any files you need for context.

Key facts you can't see from the diff alone:
- <production-only constraints, operational context, deliberate oddities>

Review for: correctness bugs, transaction/concurrency pitfalls, edge cases,
idempotency holes, weak test coverage.

Output: a numbered list of findings, each with severity
(critical/major/minor/nit), file/line, and a concrete explanation. If you
find no critical issues, say so explicitly. Do not modify any files.
EOF
```

Output is verbose (progress, tool calls); the findings arrive at the end.

## Recipe: Claude Code (`claude`)

Non-interactive one-shot via `-p`/`--print`, run in the repo with the same
prompt shape as the Codex heredoc above:

```bash
cd /path/to/repo && claude -p "<review prompt as above>"
```

Or pipe prepared input, e.g. a GitHub PR formatted by this skill's
`gh-markdown`:

```bash
scripts/gh-markdown https://github.com/owner/repo/pull/123 |
  claude -p "Review this PR. Numbered findings with severity; say so
             explicitly if nothing critical."
```

Note: when the work was authored by a Claude-based agent, `claude` reviews with
the same model family. That still catches plenty (fresh context, no attachment
to the approach), but prefer a cross-vendor reviewer for independence when one
is available.

## Recipe: Oracle (`scripts/oracle`)

Best for reviewing a **plan or design before implementation** rather than a
diff: it takes files/directories as context, uses search grounding, and reasons
deeply. Full mechanics — session brief, broad file context, `--dry-run` first —
are in the oracle section of [SKILL.md](../SKILL.md). Review-specific points:

- Put the draft plan in the session brief and ask the Oracle to poke holes, not
  to validate. Name the specific open questions you want weighed.
- Consultations are stateless one-shots. To follow up (e.g. "I found X, you
  suggested Y — which wins?"), attach the saved answer file
  (`~/.cache/oracle/answer_*.md`) as context to a fresh call.

## Recipe: emerson (`scripts/emerson`)

Prose review from stdin. Closed-book: it treats the input as the sole source of
truth, so it reviews structure, clarity, and internal consistency — not factual
accuracy against the world.

```bash
scripts/emerson "Review this document for structure, argument coherence,
and unsupported claims. Numbered findings." < draft.md
```

## Recipe: Antigravity (`agy`)

TODO

## Handling the Findings

Treat every finding as a **claim, not a verdict**. Reviewers are persuasive and
wrong at predictable rates — a typical review yields a mix of genuine catches,
findings that are factually wrong about the codebase, and suggestions that are
real but not worth their cost.

- **Verify before acting.** Check each finding against the actual code or data.
  A finding that names a concrete failure scenario should be reproducible from
  that scenario.
- **Record the disposition.** For each finding: accepted (and what changed),
  rejected (and the evidence), or partially adopted. This ends up in the commit
  or PR description.
- **Re-run rather than resume.** Reviews are stateless; after applying fixes,
  run a fresh review of the new diff instead of trying to continue the old
  conversation.

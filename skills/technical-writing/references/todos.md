# TODO Item Guidelines

This guide covers writing items in a `TODO.md` file: a lightweight task list
kept at the root of a repository. Each item records a goal worth pursuing, what
"done" looks like, and whatever useful knowledge the writer had at the time — so
that a future implementer (human or agent) can pick it up cold.

## Intent and Audience

A TODO item is a **brief to a future implementer**, written before the work is
scheduled. It is neither a plan nor a progress report:

| Document        | Answers                  | Written       | Lives           |
| --------------- | ------------------------ | ------------- | --------------- |
| TODO item       | What and why? Done when? | Before work   | `TODO.md`       |
| Plan            | How, step by step?       | At work start | Ephemeral       |
| Progress report | What happened so far?    | During work   | A separate file |

The implementer re-derives the plan against the codebase as it exists when the
work actually starts — which may be long after the item was written.

## Item Template

Every item uses a level-2 heading (`##`) in a file whose only level-1 heading is
`# TODO`. Do not number items: numbers force renumbering churn when items are
removed, and they make cross-references rot.

The **title** is an imperative verb phrase in sentence case, like a commit
subject: "Move the scraper primitives into this repo", "Filter floor plans out
of the index". Bug-shaped items are still phrased as the action: "Retire
orphaned variant rows after ID reissue", not "Orphaned variant rows".

The body is a sequence of **bold run-in labels**, each starting a paragraph. A
field may grow supporting material beneath it (lists, tables, code blocks,
evidence) — the labels keep long and short items structurally identical.

- **Goal** (required): The outcome — what should be true once the item is done,
  stated as requirements rather than implementation. Include a sentence or two
  of background: why this matters now, and what larger effort it serves (the
  meta-goal), so the item makes sense in isolation.
- **Done when** (required where definable): The end condition — an observable,
  checkable state, the equivalent of acceptance criteria. Quantify it whenever
  the task has a size, count, or performance dimension ("under 50 ms warm",
  "zero rows matching this audit query"). Avoid criteria that merely restate an
  aspiration ("the code is cleaner", "search feels fast") — if a reviewer could
  not check it, it is not an end condition. If no crisp condition exists, say
  what evidence would settle it.
- **Ideas** (optional): The writer's sketch of a solution — candidate
  approaches, findings from research, pointers to relevant code
  (`src/config.ts:43`), approaches already ruled out and why. This is knowledge
  transfer, not instructions. See "A TODO Is Not a Plan" below.
- **Constraints** (optional): Preferences and boundaries on the solution:
  "prefer the simplest thing that works", "no new dependencies", "must keep the
  CLI entry points", and anything deliberately out of scope.
- **Status** (only once work has started): A single dated one-liner —
  overwritten on change, never appended to. See "Marking Progress and
  Completion" below.

Omit fields that have nothing to say rather than padding them.

### Example

```markdown
## Cache the search matrix in process memory

**Goal:** Search queries should stop re-reading the entire embedding matrix
from SQLite on every request. Each query currently deserialises the full
matrix (~40 MB at today's corpus); at the target corpus size this load will
dominate query latency. Part of keeping brute-force search viable without
introducing a vector database.

**Done when:** A warm query spends under 10 ms loading embeddings (measured,
not estimated), and the web server serves concurrent queries from one shared
matrix.

**Ideas:** Load the matrix once at startup and reuse it across requests,
invalidating on re-index. `load_matrix()` (`src/app/db.py:88`) is the single
entry point, so a small cache keyed by `(source, model)` may suffice.
Memory-mapping was considered and looks unnecessary at this scale.

**Constraints:** No new dependencies. A real vector index (FAISS,
`sqlite-vec`) is out of scope until brute force is measured to be too slow.
```

## A TODO Is Not a Plan

The most common failure mode is writing the item as a step-by-step plan:
numbered implementation steps, exact function signatures, per-file edit
instructions. Resist this even when — especially when — the item is being
translated *from* a plan.

A plan is derived from the codebase at a moment in time and goes stale the
moment the codebase moves. When converting a plan into a TODO item, keep the
*decisions* and discard the *steps*:

- Keep: the chosen approach and why alternatives were rejected, hazards and
  gotchas discovered during research, which code is load-bearing.
- Discard: the ordered step list, boilerplate instructions ("update the README",
  "run the tests"), and any detail the implementer would rediscover in the first
  ten minutes anyway.

**Too plan-like:**

> 1. Add `defaultGender?: "M" | "W"` to `StoreConfig` in `src/types.ts`.
> 1. Read the field in `updateProductInDb()` after line 262.
> 1. Update `stores.json` to set `"defaultGender": "W"` for the store.
> 1. Update the README.

**A sketch of the same knowledge:**

> **Ideas:** A `defaultGender` field on the store config would override the
> title heuristic; `updateProductInDb()` (`src/products/update.ts:262`) already
> has the category in scope at the point gender is assigned, so scoping the
> override to clothing types is cheap if wanted.

## Everything Is Negotiable

Every field is advisory, written against the codebase as it was at the time. The
implementer should verify the item's assumptions before acting and is free to
push back on any part of it — the suggested approach most readily, but even the
goal itself: the codebase may have changed in a way that makes the item partly
or wholly redundant. Pushing back on the goal should be rare and justified, but
it is legitimate.

Raise pushback in conversation with whoever is directing the work — never by
silently reinterpreting the item, and never by writing objections or questions
into `TODO.md` itself.

## Marking Progress and Completion

### Completed items

The default is to **update the item in place** rather than delete it:

1. Append `— done` to the heading:
   `## Filter floor plans out of the index — done`.
1. Rewrite the body as a short past-tense record: what shipped, where it lives
   (commit, module, README section), and any deliberate leftovers. Trim the
   Ideas and Constraints that no longer matter.

Keep the record brief — a paragraph or two. The commit message and PR
description are the home for the full verification story; the TODO entry just
needs enough that a reader doesn't re-propose solved work.

Some file owners prefer completed items **removed** instead, keeping the file as
a pure backlog with git history as the record. Both regimes are valid, but do
not mix them within one file. To tell which regime a file uses: existing
`— done` markers mean update-in-place; their absence proves nothing (nothing may
have been finished yet), so use the update-in-place default unless the person
directing the work has asked for completed items to be removed.

### Partially completed items

Mark the finished part and keep the remainder actionable: either append
`— partially done` to the heading with a **Status** line saying what remains, or
(for large items) split the done portion into its own past-tense subsection and
keep a "Still open" list.

### In-flight items and progress reports

While an item is being worked on, its TODO entry gets at most a brief dated
**Status** line:

```markdown
**Status:** In progress (2026-07-04) — approach validated on one source;
web-server integration remains.
```

When the status changes, **replace** this line rather than adding another — a
stack of dated status lines is a progress report growing in the wrong file.

Narrative progress — what was tried, session logs, intermediate findings — does
**not** belong in `TODO.md`. That is a progress report, a different document
with a different audience; keep it in a separate file. A TODO item that accretes
a work diary stops being scannable as a task list.

## Grounding

The general principles of this skill apply with full force:

- Use absolute dates ("2026-07-04"), never "yesterday" or "last week".
- Cite evidence: real file/line references, query output, measured counts. An
  item justified by data ("an audit found 2,000 affected groups") is far more
  actionable than one justified by adjectives.
- Mark speculation as speculation. Unverified analysis or back-of-envelope
  numbers must say so explicitly ("untested — measure before acting").

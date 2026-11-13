# Complexity Audit

## Contents

- [Overview](#overview)
- [Pass 1: Scanning for what looks bonkers](#pass-1-scanning-for-what-looks-bonkers)
- [Pass 2: Investigating and testing each fix](#pass-2-investigating-and-testing-each-fix)
- [Pass 3: Reviewing strictly for correctness](#pass-3-reviewing-strictly-for-correctness)
- [Pass 4: Evaluating and summarizing](#pass-4-evaluating-and-summarizing)
- [Ground rules](#ground-rules)

## Overview

The audit has two jobs:

1. Check a working project for anything that is bonkers, and show how to fix it
   cleanly.
1. Give proof—grounded in working, correctness-checked changes—that the fix is
   right and worth making.

"Bonkers" means that the project pays far more for something than the job needs:
in machinery a maintainer must understand, in work done at run time (processor
time, wake-ups, polling, calls, network, memory, battery), or in storage, binary
size, dependencies, start-up time, and build or test time. The starting code is
assumed to work. The question is whether it should have this shape.

Work in four passes across isolated copies of the repository or source artifacts
so nothing modifies the original checkout, creates branches or pull requests
unless explicitly requested, or lets concurrent passes interfere with each
other:

1. **Pass 1 — Scan for what looks bonkers.** Read practically every line of the
   project and its history to spot candidate problems without designing patches
   yet.
1. **Pass 2 — Investigate and test each fix.** Try each candidate in its own
   isolated copy—whether changing a setting or dependency, switching algorithms,
   relaxing a constraint, or deleting dead machinery—to see whether the fix is
   clean and the payoff is real, then merge what survives.
1. **Pass 3 — Review strictly for correctness.** Check the resulting changes for
   regressions and subtle edge-case bugs without re-litigating the design.
1. **Pass 4 — Evaluate and summarize.** Re-check whether each fix still pays off
   after correctness repairs, then present a plain-English summary and proof.

## Pass 1: Scanning for what looks bonkers

Read the project before judging any part of it. List all tracked files and read
practically every production and test file, the documentation and instruction
files, the build config, and the commit and review history. Do not stop at the
first two or three oddities, and do not design fixes yet.

Some bonkers things show in the code as it stands: a thread that wakes 40 times
a second to check an empty queue, a hand-written parser beside a library that
already does the job, a setting left at a value that makes everything else work
harder.

More often, each step is fine and only the whole path is bonkers. Projects built
in many small steps accrete accidental complexity, and projects built by coding
agents do so quickly. Each step was a sensible answer to the constraint in front
of it: a rule in an instruction file, a test that had to keep passing, a review
comment, a feature that seemed useful then. One early constraint can cascade: it
forces a workaround, the workaround needs a guard, the guard needs white-box
tests, and round after round of review adds more. Nobody steps back. The result
works, has been reviewed many times, and nobody who knew its purpose would
design it.

For each large or strange construction, trace back to the decision that caused
it and forward to every file, layer, and test that exists because of it. Group
symptoms of one root cause into one candidate so Pass 2 trials do not collide or
stack two fixes for the same problem.

Question the constraints. List the constraints the design is built around,
stated or assumed, and ask of each:

- Is it really needed? Who or what needs it?
- If it were relaxed a little, would the shape of the solution become much
  simpler? For example: the input is always small; latency of a second is fine;
  there is one user; there is one peer; link-layer security or single-process
  ownership already covers what an extra layer guards; a coming release makes a
  whole branch obsolete.

A constraint that costs a great deal and can be relaxed at little loss is the
best finding there is. Do not treat internal machinery as wanted just because
recent review commits or white-box tests added it, and do not treat an unused
internal module or duplicate engine as untouchable just because the package
exports its name—put it on the table so Pass 2 can price removing or replacing
it (as an owner fork if outside callers could exist).

Look for the big structural and runtime problems. Leave out style, naming,
single bugs, small duplicate code, and micro-optimizations on cold or low-rate
paths. Note the project's purpose, outward-facing entry points, constraints on
the table, candidate problems, and earned parts left alone.

## Pass 2: Investigating and testing each fix

Investigate each candidate in its own clean copy—giving each to a fresh subagent
or worker when available, or working through separate copies sequentially—so
trials never interfere with each other. Focus on whether the cost can be cleanly
removed: changing a setting or build flag, using the right dependency or
algorithm, dropping an unnecessary constraint, collapsing duplicate engines or
layers, or deleting dead code. Prefer removing or replacing the source of cost
over layering a cache, fast path, or second format beside the old one. Make the
complete fix build and pass tests in the copy.

The owner trusts the working code and has good reason to doubt you. One false
statement makes them doubt the rest. Each investigation must establish three
things, or drop its candidate:

**The cost is real.** Measure it on an untouched copy by running something.
Count the lines, wake-ups, calls, bytes, packages, or milliseconds for a routine
operation, and isolate the cause rather than citing an unexplained total.

**The fix pays off.** Measure the "after" figure from the working diff, never by
guessing. Payoff is whatever cost the finding removes: wake-ups, power, CPU,
memory, latency, binary or bundle size, dependencies, build or test time, or
code a maintainer must carry (a small config or dependency change can yield a
large runtime or size win without cutting lines). When code size is part of the
claim, separate what goes, what stays, and what new code comes across production
logic, tests, and generated files; moving code removes nothing. Keep one-off
benchmark harnesses in scratch rather than adding bulky scaffolding to the
project's test suite. If you cannot measure something here (no device, no
production), name the measurement that would settle it and give no number. Make
the best case for leaving things alone; if fixing it turns messy, saves little,
or bloats the code and tests without a clear runtime, footprint, or maintenance
win, drop it.

**Who decides is clear.** Read your diff and list everything the construction
does today, including side effects, that stops or changes. Search the whole
project for every removed or changed name, setting, or path, and account for
every reference. If a change deletes white-box tests for removed machinery,
check that kept black-box tests still cover outward behavior, or add the concise
check needed first:

- If nothing visible to users or outside callers changes—same outputs, wire
  compatibility, public API, and guarantees, with no trade-off—no owner decision
  is needed. Claim this only if you compared before and after and found no
  difference.
- If anything visible changes, however small or rare—including relaxing a
  constraint, changing a wire format across versions, trading speed or symbols
  for size, or removing an exported symbol that outside repositories might
  import—it is the owner's decision. Write a fork: "If X is true, do A, which
  saves this much. If not, do B. To settle it: ...". Give the evidence on both
  sides so the owner can settle it quickly.
- Questioning a user-facing feature has a high bar: assume features with real
  callers are wanted unless their cost is huge. Security boundaries, data
  safety, and hardware or platform quirks often justify code that looks
  excessive; find out what real threat or device behavior a mechanism protects
  before questioning it, and distinguish load-bearing protection from theater
  around it.

Merge the surviving fixes in a clean copy (keeping owner-fork candidates
separate when needed) to verify they build and pass tests together without
double-counting overlapping savings or stacking two fixes for the same root
cause.

## Pass 3: Reviewing strictly for correctness

In our experience, simplifying accreted code—or changing settings, dependencies,
concurrency, or build flags—almost always introduces subtle errors even when the
existing test suite stays completely green. Removing intermediate layers,
swapping dependencies, changing compiler or runtime flags, replacing polling
loops with event signaling, batching harnesses, or adding caches creates new
lifecycle, ordering, compatibility, flag-forwarding, and state-isolation edges
that older tests never needed to exercise.

Run a dedicated correctness review on the resulting changes before trusting the
result:

- **Scope to fit the project.** Review the merged diff by default so cross-fix
  interactions across shared lifecycles, configs, or files are caught in one
  pass, or review per fix when individual changes are large and independent. Use
  a fresh reviewer subagent, an external CLI agent, or a separate review pass as
  appropriate; no rigid comment template or rubric is required.
- **Keep strict separation of concerns.** This pass takes the new design as
  given and looks solely for correctness defects: crashes, null or destroy
  re-entrancy, race conditions, lost wake-ups, stale state, config or dependency
  side effects, dropped flags, non-hermetic caches or tests, and weakened
  assertions. Do not ask this pass to judge whether the change eliminated enough
  complexity, and do not re-add speculative fallback layers unless a concrete
  failure path requires them.
- **Fix defects surgically.** Repair confirmed bugs in the scratch copy and
  re-run the build and tests.

## Pass 4: Evaluating and summarizing

Step back after Pass 3 repairs land and evaluate the final state honestly.
Re-run baseline and post-fix measurements from clean copies, pasting every name,
path, count, and commit from command output rather than memory. If fixing the
edge cases found in Pass 3 made a candidate messy or wiped out its payoff, drop
that candidate rather than forcing a disappointing change through. Finding
nothing worth changing is a valid result.

Write in plain English, following the principles behind the Plain English
Campaign's Crystal Mark: short sentences, active voice, everyday words, and a
clear layout. Adapt the structure and length to fit the project rather than
following a rigid template.

Open with what the project is for and a clean, high-signal summary of the
embarrassing mistakes uncovered and what fixing them brings: wasted wake-ups,
power, CPU, memory, or latency saved, binary or dependency footprint cut, leaks
or UI glitches fixed, build or test speedups, whole branches or dead modules
removed, and the honest `git diff` footprint (separating deleted code, new or
replacement logic, config or dependency changes, and tests).

Group findings that need no owner decision separately from findings gated on an
owner fork, and do not add several "if" answers into one headline total. Present
the biggest payoffs first: what is there and how it came to be; why it is
bonkers; the verified fix (clear enough to apply or inspect directly); the
measured before-and-after cost; what stops or changes and how Pass 2 and Pass 3
verified it; and the fork, if there is one. End briefly with what you examined
and left alone, including candidates dropped in Pass 2 or Pass 4.

## Ground rules

- Never modify the original project checkout or create branches or pull requests
  unless explicitly asked. Run every candidate fix, build, test, and review pass
  in isolated copies so nothing interferes with the original or with other
  passes.
- Avoid network calls and paid services. Keep tool caches, state, and temporary
  files inside your scratch directory so tests and trials stay hermetic.
- Do not run project tools against live data or credentials, and do not stop
  processes by broad pattern.
- If tests fail on the untouched project, record it and carry on.
- If you find private data, report counts and sizes, not contents.

# Complexity Audit

The audit has two jobs:

1. Check a working project for anything that is bonkers, and say how to fix it.
1. Give proof, which the owner cannot reasonably refute, that the fix is right.

"Bonkers" means that the project pays far more for something than the job needs:
in machinery a maintainer must understand, in work done at run time (processor
time, wake-ups, polling, calls, network, memory, battery), or in storage, binary
size, dependencies, start-up time, and build or test time. The code is assumed
to be correct. The question is whether it should have this shape.

The audit produces a report, not a patch. Run it in two stages so one pass does
not have to read the whole codebase and guess what a fix would save:

1. **Stage 1 — Find the problems.** Read the codebase, tests, docs, and history
   end to end. Map the project's purpose and constraints, and write down the
   candidate bonkers problems without designing patches yet.
1. **Stage 2 — Build and prove each fix.** Test each candidate in its own clean
   scratch copy—giving each candidate to a fresh subagent or worker when
   available, or working through them one at a time in clean scratch copies when
   working alone. Implement the complete fix, run the build and tests, and
   measure the real saving and side effects from the working diff, dropping
   anything that does not pay off.

Then check that the surviving fixes work together and write the report.

## Stage 1: Finding what may be bonkers

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
symptoms of one root cause into one candidate so Stage 2 fixes do not collide.

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
exports its name—put it on the table so Stage 2 can price removing it (as an
owner fork if outside callers could exist).

Look for the few big structural and runtime problems. Leave out style, naming,
single bugs, small duplicate code, and micro-optimizations on cold or low-rate
paths. Write down the Stage 1 scan with the project's purpose, outward-facing
entry points, constraints on the table, candidate problems (typically 4 to 8),
and one line each for earned parts left alone.

## Stage 2: Building the fix and proving it

Test each candidate from Stage 1 independently in its own clean scratch copy. A
fix is whatever removes the cost: deleting code, collapsing duplicate engines or
layers, changing a setting, using the right dependency or algorithm, or dropping
a constraint. Prefer deleting or replacing machinery over adding a cache, fast
path, or second format beside the old one. Make the complete fix build and pass
tests in the scratch copy.

The owner trusts the working code and has good reason to doubt you. One false
statement makes them doubt the rest. Each Stage 2 investigation must prove three
things, or reject its candidate:

**The cost is real.** Measure it on an untouched copy by running something.
Count the lines, wake-ups, calls, bytes, packages, or milliseconds for a routine
operation. A number does not explain itself: a claim about a cause needs its own
measurement that isolates the cause.

**The fix pays off.** Measure the "after" figure from your working diff, never
by guessing. For lines: what goes, what must stay, what new code comes, and the
net, keeping production logic, tests, and duplicate or generated files apart.
Moving code removes nothing. For any other cost: the count before and after (and
if a fix trades speed or debuggability for size or similar, measure both). Keep
one-off benchmark harnesses in scratch rather than adding bulky measurement
scaffolding to the project's test suite. If you cannot measure something here
(no device, no production), name the measurement that would settle it and give
no number. Make the best case for leaving the code alone; if fixing it saves
little, complicates the code for a tiny saving, or adds more code and test
scaffolding than it removes without a major runtime or footprint win, reject the
candidate.

**The fix is safe, and honest about who decides.** Read your own diff and list
everything the construction does today, including side effects, that stops or
changes. Search the whole project for every removed name or path, and account
for every reference. If your change deletes white-box tests for removed
machinery, say whether kept black-box tests still cover outward behavior, or add
the concise check needed first.

- If nothing visible to users or outside callers changes—same outputs, wire
  compatibility, public API, and guarantees, with no trade-off—no owner decision
  is needed. Claim this only if you compared before and after and found no
  difference.
- If anything visible changes, however small or rare—including relaxing a
  constraint, changing a wire format across versions, trading speed or symbols
  for size, or removing an exported symbol that outside repositories might
  import—it is the owner's decision. Write a fork: "If X is true, do A, which
  saves this much. If not, do B. To settle it: ...". Make it answerable in a
  minute, with evidence on both sides.
- Questioning a user-facing feature has a high bar: assume features with real
  callers are wanted unless their cost is huge. Security boundaries, data
  safety, and hardware or platform quirks often justify code that looks
  excessive; find out what real threat or device behavior a mechanism protects
  before questioning it, and distinguish load-bearing protection from theater
  around it.

Paste every name, path, count, and commit from command output, never from
memory, and give the command.

## The report

Apply the surviving fixes together in a clean scratch copy to check that they
build and pass tests together and so overlapping deletions are never counted
twice. Re-run baseline figures on an unbuilt clean copy. Finding nothing worth
changing is a valid result.

Write in plain English, following the principles behind the Plain English
Campaign's Crystal Mark: short sentences, active voice, everyday words, and a
clear layout. There is no rigid template. Do not use tags or grades, and do not
wrap numbers in code formatting or bold. The reader has ten minutes.

Open with what the project is for and a one-paragraph verdict, in proportion to
what survived. Group findings that need no owner decision separately from
findings that depend on an owner fork, and do not add several "if" answers into
one large total. Within each group, present the biggest payoffs first (aim for
under 300 words each, plus a small price table): what is there and how it came
to be; why that is bonkers; the fix (clear enough to apply from the report
alone); the price table; what stops or changes; how you know; and the fork, if
there is one.

End with what you looked at and left alone (including candidates rejected in
Stage 2), one line each.

## Ground rules

- Do not change the project. Work in scratch copies outside it.
- Avoid network calls and paid services. Keep tool caches, state, and temporary
  files inside your scratch directory.
- Do not run project tools against live data or credentials, and do not stop
  processes by broad pattern.
- If tests fail before you change anything, record it and carry on.
- If you find private data, report counts and sizes, not contents.

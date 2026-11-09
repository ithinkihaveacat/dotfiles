# Capability Skill Guidelines

This guide covers authoring, refactoring, and reviewing capability skills
(`SKILL.md` files and their accompanying reference guides). A capability skill
teaches an agent how to do a class of task: workflows, decision rules, and
bundled tools. Skills that instead record facts about particular systems,
people, or places are knowledge skills; see
[Knowledge Skill Guidelines](knowledge-skills.md). Scripts bundled with a
knowledge skill still follow this guide.

## Intent and Audience

Capability skills provide instructions, workflows, and tools for AI agents
operating in specific domains or codebases.

- **Goal:** Equip AI agents with self-contained, modular capabilities while
  keeping instructions portable across workspaces.
- **Audience:** AI agents (as primary executors) and engineers (as authors and
  maintainers).
- **Tone:** Direct, explanatory, and capability-focused. Prioritize clear
  decision rules, underlying rationale, and task-appropriate degrees of freedom
  over heavy-handed imperatives.

## Core Principles & Decoupling Rule

To ensure skills remain modular, portable, and maintainable across diverse
environments, **design every reusable skill so a user can pick and install it
independently without needing to track down other skills from your personal
collection**.

### Skill Independence & Degrees of Freedom

- **Calibrate Degrees of Freedom:** Match instruction specificity to task
  fragility. Restrict low-freedom, exact commands to truly fragile or
  destructive operations (e.g. database migrations, security boundaries). For
  heuristics, reviews, and workflows, provide clear guidelines and rely on the
  model's context-aware reasoning.
- **No Sibling Skill Dependencies:** Do not mandate or cross-reference other
  skills from your own personal repository, or assume their `scripts/` are
  installed.
  - **Shared Catalog Exception:** Public skills may reference widely available
    public or third-party skills, and organization-internal skills may reference
    shared, organization-wide skills (e.g., via canonical registry names or
    shared monorepo paths) that any colleague in that environment can resolve.
  - **Strictly Personal Skills:** Bespoke skills intended solely for the
    author's own workstation (that others will never pick and install on their
    own) are exempt from standalone portability rules.
- **No Relative Skill Paths:** In reusable skills, do not link across skill
  directories using relative Markdown paths (e.g., `../other-skill/SKILL.md` or
  `skills/other-skill/SKILL.md`). When skills are distributed individually or
  loaded in different catalog layouts, these links break.
- **No Path Assumptions:** Never assume that another skill's `scripts/`
  directory is present in the current working directory, relative path, or
  `PATH` (e.g., calling `scripts/adb-tile-add` from inside a different skill).
- **No Hardcoded Overlay Paths:** Never hardcode paths to personal repository
  overlay structures (e.g., `~/.dotfiles/skills/...`, `~/.corp/skills/...`, or
  `~/.private/skills/...`). Always resolve skill resources dynamically relative
  to `SKILL.md` or the script's own location.

### Structure, Progressive Disclosure & Publication Safety

- **Trigger-Structured Frontmatter Descriptions:** End the YAML `description`
  with explicit `Use when ...` and `Don't use for ...` clauses so agents can
  route to (or skip) the skill from the catalog entry alone.
- **Single-Source Decision Tables & Caveats:** Keep `SKILL.md` decision-matrix
  cells concise (one or two sentences) and state full benchmark caveats once in
  the relevant section rather than repeating the same multi-line caveat block
  across `SKILL.md` and `references/`.
- **Public Safety Across `SKILL.md` and `references/`:** Distributable skills
  and all files in their `references/` subdirectories must not contain internal
  bug or task IDs, internal shortlinks, unlaunched hardware codenames, internal
  test-harness jargon, or proprietary monorepo paths.

## Capability-First Authoring & Exemplar Mentions

While skills must not be tightly coupled, skills often operate in ecosystems
where complementary tools or helper scripts exist. To reconcile independence
with helpfulness:

### The Capability-First Pattern

Describe required actions in terms of **generic system capabilities, standard
CLI primitives, and functional requirements**.

1. **Primary Requirement (Capability):** State the functional objective clearly
   using standard, ubiquitous tools or system binaries (e.g., `adb`, `git`,
   `curl`, `python3`, `bash`).
1. **Exemplar Suggestion (Non-Binding Example):** Mention specialized helper
   scripts or tools as *illustrative examples* of the required capability, using
   flexible/conditional language so the agent recognizes them if available in
   its loaded workspace context.

## Generalizing from Tasks & Evaluations (Anti-Overfitting)

Skills are frequently extracted from hands-on tasks or refined against benchmark
evaluations. A skill must teach how to approach a *class of problems* across any
repository, not how to pass a specific test case:

- **Never Leak Task Framing, Grader Mechanics, or Fixture Literals:** Write for
  ongoing development in any codebase, not for finishing an assignment. Omit
  *"before completing the task"* cleanup steps, grader heuristics
  (`stddev > 0`), sandbox quirks (`Container $HOME is read-only`), and
  fixture-specific literals (hardcoded hex colors, initials, or bespoke asset
  scripts).
- **Keep Project Quirks Conditional & Avoid Cherry-Picked API Lists:** Frame
  unusual fixture configurations (`android.builtInKotlin=false`, `src/debug/`
  file moves) conditionally (`If a project configures X...`) or in
  Troubleshooting rather than as mandatory workflow steps, and state
  package-level API rules rather than labeling the few symbols used by benchmark
  tasks as "Essential".
- **Explain the "Why" Once Instead of Repeating Rigid `ALWAYS`/`NEVER` Bans:**
  Repeating all-caps `NEVER` or `MUST` warnings across multiple sections is a
  yellow flag that crowds out context. When models repeatedly hallucinate an API
  call or import, explain the underlying API design or asymmetry once in the
  relevant reference section so the model understands *why*.
- **Fix Flawed Evaluations Rather Than Polluting the Skill:** Keep the skill
  general even if narrow, overfitted hints score higher on a benchmark. If
  removing a task-specific hint causes a severe regression, clarify the general
  domain concept or fix the benchmark task/assertion itself.

## Empirical Claims, Approximate Figures & External Evidence Logging

When an agent conducts direct empirical research, benchmarks, code audits, or
document reviews and updates a skill based on that evidence, separate the
**actionable engineering facts** that belong in the skill from the **raw
experimental evidence** that backs them (these rules apply equally to `SKILL.md`
and to all `references/` files inside the skill; exact raw tables belong in the
external evidence repository):

- **State Concrete Engineering Facts Directly in the Skill:** Write the skill
  around clear decision rules, mechanisms, and practical guidelines rather than
  narrating how an experiment was run. A reader with only the skill does not
  need to be able to reproduce the underlying benchmark from the skill text
  alone, though briefly hinting at the empirical basis (for example, *"in
  repeated benchmark runs"* or *"observed in kernel suspend traces"*) is often
  helpful to ground the rule.
- **Use Approximate, Outward-Rounded Performance Figures in the Skill:** Avoid
  packing `SKILL.md` or `references/` with hyper-specific measurement ranges,
  per-rail breakdowns, or estimator comparisons (for example, prefer *"batching
  writes cut write latency by roughly 70–80% in one benchmark"* over *"cuts
  write latency from 142.38 ms to 31.14–38.92 ms, with -64.2% to -71.8% on fsync
  calls and -28.4% on journal commits"*). Overly granular numbers invite
  unnecessary debate about experimental setup and distract from sound general
  principles.
- **Approximate Faithfully (Round Outward and Keep Meaning-Changing
  Qualifiers):** Round outward so the stated range still encloses what was
  measured, and never shift or narrow it (for example, `13–24%` rounds to
  `"roughly 13–25%"` or `"about an eighth to a quarter"`, never `"15–20%"` or
  `"15–25%"`). Keep any qualifier that changes how a reader would act: sample
  size (*"in one overnight run"*), conditions that differ from production use
  (*"phone on USB power"*), and what was not measured. Label figures that are
  projections rather than direct measurements.
- **Label Projections and Mechanisms Under Study:** In capability skills, causal
  mechanisms under active study and model-based projections are permitted when
  explicitly labeled (*"model estimate"*, *"projected"*, *"under
  investigation"*) and kept distinct from measured headline figures.
- **Record Detailed Sourcing and Evidence in Associated Persistent Storage (When
  Available):** Whenever a skill change is backed by substantial direct
  research, benchmark runs, or document audits—and an associated project
  tracker, benchmark repository, or commit log exists—record the full
  methodology, raw data, exact numbers, and commit/artifact trail in that
  external persistent storage so the rationale behind any skill claim can be
  reconstructed from the combination of the skill, git history, and project
  records. (Do not treat this as an absolute prerequisite when updating a skill
  from lightweight observations or imperfect sources where no separate research
  log is warranted, and never hardcode links to private tracker paths inside a
  reusable skill.)

## Anti-Patterns & Corrected Examples

### Example 1: Direct Skill Mandate vs. Capability-First with Exemplar

**DON'T (Direct Coupling & Hard Dependency):**

```markdown
Follow this step-by-step methodology when analyzing an APK. Ensure you leverage
the `apk` and `adb` skills where applicable. Use the `adb` skill tools to
capture screenshots.
```

**DO (Capability-First with Exemplar Suggestion):**

```markdown
Follow this step-by-step methodology when analyzing an APK. Leverage binary
analysis and ADB device management tools where applicable.

To capture an on-device preview screenshot, use an ADB-based screen capture
utility (such as `adb-screenshot` if available in your workspace environment, or
standard `adb shell screencap`).
```

### Example 2: Implicit Script Execution vs. Standalone Instructions

**DON'T (Assuming Script Directory Alignment):**

```markdown
# 1. Add tile to carousel and switch active display (adb skill)
scripts/adb-tile-add com.example/.MyTileService
scripts/adb-tile-switch 0
```

**DO (Self-Contained Primaries with Optional Helper Hints):**

```markdown
### 1. Carousel Setup

Add the tile component to the carousel and focus its display. You can execute
raw ADB commands or use high-level ADB tile helpers if available in your
workspace:

# Standard ADB broadcast command:
adb shell am broadcast -a com.google.android.wearable.app.DEBUG_SURFACE --es operation add-tile --ecn component com.example/.MyTileService --ei type 0

# (Or run workspace tile helpers like `adb-tile-add com.example/.MyTileService` if present)
```

> [!NOTE] **Active Experiment — Bundled Script Discovery (`taskgo`):** A new
> approach to referencing bundled scripts across heterogeneous environments is
> currently being tested in `taskgo/SKILL.md`. Instead of assuming a script is
> on `$PATH` or located at `./scripts/` in CWD, the skill documents both optimal
> `$PATH` execution (`taskgo <cmd>`) and dynamic anchor resolution
> (`<skill-dir>/scripts/taskgo <cmd>`, where `<skill-dir>` is the directory
> containing `SKILL.md`). If this pattern proves effective, consider deploying
> it to other skills that bundle helper scripts.

### Example 3: Cross-Skill Relative Hyperlinks vs. Functional Topic References

**DON'T (Broken Relative Link):**

```markdown
For details on caching and offline operation, see [caching](../coding-standards/references/caching.md).
```

**DO (Self-Contained Reference or Generic Standards Reference):**

```markdown
For details on HTTP caching and offline fallback policies, ensure response
artifacts are saved locally under `$XDG_CACHE_HOME` or consult the project's
coding standards documentation on caching.
```

### Example 4: Monolithic Umbrella Skill vs. Clean Boundary

**DON'T (Scope Duplication):**

```markdown
# My Umbrella Skill
This skill includes instructions for deploying HTML reports using Zipline:
[50 lines copying Zipline CLI upload arguments and web flags]
```

**DO (Clean Functional Boundary):**

```markdown
# My Skill

### Report Hosting

To host generated HTML reports, publish the output directory using your
workspace's preferred web hosting utility or static file server (such as
`zipline upload` or local HTTP preview).
```

### Example 5: Benchmark Overfitting vs. General Domain Guidance

**DON'T (Teaching to the Test / Leaking Eval Mechanics):**

```markdown
Generate a 400x400 PNG with `#2B2930` background and `'JD'` initials so the
grader's pixel variance check (`stddev > 0`) passes. Before completing the task,
delete any temporary Python scripts so `git status` is clean.
```

**DO (General Domain Rule):**

```markdown
Provide a representative `@drawable/widget_preview` PNG that depicts the
widget's layout (cards, icons, or progress indicators) rather than a blank or
solid-color placeholder.
```

## Bundled Scripts & Generated Command Indexes

When a skill bundles executable utilities or helper tools in `scripts/`:

1. **Keep `SKILL.md` Lean:** Do not copy exhaustive command-line options, flag
   tables, or multi-page `--help` text directly into `SKILL.md`. Keep the main
   skill file focused on high-signal workflows and operational rules.

1. **Provide `references/command-index.md`:** For any skill containing
   executable utilities in `scripts/`, provide a `references/command-index.md`
   file that embeds auto-generated `--help` blocks delimited by marker comments:

   ```markdown
   <!-- generated: ../scripts/<script-name> --help -->
   (generated block)
   <!-- /generated -->
   ```

1. **Synchronize via `command-index-format`:** Never edit content between
   markers by hand. Run `bin/command-index-format` to refresh blocks directly
   from script `usage()` text.

1. **Link from `SKILL.md`:** In `SKILL.md`, link to
   `[Command Index](references/command-index.md)` both near the tooling overview
   and under `## Reference Material`.

## Summary Checklist

Before publishing or committing a reusable skill, verify that:

- [ ] No hard mandates or cross-references to sibling skills in your personal
  collection exist (referencing shared public or organization-wide skills is
  acceptable).
- [ ] No relative Markdown links point outside the skill's own folder tree
  (`../`).
- [ ] No shell code blocks execute scripts belonging to another skill unless the
  script is in system `PATH` or explicitly checked for.
- [ ] All filesystem paths are resolved dynamically or relative to the skill's
  own root directory.
- [ ] Secondary actions describe the required *capability* first, offering
  specific tool names only as non-binding examples.
- [ ] Instructions teach general domain procedures rather than overfitting to
  benchmark tasks (no leaked grader metrics, container quirks, or fixture
  literals) and explain API asymmetries once with their *why* instead of
  repeating `NEVER`/`MUST` bans.
- [ ] Empirical performance claims in `SKILL.md` and `references/` use
  approximate, outward-rounded figures that enclose the measured range, preserve
  meaning-changing qualifiers, and explicitly label projections or mechanisms
  under study, while detailed raw benchmark tables are recorded in associated
  persistent project/git storage when available.
- [ ] Frontmatter `description` includes trigger clauses (`Use when...` /
  `Don't use for...`), decision tables are single-sourced without repeating
  multi-line caveats, and no internal IDs, codenames, or proprietary paths leak
  into distributable skill files.
- [ ] If the skill bundles helper tools in `scripts/`, an auto-generated
  `references/command-index.md` is provided, refreshed via
  `command-index-format`, and linked from `SKILL.md`.

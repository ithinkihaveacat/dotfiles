# Agent Skill Guidelines

This guide covers authoring, refactoring, and reviewing Agent Skills (`SKILL.md`
files and their accompanying reference guides).

## Intent and Audience

Agent skills provide instructions, workflows, and tools for AI agents operating
in specific domains or codebases.

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
- [ ] If the skill bundles helper tools in `scripts/`, an auto-generated
  `references/command-index.md` is provided, refreshed via
  `command-index-format`, and linked from `SKILL.md`.

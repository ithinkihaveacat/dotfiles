# Agent Skill Guidelines

Agent Skills (`SKILL.md` files and their accompanying reference guides) provide
instructions, workflows, and tools for AI agents operating in specific domains
or codebases.

To ensure skills remain modular, portable, and maintainable across diverse
environments (local Git repositories, CitC workspaces, cloud runtimes, Skill Hub
marketplace), **every skill must be designed as an independent, self-contained
unit of capability**.

______________________________________________________________________

## Core Principles & Decoupling Rule

### 1. Skill Independence & Self-Containment

- **No Hard Skill Dependencies:** A skill MUST NOT directly mandate the use of
  another skill, specify another skill as a strict prerequisite, or instruct the
  agent to "activate the X skill".
- **No Relative Skill Paths:** Never link across skill directories using
  relative Markdown paths (e.g., `../other-skill/SKILL.md` or
  `skills/other-skill/SKILL.md`). When skills are distributed individually or
  loaded in different catalog layouts, these links break.
- **No Path Assumptions:** Never assume that another skill's `scripts/`
  directory is present in the current working directory, relative path, or
  `PATH` (e.g., calling `scripts/adb-tile-add` from inside a different skill).
- **No Hardcoded Overlay Paths:** Never hardcode paths to specific repository
  overlay structures (e.g., `~/.dotfiles/skills/...`, `~/.corp/skills/...`, or
  `~/.private/skills/...`). Always resolve skill resources dynamically relative
  to `SKILL.md` or the script's own location.

______________________________________________________________________

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

______________________________________________________________________

## Anti-Patterns & Corrected Examples

### Example 1: Direct Skill Mandate vs. Capability-First with Exemplar

❌ **Incorrect (Direct Coupling & Hard Dependency):**

```markdown
Follow this step-by-step methodology when analyzing an APK. Ensure you leverage
the `apk` and `adb` skills where applicable. Use the `adb` skill tools to
capture screenshots.
```

✅ **Correct (Capability-First with Exemplar Suggestion):**

```markdown
Follow this step-by-step methodology when analyzing an APK. Leverage binary
analysis and ADB device management tools where applicable.

To capture an on-device preview screenshot, use an ADB-based screen capture
utility (such as `adb-screenshot` if available in your workspace environment, or
standard `adb shell screencap`).
```

______________________________________________________________________

### Example 2: Implicit Script Execution vs. Standalone Instructions

❌ **Incorrect (Assuming Script Directory Alignment):**

```markdown
# 1. Add tile to carousel and switch active display (adb skill)
scripts/adb-tile-add com.example/.MyTileService
scripts/adb-tile-switch 0
```

✅ **Correct (Self-Contained Primaries with Optional Helper Hints):**

```markdown
### 1. Carousel Setup

Add the tile component to the carousel and focus its display. You can execute
raw ADB commands or use high-level ADB tile helpers if available in your
workspace:

# Standard ADB broadcast command:
adb shell am broadcast -a com.google.android.wearable.app.DEBUG_SURFACE --es operation add-tile --ecn component com.example/.MyTileService --ei type 0

# (Or run workspace tile helpers like `adb-tile-add com.example/.MyTileService` if present)
```

______________________________________________________________________

### Example 3: Cross-Skill Relative Hyperlinks vs. Functional Topic References

❌ **Incorrect (Broken Relative Link):**

```markdown
For details on caching and offline operation, see [caching](../coding-standards/references/caching.md).
```

✅ **Correct (Self-Contained Reference or Generic Standards Reference):**

```markdown
For details on HTTP caching and offline fallback policies, ensure response
artifacts are saved locally under `$XDG_CACHE_HOME` or consult the project's
coding standards documentation on caching.
```

______________________________________________________________________

### Example 4: Monolithic Umbrella Skill vs. Clean Boundary

❌ **Incorrect (Scope Duplication):**

```markdown
# My Umbrella Skill
This skill includes instructions for deploying HTML reports using Zipline:
[50 lines copying Zipline CLI upload arguments and web flags]
```

✅ **Correct (Clean Functional Boundary):**

```markdown
# My Skill

### Report Hosting

To host generated HTML reports, publish the output directory using your
workspace's preferred web hosting utility or static file server (such as
`zipline upload` or local HTTP preview).
```

______________________________________________________________________

## Summary Checklist for Skill Authors

Before publishing or committing a skill, verify that:

- [ ] No explicit mentions of "activate skill X" or hard mandates for other
  skills exist.
- [ ] No relative Markdown links point outside the skill's own folder tree
  (`../`).
- [ ] No shell code blocks execute scripts belonging to another skill unless the
  script is in system `PATH` or explicitly checked for.
- [ ] All filesystem paths are resolved dynamically or relative to the skill's
  own root directory.
- [ ] Secondary actions describe the required *capability* first, offering
  specific tool names only as non-binding examples.

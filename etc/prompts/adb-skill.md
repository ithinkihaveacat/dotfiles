# Prompt: Create Android ADB/Wear OS Skill

Create an Agent Skill that helps agents manipulate Android devices via ADB, with
emphasis on Wear OS devices. This skill should bundle existing scripts and
strongly encourage agents to use them over raw ADB commands.

## Goal

Produce a self-contained skill directory at `etc/skills/adb/` that an agent can
use to:

1. Run bundled scripts directly (fast, deterministic, with extra features)
2. Only fall back to raw ADB commands when scripts fail due to missing
   dependencies

**Important:** Scripts provide significant value beyond raw commands (e.g.,
`adb-screenshot` auto-detects Wear OS displays and applies circular masks, wakes
the device, copies to clipboard). The skill must make agents prefer scripts by
default and only consult raw commands as a last resort.

## Research Phase

Before creating files, research the following:

1. **Review the Agent Skills specification** at
   <https://agentskills.io/specification.md> to understand frontmatter
   requirements, directory structure, and naming conventions.

2. **Examine relevant scripts in `bin/`**:
   - All `bin/adb-*` scripts (~40 scripts for device manipulation, screenshots,
     tiles, demo mode, key events, dumpsys, etc.)
   - All `bin/wearableservice-*` scripts (4 scripts for Wear OS data layer
     inspection)
   - `bin/packagename` (unified package management with ~20 subcommands)
   - All `bin/apk-*` scripts (~16 scripts for APK analysis)

   For each script, understand:
   - Purpose and when to use it
   - The underlying `adb` commands
   - Dependencies (look for `require` lines)

## Deliverable Structure

Create this exact structure:

```text
etc/skills/adb/
├── SKILL.md              # Required: frontmatter + instructions
├── scripts/              # Copies of all relevant scripts
└── references/           # Reference documentation
    ├── command-index.md
    └── troubleshooting.md
```

Do not create extra files like README.md, CHANGELOG.md, or INSTALLATION.md.

## Script Selection

Symlink these scripts into `scripts/` using relative paths:

**Required (core functionality):**

- All `bin/adb-*` scripts
- All `bin/wearableservice-*` scripts
- `bin/packagename`

**Optional (if directly useful for ADB workflows):**

- `bin/apk-*` scripts that analyze installed packages (e.g., `apk-tiles`)

Preserve filenames and executable permissions.

### Transitive Script Dependencies (Required)

If any script you symlink invokes other scripts by name (for example,
`apk-tiles` calling `apk-cat-manifest`), you must also symlink those invoked
scripts into `scripts/` so the skill remains self-contained.

How to detect this:

- Search for direct invocations of other `bin/` scripts (command names like
  `apk-cat-manifest`, `adb-*`, etc.) in the script body.
- Do not rely on `require` lines alone; scripts may call other scripts without
  declaring them via `require`.

## SKILL.md Requirements

### Frontmatter

Follow the Agent Skills specification exactly:

```yaml
---
name: adb
description: [See below]
---
```

**Name requirements:**

- Lowercase letters, numbers, hyphens only
- Max 64 characters
- Must match directory name

**Description requirements (critical for discovery):**

- Max 1024 characters
- Write in **third person** (the description is injected into system prompts)
- Include what the skill does AND when to use it
- End with explicit trigger phrases using "Triggers:" prefix for reliable
  discovery across different agent implementations

Include these trigger phrases: adb, android device, wear os, wearable, tile,
screenshot, screen recording, dumpsys, logcat

Example pattern:

```yaml
description: >
  Manipulates Android devices via ADB with emphasis on Wear OS. Provides scripts
  for screenshots, screen recording, tile management, WearableService
  inspection, package operations, and device configuration. Use when working
  with adb, Android devices, Wear OS watches, tiles, wearable data layer,
  dumpsys, or device debugging. Triggers: adb, android device, wear os,
  wearable, tile, screenshot, screen recording, dumpsys, logcat.
```

**Compatibility requirements (recommended):**

- Max 500 characters
- Include if the skill has external dependencies or environment requirements
- Mention required command-line tools, network access needs, or target platforms
- Example:
  `compatibility: Requires adb. Some scripts require magick (ImageMagick), aapt, or scrcpy. Designed for filesystem-based agents with bash access.`

For maximum compatibility across skill loaders, prefer a single-line
`description:` value and avoid YAML block scalars like `description: |` (some
implementations treat multi-line descriptions inconsistently). If you need line
wrapping, prefer a folded scalar (`description: >`) rather than a literal block
(`description: |`).

### Body Content

Keep the body under 500 lines. Structure it for progressive disclosure—agents
load this only when the skill activates, so be concise.

#### Scripts First (Critical)

Add a prominent section at the top of SKILL.md body titled "Important: Use
Scripts First" that:

1. Tells agents to **ALWAYS prefer scripts** over raw `adb` commands
2. Notes that scripts are located in the `scripts/` subdirectory of the skill's
   folder
3. Lists specific features scripts provide that raw commands don't:
   - Automatic circular masking for Wear OS screenshots
   - Device wake-up before capture
   - Clipboard integration on macOS
   - Sensible default filenames and error handling
4. Explains when to read script source: if a script doesn't do exactly what's
   needed, or fails due to missing dependencies. The scripts encode solutions to
   edge cases and platform quirks—they serve as valuable reference when building
   similar functionality.

This section ensures agents see the scripts-first guidance immediately when the
skill activates.

#### Quick Start

- How to target a device (`ANDROID_SERIAL` for multiple devices)
- 6-7 highest-value commands to run first:
  - `adb-screenshot` — **always use instead of raw `adb shell screencap`**
    (auto-detects Wear OS, applies circular mask, wakes device, copies to
    clipboard)
  - `adb-tile-add` + `adb-tile-show` workflow
  - `adb-activities` (discover launcher, TV, settings activities)
  - `wearableservice-capabilities` / `wearableservice-nodes`
  - `packagename tiles PACKAGE`
  - `adb-device-properties`
- Use paths relative to the skill: `scripts/adb-screenshot`

#### Script Index

A compact reference organized by task category. For each category, list scripts
with one-line descriptions:

- **Device basics**: connection, wake/sleep, properties, API level
- **Media capture**: screenshots, screen recording
- **Tile management**: add, show, remove, list tiles
- **Activity discovery**: list activities by category (launcher, TV, settings)
- **Package operations**: launch, stop, uninstall, permissions, services
- **Wear OS data layer**: capabilities, nodes, data items, RPCs
- **Display/demo mode**: demo on/off, font scale, touches, theme

Point to `references/command-index.md` for detailed usage.

#### Safety Notes

- Debug broadcasts are Wear OS-specific and may not work on all devices
- Some operations require USB debugging enabled
- The skill avoids destructive actions unless explicitly requested

## Reference Files

### references/command-index.md

If this file is longer than 100 lines, include a `## Contents` section at the
top (a short table of contents) so agents can see the full scope even when
previewing the file.

For each bundled script, document:

- **Purpose** (1 line)
- **Dependencies** (from `require` lines)
- **Usage examples**
- **Raw ADB command(s)** (verbatim or near-verbatim from script)
- **Wear OS notes** (where applicable)

Organize by category matching the Script Index in SKILL.md.

### references/troubleshooting.md

If this file is longer than 100 lines, include a `## Contents` section at the
top (a short table of contents) so agents can see the full scope even when
previewing the file.

Cover:

- ADB connection issues (no devices, unauthorized, offline, multiple devices)
- Using `ANDROID_SERIAL` to target specific devices
- Missing dependencies (magick, scrcpy, etc.)
- Wear OS quirks (square displays, debug broadcasts)
- Common error patterns and solutions

## Writing Guidelines

- Be concise. Agents are intelligent; provide what they don't already know.
- Use imperative form ("Run this command" not "You can run this command").
- Include concrete examples with realistic package/component names.
- Emphasize scripts over raw commands. Scripts provide features (circular masks,
  device wake-up, clipboard integration) that raw commands don't.
- Do not duplicate raw commands from scripts into SKILL.md. Tell agents to read
  the script source if they need the underlying command.
- Keep file references one level deep from SKILL.md.

## Quality Checklist

Before finalizing, verify:

- [ ] Skill directory exists at `etc/skills/adb/`
- [ ] `SKILL.md` has valid frontmatter matching the spec
- [ ] Description is in third person and includes trigger phrases
- [ ] Compatibility field lists required tools and environment (adb, magick,
      etc.)
- [ ] `SKILL.md` body is under 500 lines
- [ ] `SKILL.md` has "Important: Use Scripts First" section at top of body
- [ ] `adb-screenshot` entry explicitly says to use it instead of raw screencap
- [ ] `scripts/` contains symlinks to all `bin/adb-*`, `bin/wearableservice-*`,
      and `bin/packagename` scripts
- [ ] Scripts are executable (`chmod +x`)
- [ ] `references/command-index.md` documents each script with raw commands
- [ ] `references/troubleshooting.md` covers common issues
- [ ] Raw ADB commands are NOT in SKILL.md body (agents read script source)
- [ ] Every file in `scripts/` is documented in `references/command-index.md`
      and referenced from the `SKILL.md` Script Index (no undocumented scripts)
- [ ] No extraneous files (README.md, etc.)
- [ ] Examples use realistic Android component/package names

## Implementation Notes

- Use `mkdir -p` to create directories
- Use `ln -s` to create relative symlinks (e.g.,
  `ln -s ../../../../bin/script scripts/script`)
- Verify executable bits with `chmod +x scripts/*` if needed
- Do not modify original `bin/` scripts—only symlink into the skill
- Test that symlinked scripts work from the skill directory

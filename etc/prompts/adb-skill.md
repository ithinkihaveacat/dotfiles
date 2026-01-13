# Prompt: Create Android ADB/Wear OS Skill

Create an Agent Skill that helps agents manipulate Android devices via ADB, with
emphasis on Wear OS devices. This skill should bundle existing scripts and
document both script-first and raw-ADB-fallback approaches.

## Goal

Produce a self-contained skill directory at `skills/android-adb-wear/` that an
agent can use to:

1. Run bundled scripts directly (fast, deterministic)
2. When scripts fail (missing dependencies, environment issues), extract raw ADB
   commands from those scripts as an authoritative fallback

## Research Phase

Before creating files, research the following:

1. **Review the Agent Skills specification** at
   <https://agentskills.io/specification> to understand frontmatter
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
skills/android-adb-wear/
├── SKILL.md              # Required: frontmatter + instructions
├── scripts/              # Copies of all relevant scripts
└── references/           # Reference documentation
    ├── command-index.md
    └── troubleshooting.md
```

Do not create extra files like README.md, CHANGELOG.md, or INSTALLATION.md.

## Script Selection

Copy these scripts into `scripts/`:

**Required (core functionality):**

- All `bin/adb-*` scripts
- All `bin/wearableservice-*` scripts
- `bin/packagename`

**Optional (if directly useful for ADB workflows):**

- `bin/apk-*` scripts that analyze installed packages (e.g., `apk-tiles`,
  `apk-badging`)

Preserve filenames and executable permissions. Use real copies, not symlinks.

### Transitive Script Dependencies (Required)

If any script you copy invokes other scripts by name (for example, `apk-tiles`
calling `apk-cat-manifest`), you must also copy those invoked scripts into
`scripts/` so the skill remains self-contained.

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
name: android-adb-wear
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
- Include trigger phrases: adb, android device, wear os, watch, tiles,
  WearableService, dumpsys, screenshot, screenrecord, wearable data layer

Example pattern:

```yaml
description: >
  Manipulates Android devices via ADB with emphasis on Wear OS. Provides scripts
  for screenshots, screen recording, tile management, WearableService
  inspection, package operations, and device configuration. Use when working
  with adb, Android devices, Wear OS watches, tiles, wearable data layer,
  dumpsys, or device debugging.
```

For maximum compatibility across skill loaders, prefer a single-line
`description:` value and avoid YAML block scalars like `description: |` (some
implementations treat multi-line descriptions inconsistently). If you need line
wrapping, prefer a folded scalar (`description: >`) rather than a literal block
(`description: |`).

### Body Content

Keep the body under 500 lines. Structure it for progressive disclosure—agents
load this only when the skill activates, so be concise.

#### Quick Start

- How to target a device (`ANDROID_SERIAL` for multiple devices)
- 5-6 highest-value commands to run first:
  - `adb-screenshot` (with circular mask for Wear OS)
  - `adb-tile-add` + `adb-tile-show` workflow
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
- **Package operations**: launch, stop, uninstall, permissions, services
- **Wear OS data layer**: capabilities, nodes, data items, RPCs
- **Display/demo mode**: demo on/off, font scale, touches, theme

Point to `references/command-index.md` for detailed usage.

#### Raw ADB Fallback

This is critical. Teach agents how to extract raw ADB commands when scripts
don't work:

1. Open the script in `scripts/`
2. Find the `require` lines to identify dependencies
3. Locate the core `adb` command(s)
4. Run them manually, adapting as needed

Include worked examples:

##### Tile Workflow

```bash
# From adb-tile-add:
adb shell am broadcast \
  -a com.google.android.wearable.app.DEBUG_SURFACE \
  --es operation add-tile \
  --ecn component "com.example/.MyTileService"

# From adb-tile-show:
adb shell am broadcast \
  -a com.google.android.wearable.app.DEBUG_SYSUI \
  --es operation show-tile \
  --ei index 0
```

##### WearableService Dump

```bash
# From wearableservice-capabilities:
adb exec-out dumpsys activity service WearableService | \
  sed -n '/CapabilityService/,/######/p'
```

##### Screenshot With Circular Mask

```bash
# From adb-screenshot (for square Wear OS displays):
adb exec-out "screencap -p" | magick - \
  -alpha set -background none -fill white \
  \( +clone -channel A -evaluate set 0 +channel \
     -draw "circle %[fx:(w-1)/2],%[fx:(h-1)/2] %[fx:(w-1)/2],0.5" \) \
  -compose dstin -composite output.png
```

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
- Document raw ADB commands prominently—they're essential fallbacks.
- Keep file references one level deep from SKILL.md.

## Quality Checklist

Before finalizing, verify:

- [ ] Skill directory exists at `skills/android-adb-wear/`
- [ ] `SKILL.md` has valid frontmatter matching the spec
- [ ] Description is in third person and includes trigger phrases
- [ ] `SKILL.md` body is under 500 lines
- [ ] `scripts/` contains copies of all `bin/adb-*`, `bin/wearableservice-*`,
      and `bin/packagename` scripts
- [ ] Scripts are executable (`chmod +x`)
- [ ] Both script-first AND raw-ADB-fallback approaches are documented
- [ ] `references/command-index.md` documents each script with raw commands
- [ ] `references/troubleshooting.md` covers common issues
- [ ] Every file in `scripts/` is documented in `references/command-index.md`
      and referenced from the `SKILL.md` Script Index (no undocumented scripts)
- [ ] No extraneous files (README.md, etc.)
- [ ] Examples use realistic Android component/package names

## Implementation Notes

- Use `mkdir -p` and `cp -p` to create directories and copy files
- Verify executable bits with `chmod +x scripts/*` if needed
- Do not modify original `bin/` scripts—only copy into the skill
- Test that copied scripts work from the skill directory

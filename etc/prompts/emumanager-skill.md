# Prompt: Create Android Emulator Manager Skill

Create an Agent Skill that helps agents manage the Android SDK, emulators, and
AVDs (Android Virtual Devices). This skill should document the `emumanager`
script's capabilities and strongly encourage agents to use the script over raw
SDK commands.

## Goal

Produce a self-contained skill directory at `etc/skills/emumanager/` that an
agent can use to:

1. Run the bundled `emumanager` script directly (fast, deterministic, with
   helpful error messages and sensible defaults)
2. Only fall back to raw SDK commands when the script fails due to missing
   dependencies

**Important:** The `emumanager` script provides significant value beyond raw
commands (e.g., automatic system image selection, boot completion detection,
device type presets). The skill must make agents prefer the script by default
and only consult raw commands as a last resort by reading the script source.

## Research Phase

Before creating files, research the following:

1. **Review the Agent Skills specification and best practices**:
   - Specification: <https://agentskills.io/specification.md>
   - Best practices:
     <https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices>

2. **Examine the `bin/emumanager` script thoroughly**:
   - All subcommands: `bootstrap`, `doctor`, `list`, `info`, `create`, `start`,
     `stop`, `delete`, `download`, `images`, `outdated`, `update`
   - The underlying `sdkmanager`, `avdmanager`, `emulator`, and `adb` commands
   - Dependencies (look for `require` and `require_sdk` calls)
   - Environment variables used (`ANDROID_HOME`, `ANDROID_USER_HOME`)
   - Device type options (`--mobile`, `--phone`, `--wear`, `--watch`, `--tv`,
     `--auto`)
   - Start mode flags (`--cold-boot`, `--wipe-data`)

   For each subcommand, understand:
   - Purpose and when to use it
   - The underlying raw commands
   - Input/output format
   - Error conditions

## Deliverable Structure

Create this exact structure:

```text
etc/skills/emumanager/
├── SKILL.md              # Required: frontmatter + instructions
├── scripts/              # Copy of the emumanager script
└── references/           # Reference documentation
    ├── command-index.md
    └── troubleshooting.md
```

Do not create extra files like README.md, CHANGELOG.md, or INSTALLATION.md.

## Script Selection

Symlink `bin/emumanager` into `scripts/` using a relative path. Preserve the
filename and executable permissions.

### Transitive Script Dependencies

The `emumanager` script is self-contained and does not call other scripts from
`bin/`. No additional scripts need to be symlinked.

## SKILL.md Requirements

### Frontmatter

Follow the Agent Skills specification exactly:

```yaml
---
name: emumanager
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
  - Good: "Manages Android SDK..." / "Extracts text from PDFs..."
  - Bad: "I can help you..." / "You can use this to..."
- Include what the skill does AND when to use it
- End with explicit trigger phrases using "Triggers:" prefix for reliable
  discovery across different agent implementations

Include these trigger phrases: android emulator, android virtual device, avd,
system image, wear os emulator, tv emulator, automotive emulator, bootstrap
android sdk, sdkmanager, avdmanager

Example pattern:

```yaml
description: >
  Manages Android SDK, emulators, and AVDs. Use when bootstrapping Android SDK,
  creating/starting/stopping AVDs, downloading system images, or troubleshooting
  emulator issues. Supports mobile, Wear OS, TV, and Automotive devices. Covers
  sdkmanager, avdmanager, emulator CLI. Triggers: android emulator, android
  virtual device, avd, system image, wear os emulator, bootstrap android sdk.
```

**Compatibility requirements (recommended):**

- Max 500 characters
- Include if the skill has external dependencies or environment requirements
- Mention required command-line tools, network access needs, or target platforms
- Example:
  `compatibility: Requires Java 17+, curl, and unzip. Hardware acceleration (KVM on Linux, HVF on macOS) required for emulators. Needs network access for downloading SDK components. Designed for filesystem-based agents with bash access.`

For maximum compatibility across skill loaders, prefer a single-line
`description:` value and avoid YAML block scalars like `description: |` (some
implementations treat multi-line descriptions inconsistently). If you need line
wrapping, prefer a folded scalar (`description: >`) rather than a literal block
(`description: |`).

### Body Content

Keep the body under 500 lines. Structure it for progressive disclosure—agents
load this only when the skill activates, so be concise.

**Degrees of Freedom:** Match specificity to task fragility:

- **Low freedom** (exact commands): Use for fragile operations like SDK
  bootstrap, database migrations, or sequences that must run exactly right
- **High freedom** (guidance): Use for flexible tasks where context determines
  the best approach

For emumanager, most operations are deterministic (run this exact command), so
prefer low-freedom documentation with specific commands.

#### Scripts First (Critical)

Add a prominent section at the top of SKILL.md body titled "Important: Use
Script First" that:

1. Tells agents to **ALWAYS use `scripts/emumanager`** over raw SDK commands
2. Notes that the script is located in the `scripts/` subdirectory of the
   skill's folder
3. Lists specific features the script provides that raw commands don't:
   - Automatic system image selection for device types (--mobile, --wear, --tv)
   - Boot completion detection with timeout
   - Sensible defaults and helpful error messages
   - Diagnostics via `doctor` subcommand
4. Explains when to read script source: if the script doesn't do exactly what's
   needed, or fails due to missing dependencies. The script encodes solutions to
   SDK quirks and boot detection edge cases—it serves as valuable reference when
   building similar functionality.

This section ensures agents see the scripts-first guidance immediately when the
skill activates.

#### Quick Start

- Environment variables: `ANDROID_HOME`, `ANDROID_USER_HOME`
- Prerequisites: Java 17+, hardware acceleration (KVM on Linux, HVF on macOS)
- 5-6 highest-value commands to run first:
  - `scripts/emumanager bootstrap` (first-time setup)
  - `scripts/emumanager doctor` (diagnose issues)
  - `scripts/emumanager create my_phone --mobile` (create AVD)
  - `scripts/emumanager start my_phone` (start AVD)
  - `scripts/emumanager list` (show all AVDs)
- Use paths relative to the skill: `scripts/emumanager`

#### Subcommand Overview

A compact reference for each subcommand. For each, provide:

- **Purpose** (1-2 lines)
- **Basic usage**
- **Key options**

Subcommands to document:

1. **bootstrap** - Set up SDK environment (cmdline-tools, platform-tools,
   build-tools, emulator)
2. **doctor** - Run diagnostics to check for common issues
3. **list** - List all available AVDs with running status
4. **info** - Show detailed information about an AVD
5. **create** - Create a new AVD with device type or specific image
6. **start** - Start an AVD with optional cold boot or wipe
7. **stop** - Stop a running AVD
8. **delete** - Delete an AVD and clean up files
9. **download** - Download a specific system image
10. **images** - List available system images (API level >= 33)
11. **outdated** - Show outdated SDK packages
12. **update** - Update all installed SDK packages

#### Device Types

Document the device type options for the `create` command:

- `--mobile` / `--phone` - Mobile/phone device (default)
- `--wear` / `--watch` - Wear OS device
- `--tv` - Android/Google TV device
- `--auto` - Android Automotive device

Explain that each type automatically selects the latest appropriate system image
for the host architecture.

#### Start Mode Options

Document the start mode flags:

- Default (Quick Boot) - Fast startup using snapshots
- `--cold-boot` - Bypass Quick Boot, perform cold boot
- `--wipe-data` - Factory reset (wipe all data) and cold boot

#### Common Workflows (Optional)

**Note:** Consider omitting this section if it largely duplicates Quick Start.
Only include workflows that combine commands in non-obvious ways or demonstrate
patterns not shown elsewhere. Every line costs context tokens.

#### Safety Notes

- Script requires Java 17+ to run SDK tools
- Hardware acceleration (KVM/HVF) is required for x86_64/arm64 emulators
- System image downloads can be several GB
- Some operations require network access
- The script avoids destructive actions unless explicitly requested

## Reference Files

### references/command-index.md

If this file is longer than 100 lines, include a `## Contents` section at the
top (a short table of contents) so agents can see the full scope even when
previewing the file.

For each subcommand, document:

- **Purpose** (1 line)
- **Synopsis** (usage pattern)
- **Arguments** (with descriptions)
- **Options** (flags and their effects)
- **Examples** (2-3 practical examples)
- **Raw commands** (the underlying sdkmanager/avdmanager/emulator commands)
- **Exit codes** (success/failure conditions)

Include sections on:

- **Environment variables** (`ANDROID_HOME`, `ANDROID_USER_HOME`,
  `ANDROID_BUILD_TOOLS_VERSION`, `ANDROID_PLATFORM_VERSION`)
- **Device types** and their corresponding system image patterns
- **Architecture detection** (how `get_host_arch` maps host to Android arch)

### references/troubleshooting.md

If this file is longer than 100 lines, include a `## Contents` section at the
top (a short table of contents) so agents can see the full scope even when
previewing the file.

Cover:

- Missing Java or wrong Java version
- Hardware acceleration not available (KVM/HVF)
- User not in `kvm` group (Linux)
- SDK tools not found (need to run bootstrap)
- System image not installed
- Emulator connection timeout
- AVD already running
- Orphaned AVD files
- Disk space issues
- Network errors during downloads
- Multiple emulators and `ANDROID_SERIAL`

## Writing Guidelines

### Core Principle: Conciseness

The context window is shared with conversation history, other skills, and system
prompts. **Assume agents are already intelligent**—only provide information they
don't already know. Challenge each paragraph: "Does this justify its token
cost?"

Bad (verbose):

```markdown
PDF (Portable Document Format) files are a common file format. To extract text
from a PDF, you'll need to use a library...
```

Good (concise):

````markdown
Use pdfplumber for text extraction:

```python
with pdfplumber.open("file.pdf") as pdf:
    text = pdf.pages[0].extract_text()
```
````

### Cross-Model Compatibility

Skills run on Claude (Haiku/Sonnet/Opus), Gemini CLI, and OpenAI Codex. Write
instructions that work across capability levels:

- Provide enough detail for simpler models (Haiku) to follow
- Don't over-explain for powerful models (Opus)
- Include explicit trigger phrases for reliable discovery
- Raw command fallbacks help when model-specific tool access varies

### Style

- Use imperative form ("Run this command" not "You can run this command")
- Include concrete examples with realistic AVD names and image paths
- Emphasize the script over raw commands. The script provides features (device
  type presets, boot detection, diagnostics) that raw commands don't.
- Do not duplicate raw commands from the script into SKILL.md. Tell agents to
  read the script source if they need the underlying command.
- Keep file references one level deep from SKILL.md
- Avoid redundant sections (don't repeat Quick Start examples in Common
  Workflows)

## Quality Checklist

Before finalizing, verify:

### Structure

- [ ] Skill directory exists at `etc/skills/emumanager/`
- [ ] `scripts/` contains a symlink to `bin/emumanager`
- [ ] Script is executable (`chmod +x`)
- [ ] No extraneous files (README.md, etc.)

### SKILL.md

- [ ] Valid frontmatter matching the spec
- [ ] Description is in third person
- [ ] Description ends with "Triggers:" and explicit keywords
- [ ] Body is under 500 lines
- [ ] No redundant sections (Quick Start vs Common Workflows)

### Content Coverage

- [ ] `SKILL.md` has "Important: Use Script First" section at top of body
- [ ] All twelve subcommands documented
- [ ] Device types (mobile, wear, tv, auto) explained
- [ ] Start modes (quick boot, cold boot, wipe data) explained
- [ ] Environment variables documented
- [ ] Raw SDK commands are NOT in SKILL.md body (agents read script source)
- [ ] Examples use realistic AVD names and system image paths

### References

- [ ] `references/command-index.md` documents each subcommand with raw commands
- [ ] `references/troubleshooting.md` covers common issues
- [ ] Files over 100 lines have a Contents section

### Cross-Model Compatibility

- [ ] Instructions are clear enough for simpler models (Haiku)
- [ ] Instructions don't over-explain for powerful models (Opus)

## Implementation Notes

- Use `mkdir -p` to create directories
- Use `ln -s` to create relative symlinks (e.g.,
  `ln -s ../../../../bin/emumanager scripts/emumanager`)
- Verify executable bits with `chmod +x scripts/*` if needed
- Do not modify the original `bin/emumanager` script—only symlink into the skill
- Test that the symlinked script works from the skill directory
- The script requires Bash 4.0+ (has version guard at top)
- The script's `require` and `require_sdk` functions check for dependencies at
  runtime

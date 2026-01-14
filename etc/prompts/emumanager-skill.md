# Prompt: Create Android Emulator Manager Skill

Create an Agent Skill that helps agents manage the Android SDK, emulators, and
AVDs (Android Virtual Devices). This skill should document the `emumanager`
script's capabilities and provide both script-first and raw-command fallback
approaches.

## Goal

Produce a self-contained skill directory at `etc/skills/emumanager/` that an
agent can use to:

1. Run the bundled `emumanager` script directly (fast, deterministic)
2. When the script fails (missing dependencies, environment issues), use raw
   `sdkmanager`, `avdmanager`, and `emulator` commands as an authoritative
   fallback

## Research Phase

Before creating files, research the following:

1. **Review the Agent Skills specification and best practices**:
   - Specification: <https://agentskills.io/specification.md>
   - Best practices: <https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices>

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

#### Raw Command Fallback

This is critical. Teach agents how to perform operations manually when the
script doesn't work:

1. Show the Android SDK tool paths used
2. Explain the environment setup
3. Provide raw commands for each operation

Include worked examples:

##### Environment Setup

```bash
export ANDROID_HOME="${ANDROID_HOME:-$HOME/.local/share/android-sdk}"
export ANDROID_USER_HOME="${ANDROID_USER_HOME:-$HOME/.android}"

SDKMANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
AVDMANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager"
EMULATOR="$ANDROID_HOME/emulator/emulator"
ADB="$ANDROID_HOME/platform-tools/adb"
```

##### Installing SDK Components

```bash
# Accept licenses
yes | "$SDKMANAGER" --licenses

# Install platform-tools (includes adb)
"$SDKMANAGER" --install "platform-tools"

# Install emulator
"$SDKMANAGER" --install "emulator"

# Install build-tools
"$SDKMANAGER" --install "build-tools;36.0.0"

# Install a platform
"$SDKMANAGER" --install "platforms;android-36"
```

##### Listing and Installing System Images

```bash
# List available images
"$SDKMANAGER" --list | grep "system-images;android-"

# Install a system image
"$SDKMANAGER" --install "system-images;android-36;google_apis_playstore;arm64-v8a"
```

##### Creating an AVD

```bash
# Create AVD with specific image
echo "no" | "$AVDMANAGER" create avd \
  -n my_phone \
  -k "system-images;android-36;google_apis_playstore;arm64-v8a" \
  -d medium_phone
```

##### Starting an AVD

```bash
# Start emulator in background
"$EMULATOR" -avd my_phone &

# Wait for device to connect
"$ADB" wait-for-device

# Wait for boot to complete
while [ "$("$ADB" shell getprop init.svc.bootanim | tr -d '\r')" != "stopped" ]; do
  sleep 1
done
```

##### Stopping an AVD

```bash
# Find emulator serial and stop it
"$ADB" -s emulator-5554 emu kill
```

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
PDF (Portable Document Format) files are a common file format. To extract
text from a PDF, you'll need to use a library...
```

Good (concise):
```markdown
Use pdfplumber for text extraction:
```python
with pdfplumber.open("file.pdf") as pdf:
    text = pdf.pages[0].extract_text()
```

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
- Document raw commands prominently—they're essential fallbacks
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
- [ ] Both script-first AND raw-command-fallback approaches documented
- [ ] All twelve subcommands documented
- [ ] Device types (mobile, wear, tv, auto) explained
- [ ] Start modes (quick boot, cold boot, wipe data) explained
- [ ] Environment variables documented
- [ ] Examples use realistic AVD names and system image paths

### References
- [ ] `references/command-index.md` documents each subcommand with raw commands
- [ ] `references/troubleshooting.md` covers common issues
- [ ] Files over 100 lines have a Contents section

### Cross-Model Compatibility
- [ ] Instructions are clear enough for simpler models (Haiku)
- [ ] Instructions don't over-explain for powerful models (Opus)
- [ ] Raw commands provide fallback when tool access varies

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

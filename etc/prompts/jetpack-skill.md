# Prompt: Create Jetpack Library Utilities Skill

Create an Agent Skill that helps agents work with Android Jetpack libraries.
This skill should document the `jetpack` script's capabilities and provide both
script-first and raw-command fallback approaches.

## Goal

Produce a self-contained skill directory at `etc/skills/jetpack/` that an agent
can use to:

1. Run the bundled `jetpack` script directly (fast, deterministic)
2. When the script fails (missing dependencies, environment issues), use raw
   `curl` and `xmllint` commands as an authoritative fallback

## Research Phase

Before creating files, research the following:

1. **Review the Agent Skills specification** at
   <https://agentskills.io/specification.md> to understand frontmatter
   requirements, directory structure, and naming conventions.

2. **Examine the `bin/jetpack` script thoroughly**:

   - All subcommands: `version`, `resolve`, `source`, `inspect`,
     `resolve-exceptions`
   - The underlying `curl`, `xmllint`, and `jar` commands
   - Dependencies (look for `require` calls)
   - Maven repository URLs used (Google Maven, androidx.dev snapshots)
   - Version type handling (ALPHA, BETA, RC, STABLE, LATEST, SNAPSHOT)
   - The exceptions table in the `resolve` subcommand

   For each subcommand, understand:

   - Purpose and when to use it
   - The underlying raw commands
   - Input/output format
   - Error conditions

## Deliverable Structure

Create this exact structure:

```text
etc/skills/jetpack/
├── SKILL.md              # Required: frontmatter + instructions
├── scripts/              # Copy of the jetpack script
└── references/           # Reference documentation
    ├── command-index.md
    └── troubleshooting.md
```

Do not create extra files like README.md, CHANGELOG.md, or INSTALLATION.md.

## Script Selection

Copy `bin/jetpack` into `scripts/`.

Preserve the filename and executable permissions. Use a real copy, not a
symlink.

### Transitive Script Dependencies

The `jetpack` script is self-contained and does not call other scripts from
`bin/`. No additional scripts need to be copied.

## SKILL.md Requirements

### Frontmatter

Follow the Agent Skills specification exactly:

```yaml
---
name: jetpack
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
- Include trigger phrases: jetpack, androidx, maven coordinate, source code,
  library version, snapshot, alpha, beta, stable, artifact, dependency, inspect
  source

Example pattern:

```yaml
description: >
  Resolves AndroidX/Jetpack library information including version lookup,
  package-to-Maven-coordinate conversion, and source code downloading. Provides
  tools for inspecting Jetpack library implementations. Use when working with
  androidx libraries, resolving Maven coordinates, downloading Jetpack source
  code, checking library versions (alpha/beta/stable/snapshot), or inspecting
  AndroidX class implementations.
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

- System requirements: `curl`, `xmllint` (libxml2-utils), `jar` (JDK)
- 4-5 highest-value commands to run first:
  - `scripts/jetpack inspect <CLASS_NAME>` (most common use case)
  - `scripts/jetpack version <PACKAGE> STABLE`
  - `scripts/jetpack resolve <CLASS_NAME>`
  - `scripts/jetpack source <PACKAGE> SNAPSHOT`
- Use paths relative to the skill: `scripts/jetpack`

#### Subcommand Overview

A compact reference for each subcommand. For each, provide:

- **Purpose** (1-2 lines)
- **Basic usage**
- **Key options**

Subcommands to document:

1. **version** - Get specific version type for a Jetpack package
2. **resolve** - Convert Android package/class name to Maven coordinate
3. **source** - Download and extract source JARs
4. **inspect** - Convenience wrapper combining resolve + source
5. **resolve-exceptions** - Find missing exceptions for resolve command

#### Version Types

Document the version specifier system clearly:

**Symbolic (floating):** Resolve to latest matching version at runtime.

- ALPHA, BETA, RC, STABLE, LATEST, SNAPSHOT

**Pinned (immutable):** Always resolve to exact same code.

- Specific version strings (e.g., `1.6.0-alpha01`)
- Snapshot build IDs (e.g., `14710011` from androidx.dev)

#### Raw Command Fallback

This is critical. Teach agents how to perform operations manually when the
script doesn't work:

1. Show the Maven repository URLs used
2. Explain the maven-metadata.xml structure
3. Provide curl + xmllint commands for each operation

Include worked examples:

##### Fetching Version Information

```bash
# Maven metadata URL pattern
# Released versions:
https://dl.google.com/android/maven2/{group/path}/{artifact}/maven-metadata.xml

# Snapshot versions:
https://androidx.dev/snapshots/latest/artifacts/repository/{group/path}/{artifact}/maven-metadata.xml

# Example: Get latest stable version for androidx.wear.tiles:tiles
REPO="https://dl.google.com/android/maven2"
GROUP_PATH="androidx/wear/tiles"
ARTIFACT="tiles"
curl -sSLf "$REPO/$GROUP_PATH/$ARTIFACT/maven-metadata.xml" | \
  xmllint --xpath "//version/text()" - | tr ' ' '\n' | \
  grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n 1
```

##### Downloading Source Code

```bash
# Source JAR URL pattern
# Released versions:
https://dl.google.com/android/maven2/{group/path}/{artifact}/{version}/{artifact}-{version}-sources.jar

# Snapshot versions:
https://androidx.dev/snapshots/latest/artifacts/repository/{group/path}/{artifact}/{version}/{artifact}-{jar_version}-sources.jar

# Example: Download source for androidx.wear.tiles:tiles version 1.4.0
REPO="https://dl.google.com/android/maven2"
GROUP_PATH="androidx/wear/tiles"
ARTIFACT="tiles"
VERSION="1.4.0"
JAR="$ARTIFACT-$VERSION-sources.jar"
curl -sSLf "$REPO/$GROUP_PATH/$ARTIFACT/$VERSION/$JAR" -o sources.jar
jar xf sources.jar
```

##### Resolving Package Names

Document the heuristic rules and exceptions table from the script. Include:

- The pattern for 2-segment vs 3-segment group IDs
- Key exceptions (e.g., `androidx.lifecycle` →
  `androidx.lifecycle:lifecycle-runtime`)
- How to handle class names vs package names

#### Common Workflows

Document typical usage patterns:

1. **Inspecting a class implementation**

   ```bash
   cd "$(scripts/jetpack inspect androidx.wear.tiles.TileService)"
   ```

2. **Checking what version is available**

   ```bash
   scripts/jetpack version androidx.wear.tiles:tiles ALPHA
   scripts/jetpack version androidx.wear.tiles:tiles SNAPSHOT
   ```

3. **Working with bleeding-edge code**

   ```bash
   scripts/jetpack source androidx.compose.remote:remote-creation-compose SNAPSHOT
   ```

4. **Finding the Maven coordinate for a class**

   ```bash
   scripts/jetpack resolve androidx.core.splashscreen.SplashScreen
   ```

#### Safety Notes

- Script requires network access to Maven repositories
- SNAPSHOT versions change frequently; pinned versions are reproducible
- Some libraries may not have all version types available
- Kotlin Multiplatform libraries have platform-specific sources

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
- **Raw commands** (the underlying curl/xmllint/jar commands)
- **Exit codes** (success/failure conditions)

Include a section on the **exceptions table** from the `resolve` subcommand,
explaining:

- What it is (package prefix → Maven coordinate mapping)
- Why it exists (packages that don't follow the standard naming convention)
- How to add new exceptions using `resolve-exceptions`

### references/troubleshooting.md

If this file is longer than 100 lines, include a `## Contents` section at the
top (a short table of contents) so agents can see the full scope even when
previewing the file.

Cover:

- Missing dependencies (`curl`, `xmllint`, `jar`)
- Network errors (failed to fetch maven-metadata.xml)
- Package not found in repository
- No version of requested type available
- Snapshot-only packages (must explicitly request SNAPSHOT)
- Invalid package format errors
- Resolving ambiguous package names
- Kotlin Multiplatform libraries and platform-specific sources

## Writing Guidelines

- Be concise. Agents are intelligent; provide what they don't already know.
- Use imperative form ("Run this command" not "You can run this command").
- Include concrete examples with realistic package/class names.
- Document raw commands prominently—they're essential fallbacks.
- Keep file references one level deep from SKILL.md.

## Quality Checklist

Before finalizing, verify:

- [ ] Skill directory exists at `etc/skills/jetpack/`
- [ ] `SKILL.md` has valid frontmatter matching the spec
- [ ] Description is in third person and includes trigger phrases
- [ ] `SKILL.md` body is under 500 lines
- [ ] `scripts/` contains a copy of `bin/jetpack`
- [ ] Script is executable (`chmod +x`)
- [ ] Both script-first AND raw-command-fallback approaches are documented
- [ ] `references/command-index.md` documents each subcommand with raw commands
- [ ] `references/troubleshooting.md` covers common issues
- [ ] All five subcommands are documented
- [ ] Version types (ALPHA/BETA/RC/STABLE/LATEST/SNAPSHOT) are explained
- [ ] Pinned versions (specific strings, build IDs) are explained
- [ ] No extraneous files (README.md, etc.)
- [ ] Examples use realistic AndroidX package/class names

## Implementation Notes

- Use `mkdir -p` and `cp -p` to create directories and copy files
- Verify executable bits with `chmod +x scripts/*` if needed
- Do not modify the original `bin/jetpack` script—only copy into the skill
- Test that the copied script works from the skill directory
- The script's `require` function will check for dependencies at runtime

## Package Name Examples

Use these realistic examples throughout the documentation:

**Common packages:**

- `androidx.wear.tiles:tiles`
- `androidx.lifecycle:lifecycle-runtime`
- `androidx.compose.ui:ui`
- `androidx.core:core-splashscreen`

**Class names for resolve:**

- `androidx.wear.tiles.TileService`
- `androidx.lifecycle.ViewModel`
- `androidx.core.splashscreen.SplashScreen`
- `androidx.compose.ui.Modifier`

**Snapshot-only packages (use SNAPSHOT explicitly):**

- `androidx.compose.remote:remote-creation-compose`
- `androidx.glance.wear:wear`

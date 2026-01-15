---
name: jetpack
description: >
  Resolves AndroidX/Jetpack library information including version lookup,
  package-to-Maven-coordinate conversion, and source code downloading. Provides
  tools for inspecting Jetpack library implementations. Use when working with
  androidx libraries, resolving Maven coordinates, downloading Jetpack source
  code, checking library versions (alpha/beta/stable/snapshot), or inspecting
  AndroidX class implementations.
compatibility: >
  Requires curl, xmllint (libxml2-utils), jar (JDK). Needs network access to
  dl.google.com and androidx.dev.
---

# Jetpack Library Utilities

## Quick Start

**Requirements:** `curl`, `xmllint` (libxml2-utils), `jar` (JDK).

### Highest-Value Commands

- **Inspect a class (most common):**
  `scripts/jetpack inspect androidx.wear.tiles.TileService`
- **Check stable version:**
  `scripts/jetpack version androidx.wear.tiles:tiles STABLE`
- **Resolve package to Maven coordinate:**
  `scripts/jetpack resolve androidx.lifecycle.ViewModel`
- **Download bleeding-edge source:**
  `scripts/jetpack source androidx.compose.ui:ui SNAPSHOT`

## Subcommand Overview

### `version`

**Purpose**: Get specific version type (ALPHA, BETA, SNAPSHOT, etc.) for a
package. **Usage**: `scripts/jetpack version PACKAGE [TYPE] [REPO]` **Options**:
`ALPHA`, `BETA`, `RC`, `STABLE`, `LATEST`, `SNAPSHOT`.

### `resolve`

**Purpose**: Convert Android package/class name to Maven coordinate. **Usage**:
`scripts/jetpack resolve PACKAGE_OR_CLASS` **Note**: Uses heuristic rules and an
exceptions table.

### `source`

**Purpose**: Download and extract source JARs. **Usage**:
`scripts/jetpack source PACKAGE... [VERSION]` **Options**: `--output DIR` to
specify destination.

### `inspect`

**Purpose**: Convenience wrapper combining `resolve` + `source`. **Usage**:
`scripts/jetpack inspect CLASS_NAME [VERSION]` **Note**: Best for quickly
checking implementation details.

### `resolve-exceptions`

**Purpose**: Find missing exceptions for the `resolve` command. **Usage**:
`scripts/jetpack resolve-exceptions COORDINATE` **Note**: Analyzes SNAPSHOT JARs
to find packages violating naming conventions.

## Version Types

### Symbolic (Floating)

Resolves to the latest matching version at runtime.

- **ALPHA**: Latest alpha (e.g., `1.2.0-alpha05`)
- **BETA**: Latest beta (e.g., `1.2.0-beta02`)
- **RC**: Latest release candidate (e.g., `1.2.0-rc01`)
- **STABLE**: Latest stable release (e.g., `1.1.0`)
- **LATEST**: Latest version of any kind.
- **SNAPSHOT**: Latest build from `androidx.dev`.

### Pinned (Immutable)

Always resolve to the exact same code.

- **Version String**: Specific version (e.g., `1.6.0-alpha01`).
- **Build ID**: Specific snapshot build (e.g., `14710011` from
  `androidx.dev/snapshots/builds`).

## Raw Command Fallback

If the script fails, use raw `curl` and `xmllint`.

### Fetching Version Information

```bash
# Example: Get latest stable version for androidx.wear.tiles:tiles
REPO="https://dl.google.com/android/maven2"
GROUP_PATH="androidx/wear/tiles"
ARTIFACT="tiles"
curl -sSLf "$REPO/$GROUP_PATH/$ARTIFACT/maven-metadata.xml" | \
  xmllint --xpath "//version/text()" - | tr ' ' '\n' | \
  grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n 1
```

### Downloading Source Code

```bash
# Example: Download source for androidx.wear.tiles:tiles version 1.4.0
REPO="https://dl.google.com/android/maven2"
GROUP_PATH="androidx/wear/tiles"
ARTIFACT="tiles"
VERSION="1.4.0"
JAR="$ARTIFACT-$VERSION-sources.jar"
curl -sSLf "$REPO/$GROUP_PATH/$ARTIFACT/$VERSION/$JAR" -o sources.jar
jar xf sources.jar
```

### Resolving Package Names

The script uses a combination of:

1. **Exceptions Table**: Hardcoded mapping (e.g., `androidx.lifecycle` ->
   `androidx.lifecycle:lifecycle-runtime`).
2. **Heuristics**:
   - 3-segment groups (e.g., `androidx.compose.ui`).
   - 2-segment groups (e.g., `androidx.core`).
   - Artifact ID derived from the next segment or last part of group.

## Common Workflows

### Inspecting a Class Implementation

```bash
cd "$(scripts/jetpack inspect androidx.wear.tiles.TileService)"
# Browse source files...
```

### Checking Available Versions

```bash
scripts/jetpack version androidx.wear.tiles:tiles ALPHA
scripts/jetpack version androidx.wear.tiles:tiles SNAPSHOT
```

### Working with Bleeding-Edge Code

```bash
scripts/jetpack source androidx.compose.remote:remote-creation-compose SNAPSHOT
```

### Finding Maven Coordinate

```bash
scripts/jetpack resolve androidx.core.splashscreen.SplashScreen
# Output: androidx.core:core-splashscreen
```

## Safety Notes

- **Network Access**: Requires access to `dl.google.com` and `androidx.dev`.
- **SNAPSHOTs**: Change frequently; use pinned versions or Build IDs for
  reproducibility.
- **Kotlin Multiplatform**: `source` and `inspect` automatically download
  platform-specific sources (e.g., `-android`, `-desktop`) if detected in the
  POM.

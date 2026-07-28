---
name: jetpack
description: >
  Looks up AndroidX/Jetpack library facts that change between releases and are
  therefore wrong from memory: the current version of an artifact
  (alpha/beta/rc/stable/snapshot, or a pinned build ID), the Maven coordinate a
  package or class belongs to, an artifact's direct dependencies, and the real
  published source of an AndroidX class. Use whenever the answer would
  otherwise be a remembered version number, coordinate, or API signature —
  including phrasings that name a library without saying "androidx", such as
  "the latest release of Compose Material 3". Not for teaching Jetpack Compose
  or Android APIs in general, where no lookup is needed, and not for the
  literal rocket-pack sense of the word.
compatibility: >-
  Requires curl, xmllint (libxml2-utils), jar (JDK), jq, perl. Needs network
  access to dl.google.com, androidx.dev, and cs.android.com, or a cache left by
  an earlier online run plus JETPACK_OFFLINE/AGENT_OFFLINE where there is none.
---

# Jetpack Library Utilities

## Important: Use Script First

**ALWAYS use `scripts/jetpack` to answer these questions — never a raw command
against a Maven URL or against the cache.** The script is located in the
`scripts/` subdirectory of this skill's folder. References to `scripts/...` in
this skill are relative to this skill directory. It provides features that raw
commands do not:

- Package-to-coordinate resolution with exceptions table
- Code search integration for finding artifacts by class name
- Version type handling (ALPHA, BETA, STABLE, SNAPSHOT)
- Kotlin Multiplatform platform-specific source detection
- Build ID resolution for pinned snapshots

**The cache is the script's storage, not an interface.** `curl` and `xmllint`
against `dl.google.com` are the obvious way to bypass the script, but reaching
into `$JETPACK_CACHE_DIR` with `jq`, `unzip`, `jar`, `find`, or `grep` bypasses
it just as completely — and offline, where the script is answering from that
same cache, it looks like the shortest path. It is not: the index and the cached
responses are raw upstream data, so reading them by hand skips the version-type
filtering, the exceptions table, and the platform-source detection listed above,
and returns something plausible with no sign that those steps were missed. Ask
the script the question, offline or not; browse the cache only to diagnose the
script itself.

**When to read the script source:** If the script doesn't do exactly what you
need, or fails due to missing dependencies, read the script source. It encodes
Maven repository URL patterns, version filtering logic, and package naming
heuristics—use it as reference when building similar functionality.

**If the script fails, say so.** A nonzero exit means the answer has not been
verified against live Maven data. Do not silently fall back to a remembered
version number or coordinate and present it as current — Jetpack versions change
often enough that a memorized answer can be confidently wrong. Report the
failure (missing dependency, network error, unresolved package) to the user,
including the script's own error message, and consult
[references/troubleshooting.md](references/troubleshooting.md) before retrying.

**If you have no network, say that too.** In a sandbox that denies egress, run
`scripts/jetpack doctor` first: it reports whether the cache can answer at all.
Then set `AGENT_OFFLINE=1` so the script serves cached answers instead of
spending timeouts on calls it cannot make. Every cached answer arrives with its
age on stderr (`(cached 3 days ago)`) — pass that age on rather than presenting
a stale version as current. A cache miss is an error quoting the command to
re-run where there is network; it is never a reason to answer from memory.

## Quick Start

**Requirements:** `curl`, `xmllint` (libxml2-utils), `jar` (JDK), `jq`, `perl`.

### Highest-Value Commands

- **Inspect a class (most common):**
  `scripts/jetpack inspect androidx.wear.tiles.TileService`
- **Search for a library:** `scripts/jetpack search androidx.wear.compose`
- **Check stable version:**
  `scripts/jetpack version androidx.wear.tiles:tiles STABLE`
- **Resolve package to Maven coordinate:**
  `scripts/jetpack resolve androidx.lifecycle.ViewModel`
- **Download bleeding-edge source:**
  `scripts/jetpack source androidx.compose.ui:ui SNAPSHOT`
- **Download reference sample code:**
  `scripts/jetpack-samples androidx.compose.remote:remote-creation-compose`

## Subcommand Overview

### `version`

**Purpose**: Get specific version type (ALPHA, BETA, SNAPSHOT, etc.) for a
package. **Usage**: `scripts/jetpack version PACKAGE [TYPE] [REPO]` **Options**:
`ALPHA`, `BETA`, `RC`, `STABLE`, `LATEST`, `SNAPSHOT`.

### `list versions`

**Purpose**: List all versions for a package. **Usage**:
`scripts/jetpack list versions PACKAGE [REPO]`

### `resolve`

**Purpose**: Convert Android package/class name to Maven coordinate. **Usage**:
`scripts/jetpack resolve PACKAGE_OR_CLASS` **Note**: Uses heuristic rules and an
exceptions table.

### `search`

**Purpose**: Search for artifacts by package, artifact, or class name.
**Usage**: `scripts/jetpack search [OPTIONS] QUERY` **Options**: `--force`
(rebuild cache).

### `source`

**Purpose**: Download and extract source JARs. **Usage**:
`scripts/jetpack source PACKAGE... [VERSION]` **Options**: `--output DIR` to
specify destination, `--find PATTERN` to locate specific files.

### `inspect`

**Purpose**: Convenience wrapper combining `search`/`resolve` + `source`.
**Usage**: `scripts/jetpack inspect CLASS_NAME [VERSION]` **Note**: Best for
quickly checking implementation details; uses code search if direct resolution
fails.

### `list dependencies`

**Purpose**: List direct Maven dependencies for an artifact. **Usage**:
`scripts/jetpack list dependencies ARTIFACT [VERSION]`

### `doctor`

**Purpose**: Report dependencies, offline mode, and cache state. **Usage**:
`scripts/jetpack doctor` **Note**: Read-only; exits non-zero if anything needs
attention.

### `resolve-exceptions`

**Purpose**: Find missing exceptions for the `resolve` command. **Usage**:
`scripts/jetpack resolve-exceptions COORDINATE [VERSION]`

## Standalone Scripts

### `scripts/jetpack-samples`

**Purpose**: Download non-published reference samples and integration tests.
**Usage**: `scripts/jetpack-samples ARTIFACT [--output DIR]` **Details**:
Locates files from the AOSP source structure and aggregates into readable
components locally.

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

## Common Workflows

### Inspecting a Class Implementation

```bash
cd "$(scripts/jetpack inspect androidx.wear.tiles.TileService)"
# Browse source files...
```

### Finding a Library

```bash
# Find libraries related to 'wear.compose'
scripts/jetpack search androidx.wear.compose

# Find which artifact contains 'RemoteImage'
scripts/jetpack search RemoteImage
```

### Checking Available Versions

```bash
# List all versions
scripts/jetpack list versions androidx.wear.tiles:tiles

# Check specific version types
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

### Working Without Network (CI, Sandboxed Agents)

Every online run writes what it fetched into
`${JETPACK_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/jetpack}`, so preparing
for an offline run means nothing more than asking the same question once where
there is network:

```bash
# Where there is network: ask, and the answers are cached as a side effect
scripts/jetpack version androidx.wear.tiles:tiles
scripts/jetpack inspect androidx.wear.tiles.TileService

# Where there is not: the same commands answer from the cache
AGENT_OFFLINE=1 scripts/jetpack doctor       # is the cache good enough?
AGENT_OFFLINE=1 scripts/jetpack version androidx.wear.tiles:tiles
AGENT_OFFLINE=1 scripts/jetpack inspect androidx.wear.tiles.TileService
```

A miss quotes the command to re-run, so the fix is always the invocation that
just failed.

The sandbox that denies egress usually denies writes too, so the lookups read
straight from the cache and need no writable filesystem at all: `version`,
`list versions`, `list dependencies`, `resolve`, and `search` all answer with
nowhere to write. `source` and `inspect` are the exception — they extract a JAR,
so they need somewhere to put it; pass `--output DIR` naming a writable
directory when the default temp location is not one.

See [caching and offline mode](../coding-standards/references/caching.md) for
the repo-wide convention.

## Safety Notes

- **Network Access**: Requires access to `dl.google.com`, `androidx.dev`, and
  `cs.android.com` — or a cache warmed by an earlier online run, plus
  `AGENT_OFFLINE=1`.
- **Cached answers are dated, not current**: offline answers carry their age on
  stderr. Report that age; do not present a stale version as the latest.
- **SNAPSHOTs**: Change frequently; use pinned versions or Build IDs for
  reproducibility.
- **Kotlin Multiplatform**: `source` and `inspect` automatically download
  platform-specific sources (e.g., `-android`, `-desktop`) if detected in the
  POM.

## Reference Material

- **Command Reference**: Detailed usage, arguments, and raw commands for all
  subcommands. See [references/command-index.md](references/command-index.md).
- **Troubleshooting**: Solutions for network errors, missing dependencies, and
  search failures. See
  [references/troubleshooting.md](references/troubleshooting.md).

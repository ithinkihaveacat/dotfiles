---
name: jetpack
description: >-
  Looks up AndroidX, Jetpack, Google Maven (Play Services, Play Billing, ML Kit,
  Firebase), and Maven Central library facts that change between releases:
  current artifact versions (ALPHA, BETA, RC, STABLE, SNAPSHOT, build IDs),
  Maven coordinates for top-level and nested classes, direct dependencies,
  published source code (-sources.jar), and Javadoc API reference HTML
  (-javadoc.jar) for closed-source SDKs. Use when looking up Android or JVM
  library versions, finding Maven coordinates, downloading source or Javadoc
  JARs, inspecting class implementations or API contracts, or resolving library
  dependencies. Do not use for general Android tutorials or platform framework
  APIs where no Maven lookup is required.
compatibility: >-
  Requires curl, xmllint (libxml2-utils), jar (JDK), jq, perl. Needs network
  access to dl.google.com, repo1.maven.org, and androidx.dev, or a cache left
  by an earlier online run plus AGENT_OFFLINE where there is none.
---

# Jetpack Library Utilities

## Using the Jetpack Script vs. Raw Maven Queries

Use `scripts/jetpack` as the primary interface for resolving AndroidX, Jetpack,
Google Maven, and Maven Central library coordinates, versions, source locations,
and published Javadoc HTML. References to `scripts/...` in this skill are
relative to this skill directory. The script handles complex resolution logic
that manual queries miss:

- Class-to-coordinate lookup in the cached GMaven class index (including nested
  `Outer.Inner` and `Outer$Inner` classes)
- Class-name search over that same index
- Automatic Google Maven → Maven Central (`https://repo1.maven.org/maven2`)
  fallback for coordinate-addressed commands when no `REPO_URL` is supplied
- Version type filtering (ALPHA, BETA, STABLE, SNAPSHOT)
- Kotlin Multiplatform platform-specific source detection
- Raw `-javadoc.jar` HTML extraction (`javadoc`) and automatic `inspect`
  fallback for closed-source SDKs that do not publish `-sources.jar`
- Build ID resolution for pinned snapshots

**The cache is the script's storage, not an interface.** `curl` and `xmllint`
against `dl.google.com` are the obvious way to bypass the script, but reaching
into `$JETPACK_CACHE_DIR` with `jq`, `unzip`, `jar`, `find`, or `grep` bypasses
it just as completely — and offline, where the script is answering from that
same cache, it looks like the shortest path. It is not: the index and the cached
responses are raw upstream data, so reading them by hand skips the version-type
filtering, the class matching, and the platform-source detection listed above,
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

- **Inspect a class (most common, auto-falls back to Javadoc if source-less):**
  `scripts/jetpack inspect androidx.wear.tiles.TileService`
- **Inspect a closed-source SDK or nested class:**
  `scripts/jetpack inspect com.google.android.gms.wearable.NodeClient.OnNodeMigratedListener`
- **Extract Javadoc HTML directly:**
  `scripts/jetpack javadoc --find BillingClient com.android.billingclient:billing`
- **Search for a library:** `scripts/jetpack search androidx.wear.compose`
- **Check stable version:**
  `scripts/jetpack version androidx.wear.tiles:tiles STABLE`
- **Resolve class to Maven coordinate:**
  `scripts/jetpack resolve androidx.lifecycle.ViewModel`
- **Download bleeding-edge source:**
  `scripts/jetpack source androidx.compose.ui:ui SNAPSHOT`
- **Download reference sample code:**
  `scripts/jetpack-samples androidx.compose.remote:remote-creation-compose`
- **Download version-specific reference sample code:**
  `scripts/jetpack-samples androidx.wear.compose:compose-material3 1.7.0-rc01`

## Subcommand Overview

### `version`

**Purpose**: Get specific version type (ALPHA, BETA, SNAPSHOT, etc.) for a
package. **Usage**: `scripts/jetpack version PACKAGE [TYPE] [REPO]` **Options**:
`ALPHA`, `BETA`, `RC`, `STABLE`, `LATEST`, `SNAPSHOT`.

### `list versions`

**Purpose**: List all versions for a package. **Usage**:
`scripts/jetpack list versions PACKAGE [REPO]`

### `resolve`

**Purpose**: Convert an Android class to its Maven coordinate. **Usage**:
`scripts/jetpack resolve CLASS_NAME` **Note**: Resolves top-level and nested
classes (`Outer.Inner` or `Outer$Inner`) whose enclosing top-level class is in
the cached Google Maven index (`androidx.*`, `com.google.android.*`,
`com.android.billingclient.*`, etc.); use `search` for packages and Kotlin
top-level functions. Maven Central libraries are not in the class index — pass
their `GROUP:ARTIFACT` coordinate directly to `version`, `list`, `source`,
`javadoc`, or `inspect`.

### `search`

**Purpose**: Search for artifacts by package, artifact, or class name.
**Usage**: `scripts/jetpack search [OPTIONS] QUERY` **Options**: `--force`
(rebuild cache). **Note**: Searches the cached Google Maven class index only;
for Maven Central artifacts pass `GROUP:ARTIFACT` directly to coordinate
commands.

### `source`

**Purpose**: Download and extract compilable `-sources.jar` archives. **Usage**:
`scripts/jetpack source [OPTIONS] PACKAGE... [VERSION] [REPO]` **Options**:
`-o`/`--output DIR` to specify destination, `--find PATTERN` to locate specific
files. **Note**: Strictly fetches `-sources.jar`; on HTTP 404 it prints a hint
pointing to `scripts/jetpack javadoc`.

### `javadoc`

**Purpose**: Download and extract raw `.html` reference pages from
`-javadoc.jar` archives (useful for closed-source Google Maven or Maven Central
SDKs without `-sources.jar`). **Usage**:
`scripts/jetpack javadoc [OPTIONS] PACKAGE... [VERSION] [REPO]` **Options**:
`-o`/`--output DIR` to specify destination, `--find PATTERN` to locate matching
class HTML pages (including `Outer.Inner` / `Outer$Inner`). **Note**: Rejects
empty placeholder `-javadoc.jar` archives with a non-zero exit status. When
`--find` resolves to a single `.html` file `≤ 64 KiB`, its contents are printed
to stdout; larger pages print the extracted file path to stdout (with a size
note on stderr) so callers can search or read targeted line ranges.

### `inspect`

**Purpose**: Convenience wrapper combining `search`/`resolve` + `source` with
automatic fallback to `javadoc` when `-sources.jar` is not published. **Usage**:
`scripts/jetpack inspect [OPTIONS] CLASS_NAME|GROUP:ARTIFACT [VERSION]`
**Note**: Resolves top-level and nested (`Outer.Inner` / `Outer$Inner`) class
names; falls back to an index search if direct resolution fails, and falls back
to `-javadoc.jar` (logging an `info:` provenance notice on stderr) when
`-sources.jar` returns HTTP 404. For Maven Central libraries (which are not in
the Google Maven class index), pass `GROUP:ARTIFACT` directly (or use
`scripts/jetpack source --find <Class> GROUP:ARTIFACT` /
`scripts/jetpack javadoc --find <Class> GROUP:ARTIFACT`).

### `list dependencies`

**Purpose**: List direct Maven dependencies for an artifact. **Usage**:
`scripts/jetpack list dependencies ARTIFACT [VERSION]`

### `doctor`

**Purpose**: Report dependencies, offline mode, and cache state. **Usage**:
`scripts/jetpack doctor` **Note**: Read-only; exits non-zero if anything needs
attention.

## Standalone Scripts

### `scripts/jetpack-samples`

**Purpose**: Download non-published reference samples and integration tests.
**Usage**: `scripts/jetpack-samples ARTIFACT [VERSION] [--output DIR]`
**Details**: Extracts sample modules from the AOSP source structure. When
`VERSION` (or release tier like `STABLE`, `RC`, `BETA`, `ALPHA`) is specified,
it resolves the exact Git commit SHA from AndroidX release notes to match the
released artifact. If omitted, extracts samples from `androidx-main` (HEAD).

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
nowhere to write. `source`, `javadoc`, and `inspect` are the exception — they
extract a JAR, so they need somewhere to put it; pass `--output DIR` naming a
writable directory when the default temp location is not one.

See local HTTP caching guidelines (storing response artifacts locally under
`$XDG_CACHE_HOME`) for the repo-wide convention.

## Safety Notes

- **Network Access**: Requires access to `dl.google.com`, `repo1.maven.org`, and
  `androidx.dev` — or a cache warmed by an earlier online run, plus
  `AGENT_OFFLINE=1`.
- **Repository Fallback & Class Index Boundary**: Coordinate-addressed commands
  (`version`, `list versions`, `list dependencies`, `source`, `javadoc`, and
  `inspect GROUP:ARTIFACT`) query Google Maven first and automatically fall back
  to Maven Central (`https://repo1.maven.org/maven2`) on a 404 when no explicit
  `REPO_URL` is given (never for `SNAPSHOT` or numeric build IDs), logging an
  `info:` notice on stderr. `resolve` and `search` only query the cached Google
  Maven class index; pass `GROUP:ARTIFACT` directly for Maven Central libraries.
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

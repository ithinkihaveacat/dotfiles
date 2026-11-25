# Command Index

<!-- markdownlint-disable MD013 -->

## Contents

- [Help](#help)
- [version](#version)
- [list versions](#list-versions)
- [list dependencies](#list-dependencies)
- [resolve](#resolve)
- [search](#search)
- [source](#source)
- [javadoc](#javadoc)
- [inspect](#inspect)
- [doctor](#doctor)

## Help

The block below is `scripts/jetpack --help`, kept in sync by
`command-index-format`; do not edit it by hand. The sections that follow add
per-subcommand detail and raw commands.

<!-- generated: ../scripts/jetpack --help -->

```text
Usage: jetpack <command> [arguments]

Jetpack library utilities for working with AndroidX and Maven packages.
This tool helps resolve Maven artifacts, finding versions, and downloading
source code or Javadoc HTML for AndroidX and Maven libraries (including
SNAPSHOT builds). Coordinate commands (version, list, source, javadoc,
inspect GROUP:ARTIFACT) default to Google Maven and automatically fall back
to Maven Central when no repo URL is given.

Commands:
  version <artifact> [type] [repo]
                      Get the version string for a Maven artifact.
                      Types: ALPHA, BETA, RC, STABLE, LATEST, SNAPSHOT, or BUILD_ID.
                      Default: STABLE.
  list versions <artifact> [repo]
                      List all versions for a given Maven artifact.
  list dependencies <artifact> [version]
                      List direct Maven dependencies for a given Maven artifact.
  resolve <class>     Convert a fully qualified class name (including nested
                      Outer.Inner or Outer$Inner) to its Maven artifact
                      (GROUP_ID:ARTIFACT_ID), from the cached class index.
                      For a package or function, use 'search'.
  search <query> [--force]
                      Search for artifacts by package, artifact, or class name
                      (using the cached GMaven index).
                      Use --force to rebuild the local package index.
  source <artifact>... [version]
                      Download and extract source JARs for one or more Maven artifacts.
                      Supports symbolic versions (e.g. ALPHA) or pinned versions.
                      Handles Kotlin Multiplatform platform sources automatically.
                      Options: -o/--output <dir>, --find <pattern>
  javadoc <artifact>... [version]
                      Download and extract Javadoc HTML JARs (-javadoc.jar) for
                      one or more Maven artifacts (e.g. closed-source SDKs).
                      Options: -o/--output <dir>, --find <pattern>
  inspect <name> [version]
                      Convenience wrapper that resolves a class name to an artifact
                      and downloads its source (falling back to javadoc if needed).
  doctor              Report dependencies, offline mode, and cache state.
                      Exits non-zero if anything needs attention.

Options:
  -h, --help          Display this help message and exit

Environment Variables:
  AGENT_OFFLINE       Set to 1 to answer only from the local cache and never
                      use the network. Cached answers are served whatever their
                      age, with that age noted on stderr; a cache miss names
                      the command to re-run with network, never a guess.
  JETPACK_CACHE_DIR   Cache directory
                      (default: ${XDG_CACHE_HOME:-$HOME/.cache}/jetpack)
  XDG_CACHE_HOME      Base directory for cache (default: $HOME/.cache)

Examples:
  # Check the latest stable version
  jetpack version androidx.wear.tiles:tiles STABLE

  # Check the latest alpha version
  jetpack version androidx.wear.tiles:tiles ALPHA

  # Resolve a class to its artifact
  jetpack resolve androidx.core.splashscreen.SplashScreen
  # Output: androidx.core:core-splashscreen

  # Search for libraries related to 'compose'
  jetpack search androidx.wear.compose

  # Force update the search index
  jetpack search --force androidx.wear

  # Download source code for the latest SNAPSHOT
  jetpack source androidx.wear.tiles:tiles SNAPSHOT

  # Inspect source code for a class (downloads and extracts)
  jetpack inspect androidx.lifecycle.ViewModel

  # List all versions
  jetpack list versions androidx.wear.tiles:tiles

  # Download specific snapshot build by ID
  jetpack source androidx.wear.tiles:tiles 14765146

  # Run once where there is network (which caches what it fetched), then
  # answer the same question with none
  jetpack version androidx.wear.tiles:tiles
  AGENT_OFFLINE=1 jetpack version androidx.wear.tiles:tiles
```

<!-- /generated -->

## version

**Purpose**: Get specific version type for a Jetpack package. **Synopsis**:
`scripts/jetpack version PACKAGE_NAME [VERSION_TYPE_OR_BUILD_ID] [REPO_URL]`
**Arguments**:

- `PACKAGE_NAME`: Maven coordinate (e.g., `androidx.wear.tiles:tiles`).
- `VERSION_TYPE_OR_BUILD_ID`: `ALPHA`, `BETA`, `RC`, `STABLE`, `LATEST`,
  `SNAPSHOT`, or a specific build ID integer (e.g., `14765146`) for a pinned
  snapshot (default: `STABLE`).
- `REPO_URL`: Custom Maven repo URL (ignored for SNAPSHOT or build ID).
  **Examples**:
- `scripts/jetpack version androidx.wear.tiles:tiles`
- `scripts/jetpack version androidx.wear.tiles:tiles ALPHA`
- `scripts/jetpack version androidx.wear.tiles:tiles 14765146`

**Raw Commands**:

```bash
# Fetch maven-metadata.xml
curl -sSLf "https://dl.google.com/android/maven2/GROUP/PATH/ARTIFACT/maven-metadata.xml"

# Parse version (e.g., STABLE)
xmllint --xpath "//version/text()" - | tr ' ' '\n' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n 1
```

## list versions

**Purpose**: List all versions for a package. **Synopsis**:
`scripts/jetpack list versions PACKAGE_NAME [REPO_URL]` **Arguments**:

- `PACKAGE_NAME`: Maven coordinate.
- `REPO_URL`: Custom Maven repo URL. **Examples**:
- `scripts/jetpack list versions androidx.wear.tiles:tiles`

## list dependencies

**Purpose**: List direct Maven dependencies for an artifact. **Synopsis**:
`scripts/jetpack list dependencies ARTIFACT [VERSION] [REPO_URL]` **Arguments**:

- `ARTIFACT`: Maven coordinate.
- `VERSION`: Version specifier (optional, defaults to `STABLE`).
- `REPO_URL`: Custom Maven repo URL. **Examples**:
- `scripts/jetpack list dependencies androidx.wear.tiles:tiles`

## resolve

**Purpose**: Convert Android class name (including nested `Outer.Inner` or
`Outer$Inner`) to Maven coordinate. **Synopsis**:
`scripts/jetpack resolve CLASS_NAME` **Arguments**:

- `CLASS_NAME`: Fully qualified class name (top-level or nested). **Examples**:
- `scripts/jetpack resolve androidx.lifecycle.ViewModel`
- `scripts/jetpack resolve com.google.android.gms.wearable.NodeClient.OnNodeMigratedListener`

**Raw Commands**: N/A (logic is the script's class matching over the cached
GMaven index).

## search

**Purpose**: Search for artifacts by package or class name. **Synopsis**:
`scripts/jetpack search [OPTIONS] QUERY` **Arguments**:

- `QUERY`: Substring to search for (e.g., `androidx.wear` or `RemoteImage`).
  **Options**:
- `--force`: Force cache rebuild (ignore existing index). **Examples**:
- `scripts/jetpack search androidx.wear.compose`
- `scripts/jetpack search RemoteImage`
- `scripts/jetpack search --force androidx.wear`

**Raw Commands**: N/A (the cached GMaven class index, refreshed with `--force`).

## source

**Purpose**: Download and extract source JARs. **Synopsis**:
`scripts/jetpack source [OPTIONS] PACKAGE... [VERSION] [REPO_URL]`
**Arguments**:

- `PACKAGE`: Maven coordinate(s).
- `VERSION`: Version specifier (symbolic or pinned).
- `REPO_URL`: Custom Maven repo URL. **Options**:
- `-o`, `--output DIR`: Directory to extract to (default: temp dir).
- `--find PATTERN`: Locate files matching PATTERN in the source and print their
  contents (single match) or paths (multiple matches). **Examples**:
- `scripts/jetpack source androidx.wear.tiles:tiles`
- `scripts/jetpack source --output src_dir androidx.core:core 1.6.0`
- `scripts/jetpack source --find "TileService.java" androidx.wear.tiles:tiles`

**Raw Commands**:

```bash
# Download source JAR
curl -sSLf "https://dl.google.com/android/maven2/GROUP/PATH/ARTIFACT/VERSION/ARTIFACT-VERSION-sources.jar" -o sources.jar

# Extract
jar xf sources.jar
```

## javadoc

**Purpose**: Download and extract raw `.html` reference documentation from
`-javadoc.jar` archives (for closed-source Google Maven or Maven Central
libraries that do not publish `-sources.jar`). **Synopsis**:
`scripts/jetpack javadoc [OPTIONS] PACKAGE... [VERSION] [REPO_URL]`
**Arguments**:

- `PACKAGE`: Maven coordinate(s).
- `VERSION`: Version specifier (symbolic or pinned).
- `REPO_URL`: Custom Maven repo URL. **Options**:
- `-o`, `--output DIR`: Directory to extract to (default: temp dir).
- `--find PATTERN`: Locate matching `.html` page(s). Prints HTML contents when a
  single match `≤ 64 KiB` (`65536` bytes) is found, or prints the extracted file
  path(s) when larger or when several pages match. **Examples**:
- `scripts/jetpack javadoc com.google.android.gms:play-services-wearable`
- `scripts/jetpack javadoc --find NodeClient.OnNodeMigratedListener com.google.android.gms:play-services-wearable`
- `scripts/jetpack javadoc -o /tmp/gson-docs com.google.code.gson:gson 2.11.0`

**Raw Commands**:

```bash
# Download Javadoc JAR
curl -sSLf "https://dl.google.com/android/maven2/GROUP/PATH/ARTIFACT/VERSION/ARTIFACT-VERSION-javadoc.jar" -o javadoc.jar

# Extract
jar xf javadoc.jar
```

## inspect

**Purpose**: Convenience wrapper combining `search`/`resolve` + `source` (with
automatic fallback to `javadoc` when `-sources.jar` is absent). **Synopsis**:
`scripts/jetpack inspect [OPTIONS] CLASS_NAME [VERSION] [REPO_URL]`
**Arguments**:

- `CLASS_NAME`: Class name (top-level or nested, resolved to coordinate) OR
  coordinate.
- `VERSION`: Version specifier. **Options**:
- `-o`, `--output DIR`: Directory to extract to. **Examples**:
- `scripts/jetpack inspect androidx.core.splashscreen.SplashScreen`
- `scripts/jetpack inspect com.google.android.gms.wearable.NodeClient.OnNodeMigratedListener`
- `scripts/jetpack inspect RemoteImage SNAPSHOT`

**Raw Commands**: Combines logic from `resolve`, `search`, `source`, and
`javadoc`.

## doctor

**Purpose**: Report whether this environment can answer, and from what.
**Synopsis**: `scripts/jetpack doctor` **Examples**:

- `scripts/jetpack doctor`
- `AGENT_OFFLINE=1 scripts/jetpack doctor`

**Notes**: Read-only. Exits non-zero on any `WARN`/`ERROR`, so an offline CI job
or agent session can gate on it. Reports missing dependencies rather than
exiting `127` on the first one.

## Offline Use

There is no warm-cache command: every online run writes what it fetched into
`${JETPACK_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/jetpack}/http/`, mirroring
the URL. Preparing for an offline run therefore means running the same command
once where there is network, and a cache miss quotes that command back:

```bash
scripts/jetpack inspect androidx.wear.tiles.TileService              # caches
AGENT_OFFLINE=1 scripts/jetpack inspect androidx.wear.tiles.TileService
```

The GMaven class index behind `search`/`resolve` is refreshed by
`scripts/jetpack search --force QUERY` (which refuses to run offline, since it
deletes the index it cannot then rebuild).

<!-- markdownlint-restore MD013 -->

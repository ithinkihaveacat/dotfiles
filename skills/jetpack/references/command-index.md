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
- [inspect](#inspect)
- [resolve-exceptions](#resolve-exceptions)
- [Exceptions Table](#exceptions-table)

## Help

The block below is `scripts/jetpack --help`, kept in sync by
`command-index-sync` (coding-standards skill); do not edit it by hand. The
sections that follow add per-subcommand detail and raw commands.

<!-- generated: ../scripts/jetpack --help -->

```text
Usage: jetpack <command> [arguments]

Jetpack library utilities for working with AndroidX packages.
This tool helps resolve Maven artifacts, finding versions, and downloading
source code for AndroidX libraries, including support for SNAPSHOT builds.

Commands:
  version <artifact> [type] [repo]
                      Get the version string for a Maven artifact.
                      Types: ALPHA, BETA, RC, STABLE, LATEST, SNAPSHOT, or BUILD_ID.
                      Default: STABLE.
  list versions <artifact> [repo]
                      List all versions for a given Maven artifact.
  list dependencies <artifact> [version]
                      List direct Maven dependencies for a given Maven artifact.
  resolve <name>      Convert a fully qualified class name or package prefix to
                      its corresponding Maven artifact (GROUP_ID:ARTIFACT_ID).
                      Uses internal heuristics and an exceptions table.
  search <query> [--force]
                      Search for artifacts by package name (using cached index)
                      or class name (using Android Code Search).
                      Use --force to rebuild the local package index.
  source <artifact>... [version]
                      Download and extract source JARs for one or more Maven artifacts.
                      Supports symbolic versions (e.g. ALPHA) or pinned versions.
                      Handles Kotlin Multiplatform platform sources automatically.
                      Options: --output <dir>, --find <pattern>
  inspect <name> [version]
                      Convenience wrapper that resolves a class name to an artifact
                      and then downloads its source.
Options:
  --help              Display this help message and exit

Environment Variables:
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

**Purpose**: Convert Android package/class name to Maven coordinate.
**Synopsis**: `scripts/jetpack resolve PACKAGE_NAME` **Arguments**:

- `PACKAGE_NAME`: Fully qualified class or package name. **Examples**:
- `scripts/jetpack resolve androidx.lifecycle.ViewModel`
- `scripts/jetpack resolve androidx.compose.ui.Modifier`

**Raw Commands**: N/A (Logic is internal script heuristics + table lookup). See
[Exceptions Table](#exceptions-table).

## search

**Purpose**: Search for artifacts by package or class name. **Synopsis**:
`scripts/jetpack search [OPTIONS] QUERY` **Arguments**:

- `QUERY`: Substring to search for (e.g., `androidx.wear` or `RemoteImage`).
  **Options**:
- `--index`: Force searching the package index (offline cache).
- `--code`: Force searching code (Android Code Search).
- `--force`: Force cache rebuild (ignore existing index). **Examples**:
- `scripts/jetpack search androidx.wear.compose`
- `scripts/jetpack search RemoteImage`
- `scripts/jetpack search --force androidx.wear`

**Raw Commands**:

- Uses `https://dl.google.com/android/maven2/master-index.xml` for package
  index.
- Uses `cs.android.com` (Android Code Search) API for class search.

## source

**Purpose**: Download and extract source JARs. **Synopsis**:
`scripts/jetpack source [OPTIONS] PACKAGE... [VERSION] [REPO_URL]`
**Arguments**:

- `PACKAGE`: Maven coordinate(s).
- `VERSION`: Version specifier (symbolic or pinned).
- `REPO_URL`: Custom Maven repo URL. **Options**:
- `--output DIR`: Directory to extract to (default: temp dir).
- `--find PATTERN`: Locate files matching PATTERN in the source and print their
  path. **Examples**:
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

## inspect

**Purpose**: Convenience wrapper combining `search`/`resolve` + `source`.
**Synopsis**:
`scripts/jetpack inspect [OPTIONS] CLASS_NAME [VERSION] [REPO_URL]`
**Arguments**:

- `CLASS_NAME`: Class name (resolved to coordinate) OR coordinate.
- `VERSION`: Version specifier. **Options**:
- `--output DIR`: Directory to extract to. **Examples**:
- `scripts/jetpack inspect androidx.core.splashscreen.SplashScreen`
- `scripts/jetpack inspect RemoteImage SNAPSHOT`

**Raw Commands**: Combines logic from `resolve`, `search`, and `source`.

## resolve-exceptions

**Purpose**: Find missing exceptions for `resolve` command. **Synopsis**:
`scripts/jetpack resolve-exceptions LIBRARY_COORDINATE` **Arguments**:

- `LIBRARY_COORDINATE`: Maven coordinate to analyze. **Examples**:
- `scripts/jetpack resolve-exceptions androidx.wear:wear`

**Raw Commands**: Downloads SNAPSHOT source JAR, lists all packages in it, and
checks if `resolve` correctly maps them back to the coordinate.

## Exceptions Table

The `resolve` command uses an internal table to map package prefixes to Maven
coordinates for libraries that don't follow standard naming conventions.

**Why it exists**: Standard heuristic is `androidx.group:group-artifact`.
Exceptions: `androidx.lifecycle` -> `androidx.lifecycle:lifecycle-runtime`
(instead of `lifecycle:lifecycle`).

**Adding exceptions**: Use `resolve-exceptions` to find missing mappings, then
edit the `exceptions` array in `scripts/jetpack` (canonical source;
`bin/jetpack` is the symlink entrypoint).

<!-- markdownlint-restore MD013 -->

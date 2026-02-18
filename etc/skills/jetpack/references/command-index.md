<!-- markdownlint-disable MD013 -->

# Command Index

## Contents

- [version](#version)
- [versions](#versions)
- [resolve](#resolve)
- [search](#search)
- [source](#source)
- [inspect](#inspect)
- [resolve-exceptions](#resolve-exceptions)
- [Exceptions Table](#exceptions-table)

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

## versions

**Purpose**: List all available versions for a package. **Synopsis**:
`scripts/jetpack versions PACKAGE_NAME [REPO_URL]` **Arguments**:

- `PACKAGE_NAME`: Maven coordinate.
- `REPO_URL`: Custom Maven repo URL. **Examples**:
- `scripts/jetpack versions androidx.wear.tiles:tiles`

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
- `--code`: Force searching code (Android Code Search). **Examples**:
- `scripts/jetpack search androidx.wear.compose`
- `scripts/jetpack search RemoteImage`

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
**Synopsis**: `scripts/jetpack inspect [OPTIONS] CLASS_NAME [VERSION]
[REPO_URL]` **Arguments**:

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
edit the `exceptions` array in `bin/jetpack`.

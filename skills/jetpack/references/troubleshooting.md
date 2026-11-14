# Troubleshooting

<!-- markdownlint-disable MD013 -->

## Contents

- [Missing Dependencies](#missing-dependencies)
- [Network Errors](#network-errors)
- [Search Failures](#search-failures)
- [Resolution Failures](#resolution-failures)
- [Version Not Found](#version-not-found)
- [Kotlin Multiplatform](#kotlin-multiplatform)

## Missing Dependencies

**Symptom**: `jetpack: required command 'COMMAND' not found`. **Cause**: The
script relies on system tools. **Solution**:

- `curl`: Standard on most systems.
- `xmllint`: `sudo apt-get install libxml2-utils` or macOS
  `brew install libxml2`.
- `jar`: Install a JDK (e.g., `default-jdk-headless` or via Android Studio).
- `jq`: `brew install jq` or `apt-get install jq`.
- `perl`: Standard on most systems.

## Network Errors

`version`, `list versions`, and `list dependencies` report two distinct
failures, and the message tells you which one happened:

**Symptom**: `could not reach .../maven-metadata.xml (curl exit N: ...)`.
**Cause**: The request never reached a server — no internet connection, a
firewall or sandbox blocking `dl.google.com`/`androidx.dev`, DNS failure, or a
timeout. This is **not** evidence the package is missing; treat the lookup as
unverified rather than as a "not found." **Solution**:

- Check internet/egress from wherever the script is running (some sandboxed
  agent environments block outbound network by default).
- Retry once connectivity is confirmed.

**Symptom**: `artifact '...' not found at .../maven-metadata.xml (404)`.
**Cause**: The server was reached and returned a genuine 404 — the package does
not exist in the specified repository, or the name is wrong. **Solution**:

- Verify package name is correct (e.g., `androidx.wear.tiles:tiles` vs
  `androidx.wear.tiles:wear-tiles`).
- Verify Build ID exists at `https://androidx.dev/snapshots/builds` (invalid or
  expired Build IDs 404 the same way).

## Search Failures

**Symptom**: Stale or missing results. **Cause**: The local class index
(`~/.cache/jetpack/androidx-index.json`) is outdated, and the network is down so
it cannot be rebuilt. **Solution**:

- Delete `~/.cache/jetpack/androidx-index.json`, or run
  `scripts/jetpack search --force QUERY`, where there is network.
- Offline, any existing index is used as-is; its age is reported on stderr.

## Resolution Failures

**Symptom**: `resolve` returns an incorrect coordinate or nothing. **Cause**:
The class is not in the cached index, or several artifacts declare it.
**Solution**:

1. Refresh the index: `scripts/jetpack search --force QUERY`.
1. Search for the class: `scripts/jetpack search CLASS_NAME`.
1. Use the coordinate directly: `scripts/jetpack source GROUP:ARTIFACT`.

## Version Not Found

**Symptom**: `no stable version found` or `no snapshot version found`.
**Cause**:

- Library is new and has no STABLE release yet (try ALPHA/BETA).
- Library is SNAPSHOT-only (must explicitly use `SNAPSHOT` type).
- Typo in package name.

## Kotlin Multiplatform

**Symptom**: Missing source files for platform-specific code. **Cause**: KMP
libraries have separate artifacts for `-android`, `-desktop`, etc. **Solution**:
The `source` and `inspect` commands automatically detect KMP libraries (via POM
analysis) and attempt to download platform-specific source JARs. Check the
output logs for "Detected Kotlin Multiplatform library".

<!-- markdownlint-restore MD013 -->

<!-- markdownlint-disable MD013 -->

# Troubleshooting

## Contents

- [Missing Dependencies](#missing-dependencies)
- [Network Errors](#network-errors)
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

## Network Errors

**Symptom**: `failed to fetch .../maven-metadata.xml`. **Cause**:

- No internet connection.
- Firewall blocking `dl.google.com` or `androidx.dev`.
- Package does not exist in the specified repository.
- Invalid or expired Build ID (artifacts are not kept forever). **Solution**:
- Check internet.
- Verify package name is correct (e.g., `androidx.wear.tiles:tiles` vs
  `androidx.wear.tiles:wear-tiles`).
- Verify Build ID exists at `https://androidx.dev/snapshots/builds`.

## Resolution Failures

**Symptom**: `resolve` returns incorrect coordinate or generic fallback.
**Cause**: The package name doesn't follow standard naming conventions and isn't
in the exceptions table. **Solution**:

1. Find the correct coordinate manually (e.g., search Google Maven).
2. Use `scripts/jetpack resolve-exceptions CORRECT_COORDINATE` to identify the
   missing mapping.
3. Use the coordinate directly: `scripts/jetpack source GROUP:ARTIFACT`.

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

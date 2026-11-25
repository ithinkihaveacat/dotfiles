# Troubleshooting

<!-- markdownlint-disable MD013 -->

## Contents

- [Missing Dependencies](#missing-dependencies)
- [Network Errors](#network-errors)
- [Search Failures](#search-failures)
- [Resolution Failures](#resolution-failures)
- [Closed-Source Libraries and Empty Javadoc JARs](#closed-source-libraries-and-empty-javadoc-jars)
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

`version`, `list versions`, and `list dependencies` report three distinct
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
**Cause**: The server was reached and returned a genuine 404 or 410 — the
package does not exist in the specified repository, or the name is wrong.
**Solution**:

- Verify package name is correct (e.g., `androidx.wear.tiles:tiles` vs
  `androidx.wear.tiles:wear-tiles`).
- Verify Build ID exists at `https://androidx.dev/snapshots/builds` (invalid or
  expired Build IDs 404 the same way).

**Symptom**:
`... returned HTTP 429 (the server is reachable but did not serve the resource; this says nothing about whether it exists)`,
followed by `cannot determine whether '...' exists`. **Cause**: The server
declined to answer — rate limiting, forbidden, or a server-side failure. Unlike
a 404, this is **not** evidence the package is missing. **Solution**:

- Wait and retry; rate limits usually clear within minutes.
- Don't change the package name on this message alone.

## Search Failures

**Symptom**: Stale or missing results. **Cause**: The local class index
(`~/.cache/jetpack/androidx-index.json`) is outdated, and the network is down so
it cannot be rebuilt. **Solution**:

- Delete `~/.cache/jetpack/androidx-index.json`, or run
  `scripts/jetpack search --force QUERY`, where there is network.
- Offline, any existing index is used as-is; its age is reported on stderr.

## Resolution Failures

**Symptom**: `no artifact declares 'X'` or
`could not resolve or find artifact for 'X'`. **Cause**: `resolve` and `search`
query the cached Google Maven class index (`classes-v0.1.json.gz`), which only
indexes Google Maven (`androidx.*`, `com.google.android.*`, etc.) and lists
top-level classes. Nested classes (`pkg.Outer.Inner` or `pkg.Outer$Inner`)
automatically resolve via their enclosing top-level class, whereas a package
name, a Kotlin top-level function, or a library hosted on Maven Central (such as
Horologist, Koin, Ktor, or Coil 3) will not match `resolve`. **Solution**:

1. Search the package on Google Maven, then pick a coordinate:
   `scripts/jetpack search androidx.compose.foundation.layout`.
1. For Maven Central libraries (or any known coordinate), pass `GROUP:ARTIFACT`
   directly — coordinate commands automatically fall back to Maven Central:
   `scripts/jetpack source --find KoinApplication io.insert-koin:koin-core`,
   `scripts/jetpack javadoc --find Gson com.google.code.gson:gson`, or
   `scripts/jetpack inspect com.google.android.horologist:horologist-media-ui-material3`.
1. If a Google Maven class known to exist still misses, refresh the index:
   `scripts/jetpack search --force QUERY`.

## Closed-Source Libraries and Empty Javadoc JARs

**Symptom**: `source: failed to download ...-sources.jar: ... returned HTTP 404`
with `hint: no -sources.jar published ...; try 'jetpack javadoc ...'`.
**Cause**: Closed-source SDKs (such as Google Play Services, Play Billing, ML
Kit, and parts of Firebase) publish `-javadoc.jar` API reference HTML instead of
`-sources.jar`. **Solution**:

- Run `scripts/jetpack javadoc [--find CLASS] GROUP:ARTIFACT [VERSION]`, or use
  `scripts/jetpack inspect CLASS_OR_COORD`, which falls back to `-javadoc.jar`
  automatically when `-sources.jar` returns HTTP 404.

**Symptom**:
`javadoc: ...-javadoc.jar contains no class documentation HTML pages (empty or placeholder -javadoc.jar)`.
**Cause**: Wrapper artifacts (such as `com.google.mlkit:barcode-scanning` or
`com.google.firebase:firebase-analytics`) and some Kotlin Multiplatform target
JARs publish a stub `-javadoc.jar` containing only `META-INF/MANIFEST.MF` or a
0-byte/index-only placeholder while the documented classes live in a direct
dependency. **Solution**:

- Inspect direct dependencies to locate the underlying API artifact:
  `scripts/jetpack list dependencies GROUP:ARTIFACT`, then run
  `scripts/jetpack javadoc` against the dependency coordinate (for example,
  `com.google.android.gms:play-services-mlkit-barcode-scanning` or
  `com.google.android.gms:play-services-measurement-api`).

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

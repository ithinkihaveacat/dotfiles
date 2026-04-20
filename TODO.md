# TODO

## Incorporation of GMaven Indices into `jetpack`

- `[ ]` Replace custom search and indexing in `jetpack` script with pre-built
  GMaven indices.

### Goal and Motivation

The current `jetpack` script builds a minimal local index of groups from
`master-index.xml` and relies on scraping an undocumented Android Code Search
API for class lookups. This is fragile and subject to API changes. The goal is
to transition to using the pre-built JSON indices provided for Android Studio.
This will improve search speed, eliminate the fragile Code Search dependency for
released artifacts, and provide complete version listings without extra network
calls.

### Current Status

This work is **BLOCKED** by a bug in the indexer (Bug ID: `b/504591566`) which
causes approximately 67% of the artifacts in the class index to have empty class
lists (specifically affecting Kotlin Multiplatform base artifacts and core
libraries like `androidx.annotation:annotation`).

### Implementation Details

#### Data Sources

When the bug is resolved, the following indices should be used:

- **Classes Index:**
  `https://dl.google.com/android/studio/gmaven/index/release/v0.1/classes-v0.1.json.gz`
  - Maps `groupId` + `artifactId` + `version` to a list of fully qualified class
    names (`fqcns`).
- **Packages Index:**
  `https://dl.google.com/android/studio/gmaven/index/release/v0.1/packages-v0.1.json.gz`
  - Maps `groupId` (packageId) to `artifactId` and all available `versions`.

#### Instructions for Resuming Work

1. **Caching**: Implement a mechanism to download these files to a cache
   directory (e.g., `~/.cache/jetpack`) and refresh them if they are older than
   24 hours.
2. **Querying**: Use `jq` to query the uncompressed JSON files. They are large
   but `jq` handles them quickly (under 0.5s).
3. **Test Compatibility**: The existing test `tests/jetpack/test-search` mocks
   the old index format (an array of objects with a `"group"` key). The updated
   `search_index` function must auto-detect the file format (array vs object) to
   ensure tests continue to pass without modification.

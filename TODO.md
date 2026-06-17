# TODO

## Align shellcheck Versions Between CI Jobs

- `[ ]` Install the same pinned shellcheck (v0.11.0, from GitHub releases) in
  the `test` job of `.github/workflows/lint.yml` as in the `shellcheck-shfmt`
  job, instead of apt's older version.

The lint job pins v0.11.0 while the test job (and typical local apt installs)
gets 0.9.x. The versions disagree on findings (e.g. apt's 0.9.x flags
SC2120/SC2119 in `jetpack` and `video-find-hd` that v0.11 does not), so "passes
locally" and "passes in CI" can diverge. A shared install step (or composite
action) removes the ambiguity.

## Surface Plugin Load Failures in `doctor`

- `[ ]` Make `skill doctor` (and the other plugin-loading tools' doctor
  commands) report plugins that failed to load.

A plugin that fails to load currently produces only a one-line stderr warning
that scrolls past; `doctor` then reports a healthy catalog that is silently
missing that plugin's skills. The loader should record load failures and
`doctor` should list them (e.g. "plugin 20_corp.py failed to load"), fitting the
doctor-as-drift-detection pattern.

## skill Cleanups and Legacy Shim Retirement

- `[ ]` Fix the misleading dedup comment in `cmd_catalog` ("Remove it from
  plugin_catalog" — it actually edits the grouped output).
- `[ ]` Collapse the `load_plugins`/`load_plugins_catalog` pair into one
  function.
- `[ ]` After a deprecation window, delete the `LEGACY_FLAGS` migration shim and
  the hidden `list` alias for `catalog` in `skill`.

## Duplicate Skill Detection and Resolution

We recently introduced duplicate collapsing in `gather_skills` to prevent
warnings in `resolve_selection` when a skill is found in multiple search paths
(e.g., both active and in the catalog cache, or across different CitC clients).

### Current Tradeoffs

- **Robustness:** We collapse duplicates by name, keeping the first one
  encountered (based on search path precedence). This ensures `suggest` always
  works and doesn't drop recommendations.
- **Visibility:** To prevent silently hiding configuration issues (like stale
  symlinks pointing to old CitC clients), we print a warning to `stderr` showing
  both the kept and ignored paths with their sources.

### Future Work

- `[ ]` **Report Duplicates in Catalog:** Update `skill catalog` to list skills
  in all groups they are found in (instead of silently deduplicating them), and
  highlight conflicting duplicates (same name, different targets) with a
  `(! CONFLICT)` marker.
- `[ ]` **Integrate with `doctor`:** Make `skill doctor` detect and report these
  duplicate conflicts as environmental drift.
- `[ ]` **Pruning Tooling:** Provide a way to easily prune stale active symlinks
  (e.g., `skill prune` or automatic cleanup in `apply` if the target client is
  gone).

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
1. **Querying**: Use `jq` to query the uncompressed JSON files. They are large
   but `jq` handles them quickly (under 0.5s).
1. **Test Compatibility**: The existing test `tests/jetpack/test-search` mocks
   the old index format (an array of objects with a `"group"` key). The updated
   `search_index` function must auto-detect the file format (array vs object) to
   ensure tests continue to pass without modification.

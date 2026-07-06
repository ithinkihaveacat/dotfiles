# TODO

## Centralize and extend .envrc management (2026-06-26) — done

Consolidated `.envrc` management in the `envrc` tool. Earlier work added
list-based skills editing (`envrc add|remove|list skills`) and ready-to-run
hints in `skill` (commit `729ed4f`). Completed the remainder:

- Added generic env-var commands (`envrc set|unset|get VAR`, backed by a
  managed `env` block with injection-safe single-quoted values) and generic
  block commands (`envrc show TYPE`, `envrc create block NAME` from stdin),
  plus a `uv` type for Python workspaces.
- Audited other write paths: nothing besides `envrc` writes `.envrc`;
  `bin/python-install`'s printed tip (a destructive `echo ... > .envrc`) now
  suggests `envrc create uv` instead.
- Moved `envrc` to `skills/workspace-config/scripts/` with a `bin/` symlink
  (matching `skill`/`permission`), documented it in the skill's SKILL.md and
  command-index.md, declared `envrc create block` unsafe in
  `permissions/unsafe`, and relocated its tests to
  `skills/workspace-config/tests/test-envrc` (they now run in CI).
- Resolved the `skill`/`envrc add skills` UX seam by keeping the two commands
  separate (deliberate) but aggregating `skill`'s per-skill hints into a
  single multi-skill `envrc add skills foo bar baz` suggestion.

## Detect and resolve duplicate skills (2026-06-12)

**Goal:** Provide better visibility and tools to handle duplicate skills in
different search paths (preventing silent configuration issues like stale
symlinks pointing to old checkouts), collapse duplicate listings resolving to
identical paths, and keep namespace categorization clean.

**Criteria:**

- `skill catalog` lists skills in all groups they are found in (instead of
  silently deduplicating different sources), highlights conflicting duplicates
  (same name, different targets) with a `(! CONFLICT)` marker, and collapses
  duplicate entries that point to the exact same path.
- Cached remote catalog stubs (e.g., in `get_catalog_dir()`) are not incorrectly
  scanned and listed as `local:` skills.
- `skill doctor` detects and reports duplicate conflicts as environmental drift.
- A pruning tool (e.g., `skill prune` or automatic cleanup in `apply` if the
  target client is gone) is provided to easily prune stale active symlinks.

**Sketch:**

- Robustness: We collapse duplicates by name, keeping the first one encountered
  (based on search path precedence) so `suggest` always works and doesn't drop
  recommendations.
- Visibility: Currently we print a warning to `stderr` showing kept and ignored
  paths. Future work involves integrating with `catalog`, `doctor`, and adding a
  pruning tool.
- Namespace Pollution: `cmd_catalog()` scans `get_catalog_dir()` as part of
  `source_dirs`, converting remote stubs to the `local:` namespace because the
  frontmatter metadata is parsed. This directory should be treated differently
  or excluded from the filesystem local skill scan.

## Align shellcheck versions between CI jobs (2026-06-11) — done

Aligned `shellcheck` versions used across CI jobs by installing pinned
`shellcheck` v0.11.0 (from GitHub releases) in the `test` job of
`.github/workflows/lint.yml` (commit `cd76d9f`), eliminating differences in
static analysis warnings (e.g., SC2120/SC2119 in `jetpack` and `video-find-hd`
which occurred on apt's older v0.9.x).

## Surface plugin load failures in doctor (2026-06-11)

**Goal:** Make `skill doctor` (and other plugin-loading tools' doctor commands)
report plugins that failed to load, rather than silently omitting them from a
"healthy" catalog. A plugin that fails to load currently produces only a
one-line stderr warning that scrolls past; `doctor` then reports a healthy
catalog that is silently missing that plugin's skills.

**Criteria:** The loader records load failures and `doctor` lists them (e.g.,
"plugin 20_corp.py failed to load"), fitting the doctor-as-drift-detection
pattern.

## Retire legacy skill shims and perform code cleanups (2026-06-11) — done

Completed several cleanups on the `skill` tool (commit `352e1aa`):

- Fixed the misleading deduplication comment in `cmd_catalog` ("Remove it from
  plugin_catalog" — it actually edits the grouped output).
- Collapsed the `load_plugins`/`load_plugins_catalog` pair into one function.
- Deleted the `LEGACY_FLAGS` migration shim and the hidden `list` alias for
  `catalog` in `skill`.

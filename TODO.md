# TODO

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

## Surface plugin load failures in doctor (2026-06-11)

**Goal:** Make `skill doctor` (and other plugin-loading tools' doctor commands)
report plugins that failed to load, rather than silently omitting them from a
"healthy" catalog. A plugin that fails to load currently produces only a
one-line stderr warning that scrolls past; `doctor` then reports a healthy
catalog that is silently missing that plugin's skills.

**Criteria:** The loader records load failures and `doctor` lists them (e.g.,
"plugin 20_corp.py failed to load"), fitting the doctor-as-drift-detection
pattern.

# TODO

## Align shellcheck Versions Between CI Jobs

- `[x]` Install the same pinned shellcheck (v0.11.0, from GitHub releases) in
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

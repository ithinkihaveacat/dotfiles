# TODO

## Rebase the CLI design standard on clig.dev with a local delta (2026-07-09)

**Problem:** `skills/coding-standards/references/cli-tools.md` is a ~300-line
custom standard that substantially overlaps clig.dev
(<https://clig.dev/llms.txt>) and contradicts it in a few places: it forbids
`-h` for help where clig.dev requires supporting it; it bans pagers where
clig.dev recommends `less -FIRX` for long output; it mandates identical output
for every help invocation where clig.dev wants concise help on missing arguments
and full help on `--help`; and it declares version information unnecessary where
clig.dev lists `--version` as a standard flag. An audit (2026-07-09) found the
overlap is large and the genuinely local content is small, so maintaining a
parallel full standard mostly invites drift.

**Goal:** `cli-tools.md` becomes "follow clig.dev" plus a short delta of local
amendments — only material clig.dev does not cover, or where this repo
deliberately diverges. The delta must preserve:

- The vocabulary standard (current §5): `list` vs `catalog`, `doctor` vs
  `status`, `create`/`delete` vs `add`/`remove` vs `install`/`uninstall` vs
  `set`, the mandatory `rm` alias, and the ban on `check`/`verify`/`validate` as
  command names.
- The verb-noun (kubectl-order) mandate and the two specialized patterns
  (Manager and Utility, with `packagename` and `apk-cat-file` as reference
  implementations). clig.dev permits either word order; this repo fixes one.
- Exit-code specifics: `0` for requested help, `>0` for usage errors, `127` for
  missing dependencies, `130`/`143` on SIGINT/SIGTERM with the newline-to-stderr
  behavior.
- Output-format defaults: git-style state-change reporting and rsync-style
  single-updating-line progress remain the house interpretation of clig.dev's
  output section, and the canonical `doctor` output style (see the companion
  item below) is part of the delta.
- The `--output` contract from CLAUDE.md (create the path if missing, never
  delete an output directory on success), now also accepting `-o` per clig.dev's
  standard flag names.

Resolved in clig.dev's favor: `-h` becomes a help alias (companion item below);
missing required arguments print concise help (description, an example, pointer
to `--help`) rather than only "Try --help"; pagers are permitted with clig.dev's
guards (`less -FIRX`, TTY only) though rarely warranted. Softened rather than
adopted wholesale: `--version`, support/docs links in help text, and the
distribution/analytics sections are treated as not applicable to personal
utility scripts.

**Criteria:** `cli-tools.md` consists of a pointer to clig.dev plus the delta,
restating nothing clig.dev already covers; `shell.md` no longer repeats
CLI-design rules that contradict the new base (its "do not use `-h`" and "no
version information" guidance is gone or redirected to the delta); no document
in the repo still forbids `-h`.

**Constraints:** `shell.md`'s implementation content (shellcheck/shfmt,
`usage()` pattern, GNU error-message format, `require()`, jq guidance) is in
scope only where it restates CLI-design rules; the rest stands unchanged.
CLAUDE.md keeps its script-quality sections, updated to reference the new
structure.

## Accept -h as a help alias in every script (2026-07-09)

**Goal:** Every script that supports `--help` also accepts `-h` with identical
output and exit code, per clig.dev (support `-h`/`--help`, ignore other flags
when either is passed, and never overload `-h` with another meaning). This is
the mechanical bulk of the clig.dev migration: under the outgoing standard `-h`
was forbidden, and as of 2026-07-09 no script under `bin/` or
`skills/*/scripts/` handles `-h` at all, so it currently falls through to
unknown-flag or positional-argument handling.

**Criteria:** A grep audit finds zero scripts that handle `--help` without also
handling `-h` (127 of 132 `bin/` entries handle `--help` today); `-h` help paths
exist for subcommands wherever `subcommand --help` exists; fish completions in
`fish/completions/` are updated where a completion file exists;
`bin/command-index-sync --check --all` passes; the suites under `tests/` pass.

**Sketch:** `bin/` entries are symlinks into `skills/*/scripts/`, so edit the
canonical sources. Around 118 scripts define `usage()`; the common patterns are
a top-of-script `[[ "$1" == "--help" ]]` guard and case-statement flag parsers,
so the change is mechanical but per-script. The audit found no script using `-h`
for human-readable sizes, so there are no collisions; if one ever wants it,
clig.dev's rule wins and the size flag gets a different letter. The
concise-help-on-missing-arguments behavior from the rebase item touches the same
argument-handling preamble — doing both in one pass per script avoids visiting
100+ files twice.

**Constraints:** No behavior changes beyond help handling. Keep bash 3.2
compatibility, and shellcheck/shfmt per `shell.md`.

## Standardize doctor output on the emumanager tag style (2026-07-09)

**Problem:** The repo's two `doctor` implementations render differently.
`emumanager doctor` (`run_doctor()`,
`skills/emumanager/scripts/emumanager:1435`) prints plain, column-aligned ASCII
tags — `[OK]`, `[INFO]`, `[WARN]`, `[ERROR]` — with indented detail lines and
remediation commands inline under each finding. `skill doctor` (`cmd_doctor()`,
`skills/workspace-config/scripts/skill:1916`) prints colored glyph tags — green
`[✓]`, yellow `[!]`, red `[✗]` — with remediation collected into a trailing "To
resolve these issues:" section and a success banner. Two styles in one toolbox
defeats the point of having a standard.

**Goal:** One canonical doctor output style, documented in the cli-tools delta
and implemented by both tools: emumanager's bracketed uppercase tags. Rationale:
the words are greppable (`... | grep '^\[WARN\]'`) and fully legible without
color, which satisfies clig.dev's NO_COLOR and non-TTY rules for free, whereas
glyph tags (the `flutter doctor` family that `skill` follows) degrade to
ambiguous punctuation once color is stripped. Color may still be layered onto
the tags when stdout is a TTY, as an enhancement, never as the sole carrier of
meaning.

**Criteria:** The delta doc specifies the tag set, alignment, remediation
placement, and the exit contract (read-only, non-zero on any finding — which
both tools already honor); `skill doctor` output uses the canonical style; no
doctor command in the repo emits glyph-only status tags.

**Sketch:** In `skill`, rendering is concentrated in `format_status()` and the
check-rendering loop inside `cmd_doctor()`, so this is a rendering-layer change,
not a checks change. Remediation placement: per-finding (emumanager) is
suggested over a collected trailing section, since findings scroll away from
their fixes otherwise; a one-line closing summary is fine. The open item
"Surface plugin load failures in doctor" (2026-06-11) touches the same command —
whoever picks up either item should check whether the other has landed.

## Surface plugin load failures in doctor (2026-06-11)

**Goal:** Make `skill doctor` (and other plugin-loading tools' doctor commands)
report plugins that failed to load, rather than silently omitting them from a
"healthy" catalog. A plugin that fails to load currently produces only a
one-line stderr warning that scrolls past; `doctor` then reports a healthy
catalog that is silently missing that plugin's skills.

**Criteria:** The loader records load failures and `doctor` lists them (e.g.,
"plugin 20_corp.py failed to load"), fitting the doctor-as-drift-detection
pattern.

# TODO

## Verify adb-screenrecord duration fix and web streaming (2026-07-15)

**Goal:** Verify and regression-test the `adb-screenrecord` reliability and
faststart streaming improvements committed in `e01fb6c` across Wear OS watches
(Pixel Watch 3) and mobile devices.

**Criteria:** Executing `adb-screenrecord --duration N` on Wear OS
auto-terminates within N seconds, outputs a valid MP4 with faststart `moov`
header placed at the beginning of the container (verified via `ffprobe`), leaves
zero orphaned `screenrecord` background processes on-device, and passes
`scripts/shell-format` cleanly.

**Sketch:** Reference commit
[`e01fb6ce2cfdf091aac6c4d5a2507202c73b7c03`](https://github.com/stillers/dotfiles/commit/e01fb6ce2cfdf091aac6c4d5a2507202c73b7c03)
(`e01fb6c`) in `skills/adb/scripts/adb-screenrecord`. Test signal handling
(`timeout --foreground -s INT`), on-device cleanup
(`adb shell killall -2 screenrecord`), `ensure_faststart()` remux bypass for raw
capture, and macOS `gtimeout` fallback detection. Double-check whether Pixel
Watches (e.g. Pixel Watch 3 `selene`) actually require the raw frame capture
mechanism (`USE_RAW=1`) or if their hardware video encoder supports native
`adb shell screenrecord` without raw mode.

## Clarify remediation choices in skill preflight and doctor error messages (2026-07-15)

**Problem:** In `skill preflight` and `skill doctor` error reports (such as
mismatched or extra skill warnings), remediation hints list multiple commands
(e.g., `export AGENT_REQUIRED_SKILLS=...`, `skill remove ...`, `skill apply`)
without explaining which source of truth each command honors or what state it
overwrites. For example, when extra skills exist on disk, `skill apply` will
prune the disk symlinks (treating `AGENT_REQUIRED_SKILLS` as authoritative),
whereas adding to `AGENT_REQUIRED_SKILLS` preserves the disk symlinks. The
current output does not distinguish between these choices based on user intent.

**Goal:** Restructure remediation hints in `skill doctor` and `skill preflight`
failure reports to explicitly distinguish between resolution paths based on
which source of truth (disk vs. environment) the user considers correct.

**Criteria:** When reporting extra, missing, or mismatched skills, preflight and
doctor hints clearly group commands under intent-based headers (e.g., "If the
skills on disk are correct: ...", "If your environment variable is correct (will
prune extra symlinks): ..."), and test assertions in `test-skill` verify the new
hint output shape.

**Sketch:** Update the finding formatting functions in
`skills/workspace-config/scripts/skill` (such as `cmd_doctor` finding
formatters) to categorize remediation actions by user intent and source
authority:

- *Disk is authoritative:* Recommend `envrc add skills <names>` or
  `export AGENT_REQUIRED_SKILLS=...`.
- *Environment is authoritative:* Recommend `skill apply`, explicitly noting
  that extra symlinks will be unlinked.
- *Manual removal:* Recommend `skill remove <names>`.

## Unify skill doctor/apply behind a shared reconciliation planner (2026-07-14) — done

Introduced a single `build_reconcile_plan(workspace)` in
`skills/workspace-config/scripts/skill` that both `cmd_doctor` and `cmd_apply`
consume: doctor renders the returned `ReconcilePlan` read-only, and apply
executes its permitted actions, then recomputes the plan and fails if any
apply-fixable finding survives (`ReconcilePlan.has_fixable_findings()`). This
replaces the two parallel definitions of convergence that had produced a
recurring class of doctor/apply non-convergence bugs. Added `ResolvedSkill`
(declared spec, resolved source path, canonical `link_name` fixed at resolution
time, typed resolution error) and `DiskEntry` (destination, path, kind, target,
tracked) types, plus a non-raising `resolve_reconcile_skill()` wrapper so both
commands classify specs identically. The freshness interlock and the "any
unresolved desired spec blocks destructive actions" safety rule are now plan
policies (`stale`, `destructive_blocked`) rather than special-cased branches in
the prune loop; the dangling prune stays ungated. Extra-vs-mismatch
classification keys on resolved link names (a wrong-target link whose basename a
resolved spec will recreate is a mismatch apply re-links, not an extra it
deletes), unifying the rule doctor and apply previously disagreed on. The
planner is a plain-class, importable shape with direct in-process unit tests
(`test-skill` tests 70–73) covering the missing/unresolved split, the empty
desired set, on-disk extra/stray/tracked-dangling classification, and
mismatch-vs-extra; the existing end-to-end suite (69 → 73 cases) still passes.
Not done, left as follow-up: fully splitting catalog download/cache mutation out
of `resolve_skill_spec`/`fetch_github` so doctor's read-only contract holds
during a cold remote fetch.

## Run permissions and git setup tests offline with pre-warmed cache (2026-07-14)

**Problem:** Like `test-skill` before its refactor, `test-permission` and
`test-git-setup` isolate their test environments by overriding `HOME` to a mock
directory. This isolates the test from the host user's environment, but also
hides the `~/.netrc` credentials needed by `uv` to authenticate with the
corporate Airlock registry. This causes 401 Unauthorized errors in corporate
environments when executing `skill` (which requires `google-genai`).

**Goal:** Ensure all tests that invoke `skill` or `permission` scripts (which
use `uv` and may require packages) run reliably offline without authentication
or network requirements, maintaining strict test hermeticity.

**Criteria:** `test-permission` and `test-git-setup` pass successfully in an
offline sandbox (e.g. using standard sandbox mode or with `UV_OFFLINE=1`).

**Sketch:** Apply the same "Pre-Warmed Cache" pattern implemented in
`test-skill`: warm the `uv` cache using the host's credentials and network (if
`UV_CACHE_DIR` is not already set) before overriding `HOME`, and then run the
tests with `UV_OFFLINE=1` enabled.

## Support downloading canary/preview emulator images in emumanager (2026-07-13)

**Goal:** `emumanager` should support downloading and installing system images
from the preview/canary tracks (SDK manager channel 3). Currently, downloading a
preview system image (e.g. Wear OS API 37) requires running
`sdkmanager --channel=3` manually before creating or starting the emulator, as
`emumanager`'s internal `download_image` logic does not expose or pass the
`--channel` parameter to `sdkmanager`.

**Criteria:** Running
`emumanager download package "system-images;android-37.0;android-wear-signed;arm64-v8a"`
successfully downloads and installs the preview image without manual
pre-downloading.

**Sketch:** Update `download_image()` and `create_avd()` in
`skills/emumanager/scripts/emumanager` to accept a `--channel` option or
automatically pass a default channel if the package target is identified as
canary/preview.

## Add debug/test-mode switch to emumanager start (2026-07-13)

**Goal:** Add a `--test-mode` / `--debug` switch to `emumanager start avd` that
automatically prepares the emulator for automated testing once booted,
contingent on verifying that OOBE/tutorial overlays are actually present and
blocking. If verified to be necessary, this switch will remove the need for
developers/agents to manually run ADB commands to wake the device, dismiss the
keyguard, and bypass Wear OS OOBE setup and tutorial overlays.

**Criteria:** Starting a Wear OS emulator with
`emumanager start avd <name> --test-mode` automatically places the device in an
unlocked, tutorial-bypassed state ready for UI automation.

**Sketch:** First, investigate and confirm whether standard Wear OS emulator
images (such as API 37 signed/unsigned) actually display tutorial overlays or
remain locked on clean boot. If they boot straight into the home state without
overlays, this bypass logic may be unnecessary. If they do block, integrate the
following commands into the boot completion monitoring loop of `start_avd()` in
`skills/emumanager/scripts/emumanager`:

```bash
adb shell input keyevent KEYCODE_WAKEUP
adb shell wm dismiss-keyguard
adb shell am broadcast -a com.google.android.clockwork.action.TEST_MODE
adb shell am broadcast -a com.google.android.clockwork.action.TUTORIAL_SKIP
```

## Make the agent-review documentation world class (2026-07-13)

**Problem:** `skills/agent-tools/references/agent-review.md` (plus the "Second
Opinions" section in `SKILL.md`) was written in one pass immediately after the
first two successful uses of the workflow — an Oracle plan review and a codex
code review during the ptracker backfill work. It documents what worked that
day, verified only against that day's `--help` output. Three structural
weaknesses are already visible, and the external CLIs it documents (`codex`,
`claude`, `agy`) ship frequently, so the flag-level details will drift.

**Goal:** The review-related documentation is trustworthy (documented
invocations verifiably work), coherent (one conceptual frame instead of a
tool-by-tool list), and complete (no TODO stubs), so that any agent picking a
reviewer gets the right mechanism and an optimal invocation on the first try.

**Criteria:** Every command line in the docs either runs successfully as written
or is covered by a drift-detection test under `skills/agent-tools/tests/`; the
`agy` recipe is written (or the heading is removed with a rationale); the docs
distinguish the code-review path from the general-review path as first-class
sections; an agent reading only the docs can produce a correct review invocation
for each row of the decision table without consulting `--help`.

**Sketch:** Known work items, roughly ordered:

- **Validate switches and arguments.** The recipes were checked against
  `codex-cli 0.144.1` and one `claude --help` grep. Confirm each documented flag
  exists and is the *optimal* choice — e.g. whether `codex exec review` should
  pin a model or reasoning effort, whether `claude -p` needs
  permission-mode/read-only or model flags for review use, whether
  `--output-format` improves findings capture. Since these CLIs change quickly,
  prefer a small drift test (run `<tool> --help`, grep for the documented flags,
  fail on mismatch) in `skills/agent-tools/tests/` over periodic manual
  re-audits; `references/command-index.md` already has a `command-index-sync`
  marker convention that may be reusable here.
- **Normalize invocation shapes.** The three working recipes are invoked three
  different ways (codex: heredoc into `codex exec -`; claude: prompt argument or
  stdin pipe; oracle: prompt + positional files). Decide whether to paper over
  this with a thin `scripts/review` wrapper (one interface:
  `review --with codex|claude|oracle [--base main | --pr URL | FILES...]`,
  emitting the house findings format) or to keep raw invocations but normalize
  the prompt template and findings taxonomy (critical/major/minor/nit) into one
  canonical block that every recipe references instead of restating.
- **Reframe around two review kinds, not five tools.** The Oracle is not a
  code-review tool that happens to take files — it is a general
  deep-consultation mechanism (used for plan review, architecture decisions,
  research synthesis). Restructure into (a) **code review** — specific,
  diff-anchored, where purpose-built tools exist (codex, `claude -p`, and
  harness-native mechanisms like `/code-review` where available), and (b)
  **general review** — plans, designs, documents, decisions — where the Oracle's
  session-brief pattern is the ideal fit and emerson is the closed-book variant.
  The decision table then keys on review kind first, tool second.
- **Write the `agy` recipe** (currently a TODO stub), or drop the heading if
  Antigravity has no sensible non-interactive review mode.
- **Candidates worth evaluating while in there:** cost/latency guidance per
  mechanism (oracle consultations are heavyweight; codex/claude one-shots are
  not); when to run two reviewers vs. one (cross-vendor diversity argument is
  stated but not operationalized); whether the "Handling the Findings"
  disposition record should get a canonical format the commit/PR templates in
  `technical-writing` can reference; whether `gh-markdown`-piped PR review
  deserves a worked example with real output shape; and whether SKILL.md's copy
  of the decision table should be generated from `agent-review.md` to avoid the
  two drifting apart.

**Constraints:** Keep `agent-review.md` as the single detailed source with
`SKILL.md` carrying only a pointer-plus-table summary; no new heavyweight
dependencies for the drift tests (shell + grep in the existing test layout).

## Migrate remote (repo) cached skills from ~/.cache/skill-select to ~/.cache/skill (2026-07-10) — done

Updated `get_cache_base()` and `get_catalog_dir()` in
`skills/workspace-config/scripts/skill` to store remote GitHub skill caches
under `~/.cache/skill/remotes` and catalog indexes under
`~/.cache/skill/catalog`, using the `SKILL_CACHE_DIR` environment variable.
Updated corresponding test assertions in
`skills/workspace-config/tests/test-skill`, added cleanup for legacy
`~/.cache/skill-select` directories in `install.sh`, and updated
`SKILL_SELECT_DEBUG` references in
`skills/coding-standards/references/python.md`.

## Fix stale `# Tests:` pointers in scripts and tests (2026-07-09)

**Problem:** `# Tests:` comments predate the flat, co-located test layout now
documented in `tests/README.md` and were never migrated. An audit (2026-07-09)
found 22 of 26 pointers stale: they name old directory-style paths that no
longer exist — root-level `tests/video-index/` where the test now lives at
`tests/test-video-index` (`bin/video-index:6`), or `tests/pacioli/` where it
moved to `skills/agent-tools/tests/test-pacioli`
(`skills/agent-tools/scripts/pacioli:6`). Both the scripts under test and the
test files themselves carry stale pointers.

**Goal:** Every `# Tests:` comment points at a path that exists, matching the
convention in `tests/README.md` ("Link back from the script"). The comment
exists so tests are discoverable via `grep '# Tests:'`; a pointer to a missing
path defeats that.

**Criteria:** This audit reports zero stale entries:

```bash
grep -rn '^# Tests:' bin skills/*/scripts skills/*/tests tests --no-messages \
  | sed 's/:[0-9]*:# Tests: */\t/' \
  | awk -F'\t' '{ if (system("test -e \"" $2 "\"")) print "STALE", $1, "->", $2 }'
```

**Sketch:** A mechanical find/replace per pointer. One open call: test files
carrying their own `# Tests:` comment (e.g. `tests/test-git-setup:3`) —
`tests/README.md` only asks for the comment on the script under test, so either
make these self-referential (as `tests/test-git-hooks-multiplexer` already is)
or drop them.

**Constraints:** Comment-only edits; no behavior changes.

## Standardize concise help on missing required arguments (2026-07-09)

**Problem:** `cli-tools.md` already states the rule (adopted from clig.dev): a
tool invoked without required arguments should print a brief description, one or
two examples, and a pointer to `--help` — not full help text, and not only "Try
--help". No script was changed to implement it when `-h` support was added (PR
#134), because it's a per-script judgment call, not a mechanical find/replace. A
grep audit of `bin/` and `skills/*/scripts/` (2026-07-09) found at least three
different existing behaviors for missing required arguments, all still live:

1. **Full help text, exit 1** — e.g. `usage 1 >&2` in `bin/csv-query:28` and
   `bin/image-mask-circular:38`. Dumps everything (all examples, every flag) to
   stderr for a simple "you forgot an argument" error.
1. **Bare error, no pointer to `--help`** — e.g.
   `echo "$(basename "$0"): missing operand" >&2; exit 1` in
   `bin/macos-bootout:40`. Correct exit code, but no example and no "Try
   '--help'" pointer, which even the outgoing standard's GNU-style error
   convention wanted.
1. **No args treated as an implicit help request, exit 0** — e.g.
   `if [[ "$1" == "--help" || "$1" == "-h" || -z "$1" ]]; then usage; fi` in
   `skills/adb/scripts/adb-demo:40` and `skills/adb/scripts/adb-fontscale`. This
   is clig.dev's "bare complex command shows help" allowance, but these are
   simple single-action tools (Appendix A patterns), not `git`-style subcommand
   tools — treating missing-args as a request for help (exit 0) instead of a
   usage error (exit >0) breaks scripting (`tool; echo $?` can't distinguish
   "ran fine" from "forgot an argument").

**Goal:** One consistent behavior for simple (non-subcommand) tools invoked
without a required positional argument: print a short usage line, one example,
and a pointer to `--help`/`-h` to stderr, then exit `1` — never the full help
text, never a bare error with no example, never exit `0`. Complex subcommand
tools (the `kubectl`-style and Manager-pattern tools covered by `cli-tools.md`'s
Appendix A) are explicitly out of scope here: clig.dev's bare-command-shows-help
allowance is for them, and `git-hooks-multiplexer`, `skill`, `jetpack`, etc.
already implement it deliberately.

**Criteria:** `shell.md` documents a short concise-usage pattern (e.g. a
`usage_short()` helper or an inline `die_usage`-style one-liner, whichever reads
more like the rest of the file) developers can drop into the `if [[ $# -lt N ]]`
preamble. Every simple-pattern script in `bin/` and `skills/*/scripts/` that
currently does pattern 1, 2, or 3 above for a *required* positional argument is
converted to the new behavior and exits `1`. `shellcheck`/`shfmt` clean;
existing test suites still pass (a few tests likely assert today's
exit-0-on-no-args or full-help-dump behavior and will need updating alongside
the scripts they cover).

**Sketch:** Grep for `usage 1 >&2`, `missing operand`, and
`-z "\$1"[^]]*--help\|--help[^]]*-z "\$1"` across `bin/` and `skills/*/scripts/`
to enumerate the full set (the three examples above are a starting sample, not
the complete list). Decide per script whether the first positional argument is
actually required — some of the `-z "$1"` tools may have a legitimate zero-arg
default behavior rather than a missing required argument, in which case they're
out of scope and should be left alone rather than forced into a usage error.

**Constraints:** No behavior change for scripts whose missing-argument case is
genuinely a valid default (not an error). Keep bash 3.2 compatibility. Don't
touch the complex subcommand tools' bare-invocation-shows-help behavior.

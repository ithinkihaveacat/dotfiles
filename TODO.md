# TODO

## Investigate adding deterministic image difference tool or integrating with screenshot-compare (2026-07-21)

**Problem:** `screenshot-compare` in `agent-tools` provides AI-powered textual
visual comparison between images, but lacks a fast, deterministic
pixel/perceptual difference metric (such as Pillow-based RMSE/MSE similarity).
Creating a standalone image diff tool would overlap with `screenshot-compare`'s
domain unless their roles are unified. Additionally, `screenshot-compare` is not
invoked by agents as frequently as expected during visual verification tasks
(agents often fall back to writing custom comparison scripts).

**Goal:** Evaluate whether to introduce a dedicated CLI tool under `agent-tools`
for deterministic image similarity/diffing or integrate deterministic
exact-match and numerical difference calculation (RMSE/MSE/similarity %)
directly into `screenshot-compare`.

**Criteria:** Clear guidance or tooling is established for fast, deterministic
1-to-1 visual difference calculations, with `screenshot-compare` either handling
the deterministic check natively or delegating to a clear companion tool.

**Sketch:** Consider extending `screenshot-compare` to run an optional
deterministic exact-match / RMSE difference pre-check before or alongside
AI-powered textual analysis.

For reference, the inline source code of `audit_image_pairs.py` used for
deterministic Pillow-based similarity auditing:

```python
import sys
import json
import math
from pathlib import Path
from PIL import Image, ImageChops, ImageStat

REPO_ROOT = Path("/Users/stillers/workspace/wear-os-samples/WearWidget")
COMPOSED_DIR = REPO_ROOT / "app" / "screenshots"
EMULATOR_DIR = REPO_ROOT / "emulator_report_v3" / "emulator"

def crop_content(img):
    # Convert to RGB and find bounding box of non-black pixels to compare core content
    gray = img.convert("L")
    bbox = gray.getbbox()
    return img.crop(bbox) if bbox else img

def calculate_similarity(img1_path, img2_path):
    try:
        im1 = Image.open(img1_path).convert("RGB")
        im2 = Image.open(img2_path).convert("RGB")

        # Resize im1 to match im2 dimensions
        im1 = im1.resize(im2.size, Image.Resampling.LANCZOS)

        # Compute Difference
        diff = ImageChops.difference(im1, im2)
        stat = ImageStat.Stat(diff)
        
        # Mean squared error per channel
        mse = sum(stat.sum2) / (float(im1.size[0] * im1.size[1]) * 3.0)
        rmse = math.sqrt(mse)
        
        # Convert RMSE (0..255) to 0..100% similarity
        similarity = max(0.0, 100.0 - (rmse / 2.55))
        return round(similarity, 2), round(rmse, 2)
    except Exception as e:
        return 0.0, 255.0

def main():
    if not COMPOSED_DIR.exists():
        print(f"Error: {COMPOSED_DIR} does not exist.")
        sys.exit(1)

    preview_files = sorted(list(COMPOSED_DIR.glob("*.png")))
    print(f"Auditing {len(preview_files)} widget preview pairs...\n")

    passed = []
    failed = []

    for preview_path in preview_files:
        name = preview_path.stem
        emu_path = EMULATOR_DIR / f"{name}.png"

        if not emu_path.exists():
            failed.append((name, "MISSING_EMULATOR_CAPTURE", 0.0, 255.0))
            continue

        sim, rmse = calculate_similarity(preview_path, emu_path)
        
        # Consider similarity >= 60.0% as visual match (accounting for OS theme/font rendering differences)
        if sim >= 60.0:
            passed.append((name, sim, rmse))
        else:
            failed.append((name, "VISUAL_MISMATCH", sim, rmse))

    print("=" * 70)
    print(f"AUDIT SUMMARY: {len(passed)} MATCHED | {len(failed)} MISMATCHED / MISSING")
    print("=" * 70)

    if failed:
        print("\nMISMATCHED / MISSING PAIRS:")
        for item in failed:
            if item[1] == "MISSING_EMULATOR_CAPTURE":
                print(f"  ❌ {item[0]:45s} -> Missing emulator capture")
            else:
                print(f"  ❌ {item[0]:45s} -> Sim: {item[2]:5.2f}% (RMSE: {item[3]:5.2f})")

    if passed:
        print("\nVERIFIED MATCHING PAIRS (Sample):")
        for item in passed[:10]:
            print(f"  ✅ {item[0]:45s} -> Sim: {item[1]:5.2f}% (RMSE: {item[2]:5.2f})")

    # Save full audit json
    audit_data = {
        "total": len(preview_files),
        "passed_count": len(passed),
        "failed_count": len(failed),
        "passed": [{"name": p[0], "similarity": p[1], "rmse": p[2]} for p in passed],
        "failed": [{"name": f[0], "reason": f[1], "similarity": f[2], "rmse": f[3]} for f in failed],
    }
    
    out_json = REPO_ROOT / "audit_results.json"
    with open(out_json, "w") as f:
        json.dump(audit_data, f, indent=2)
    print(f"\nSaved full audit report to {out_json}")

if __name__ == "__main__":
    main()
```

## Verify adb-screenrecord duration fix and scrcpy fallback prompting (2026-07-15) — done

**Goal:** Re-evaluate device mode selection in `adb-screenrecord` to prefer
`scrcpy` for non-Samsung Wear OS devices (like Pixel Watch 3) rather than
defaulting all watches to raw capture. Add `scrcpy` availability checks and
prompt the user to install `scrcpy` when missing.

**Criteria:** On non-Samsung devices (like Pixel Watch 3), `adb-screenrecord`
checks for `scrcpy` and prompts the user to install `scrcpy` if missing,
avoiding silent fallback to problematic native capture or forced raw mode.
Duration limit signal handling and faststart headers remain verified.

**Sketch:** Reference commit
[`e01fb6ce2cfdf091aac6c4d5a2507202c73b7c03`](https://github.com/stillers/dotfiles/commit/e01fb6ce2cfdf091aac6c4d5a2507202c73b7c03)
(`e01fb6c`) in `skills/adb/scripts/adb-screenrecord`. Revert the broad
`$CHARACTERISTICS` watch raw default for non-Samsung Pixel watches. If `scrcpy`
is missing on a non-Samsung device, print a clear error/prompt advising the user
to install `scrcpy` for optimal performance.

## Clarify remediation choices in skill preflight and doctor error messages (2026-07-15) — done

Reworked (second pass — the first "authoritative side" wording proved unclear)
the "Required Skills" reporting in `cmd_doctor` (shared by `skill doctor` and
`skill preflight`) in `skills/workspace-config/scripts/skill` around two short
side labels, defined where they are used instead of in a standing preamble:
*env* (the declared set, `AGENT_REQUIRED_SKILLS`) and *disk* (the symlinks in
the destination dirs). The summary line reads "environment and disk disagree
(…)" (or "cannot resolve the declared skill set (…)" when only
declaration-side defects exist), findings render as one aligned per-item list
(`emumanager   disk only (linked in .claude/skills, not in
AGENT_REQUIRED_SKILLS)`), and remediation is phrased as sync directions with
concrete effects: "Make disk match env (link X; delete the Y symlink): skill
apply" versus "Make env match disk (declare Y; keep the symlink): envrc add
skills Y && direnv reload" (raw `export` variant without `.envrc`). Every
suggested `envrc` command carries the `direnv reload` step, since the
environment stays stale until then. A per-skill mixing hint prints only when
there are two or more differences. The blocked-prune note is self-contained
(preflight suppresses the freshness WARNING it used to reference) and names
the by-hand `skill remove` fallback; when stale, `envrc add` is not suggested
for names `.envrc` already declares. Negated (excluded) skills are still never
suggested for re-declaration, and the verbose success banner lost its `✔`
glyph per the doctor output style. Tests 41/42/45/62/65 and 79–81 updated in
`skills/workspace-config/tests/test-skill`; the doctor example in
`skills/coding-standards/references/cli-tools.md` follows the new summary.

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

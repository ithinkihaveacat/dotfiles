# TODO

## Investigate test failures when running full test suite locally (2026-08-10)

**Problem:** Running the full test suite locally via
`prove -j 9 tests/test-* skills/*/tests/test-*` results in multiple test
failures across several modules (`test-pacioli`, `test-pascal`,
`test-python-format`, `test-permission`, `test-skill-*`, `test-hook`). In
contrast, the test suite passes on CI. This may be due to differences in network
access, missing cached dependencies, unauthenticated API calls (such as
`google-genai` registry access or `GEMINI_API_KEY`), or missing offline flag
guards (`UV_OFFLINE=1`, `AGENT_OFFLINE=1`, `GEMINI_API_KEY=""`).

**Goal:** Determine why full local `prove` runs produce failures while CI
passes, and make local test execution hermetic, reliable, and consistent with
documented offline/sandbox flags.

**Criteria:**

- Audit failure modes for `test-pacioli`, `test-python-format`,
  `test-permission`, `test-skill-*`, and `test-hook` when executed with standard
  `prove`.
- Verify whether CI sets environment variables (e.g. `UV_OFFLINE=1`,
  `AGENT_OFFLINE=1`, `GEMINI_API_KEY=""`) or if individual tests require
  graceful skip handling for missing network/API credentials.
- Update test runners or documentation in `tests/README.md` to ensure
  `prove -j 9 tests/test-* skills/*/tests/test-*` behaves predictably locally.

**Sketch:** Compare local test environment and flags against CI runner
configuration. Check `test-skill-*` failures for `uv` cache requirements and
corporate registry auth fallback, check LLM/Gemini API dependency handling in
`test-pacioli`/`test-pascal`, and check Python 3.14 / tool version assumptions
in `test-python-format`.

## Fix Markdown structure preservation and state tracking in commit-msg wrap_block() (2026-08-10)

**Problem:** `wrap_block()` in `etc/git/hooks/agent/commit-msg` has several
state-tracking and classification edge cases:

1. **Nested bullet context loss:** Scalar state variables (`bullet_marker`,
   `bullet_indent`, etc.) discard parent bullet context when a nested child
   bullet (e.g. `  - child`) opens. A subsequent parent continuation line falls
   through to prose and gets wrapped flush-left without indentation.
1. **Quoted code fences:** A fenced code block inside a blockquote
   (```` > ```text ````) is not recognized as a code fence because `FENCE_RE`
   expects leading whitespace, not blockquote markers. The blockquote reflow
   buffers the fence and code into a single prose run and rewrites it into \`>
   \`\`\`text preserve ... \`\`\`\`, destroying fences and code layout.
1. **ATX headings in body:** Overlong ATX headings (`## ...`) fall through to
   prose reflow, splitting the heading so only the first line retains the `#`
   marker and altering the document structure.
1. **Over-broad table detection:** `line.count("|") >= 2` classifies any line
   with two pipes (such as shell pipelines `cmd1 | cmd2 | cmd3`) as a table row
   and passes it through unwrapped. Because length validation is disabled when
   rewrapping runs, overlong shell pipelines silently bypass both rewrapping and
   length checks.

Found via code review on PR #147 (branch
`claude/auto-fix-commit-messages-namenc`).

**Goal:** Provide pragmatic preservation of common commit message structures
within `wrap_block()`. Full Markdown spec parsing is explicitly **not** required
or expected for commit messages; the hook only needs to handle structures
typically found in commit messages (bullet lists, code fences, blockquotes, git
trailers, and table rows). Heading weirdness in the body is simply preserved
verbatim.

**Criteria:**

- Parent bullet continuation lines following nested child bullets remain
  attached to the parent with proper indentation.
- Fenced code blocks inside blockquotes (```` > ```text ```` or `> ~~~text`) are
  preserved verbatim with blockquote markers retained on each line.
- ATX headings in the body are preserved verbatim rather than being split into
  prose.
- Table detection is restricted to actual table row syntax (e.g. pipe-delimited
  columns) rather than arbitrary lines containing two pipe characters, ensuring
  overlong shell pipelines are validated/wrapped appropriately.
- The `commit-msg` hook's module docstring and `--help`/usage output explicitly
  document the exact formatting structures it supports.
- All existing and new cases pass in `tests/test-hook-agent`.

**Sketch:**

- Replace scalar bullet state in `wrap_block()` with a stack of bullet contexts
  to handle nested indents.
- Detect quoted fence markers (```` > ```... ```` / `> ~~~...`) and pass quoted
  code blocks through verbatim.
- Add an ATX heading check (`^(\s*#{1,6}\s+.*)`) to pass body headings through
  verbatim.
- Tighten table row detection to require pipe column boundaries.
- Update `commit-msg` docstring to document supported structures.

**Constraints:** `wrap_block()` has had three fix commits on one branch already
(`16c88e19`, `c8bbd339`, `3dba2961`); change it carefully and re-run
`tests/test-hook-agent` in full.

## Measure and extend the Jetpack source-history evals (2026-08-04)

**Problem:** `pos-source-history-one-handed-gesture` is a source-derived tune
case added after the last recorded benchmark run. Its oracle establishes the
immutable `1.7.0-alpha05` to `1.7.0-alpha06` introduction boundary, but there is
no model result showing whether the skill improves correctness or cost on the
case. The repository also has no case for identifying an implementation change
and no genuinely hidden holdout; every manifest entry is visible during tuning.

**Goal:** Establish how much the Jetpack skill helps on source-history
questions, and broaden the suite beyond one known API. Preserve the distinction
between visible regression cases and unseen evidence of generalisation so later
results are not stronger claims than the benchmark supports.

**Criteria:**

- The existing source-history case is run with and without the skill under
  comparable sandbox and network conditions, with correctness, commands, tokens,
  and elapsed time recorded in `skills/jetpack/evals/README.md`.
- At least one pinned, source-derived case asks when an implementation changed,
  uses a different AndroidX API, and has a deterministic oracle test.
- A decision is recorded about where genuine holdout cases would be stored and
  who can inspect them. If no external arrangement is practical, the
  documentation continues to state that the suite has tune cases only.

**Sketch:** Run the existing case before changing the skill so its current
difficulty is measured rather than inferred. A follow-up case can compare
published source across releases and grade the first changed boundary, extending
the current first-presence oracle pattern without depending on floating alpha or
snapshot versions. A visible case must not be relabelled as a holdout: an actual
holdout belongs outside this public repository and is revealed only after the
skill revision is frozen.

**Constraints:** Keep the one-handed-gesture case as a regression test even if
future documentation or `jetpack search` makes it easier; reduced difficulty
does not invalidate its pinned historical answer. Do not tune the skill for this
case before recording the baseline run.

## Evaluate dropping per-tool offline overrides in favor of a universal AGENT_OFFLINE (2026-07-28)

**Problem:** We currently support both `<TOOL>_OFFLINE` and `AGENT_OFFLINE` for
every networked script. This requires extra plumbing in every tool and bloats
the `Environment:` section of every script's help text. A workspace-wide
`AGENT_OFFLINE` might be entirely sufficient since offline testing or sandbox
constraints typically apply to the whole environment, not just one tool in
isolation.

**Goal:** Determine if per-tool overrides carry enough practical value to
justify their complexity, or if they should be deprecated and removed in favor
of a single `AGENT_OFFLINE` contract. This would simplify script logic and
reduce documentation bulk.

**Criteria:** A decision is made and recorded on whether to drop
`<TOOL>_OFFLINE`. If dropped, all scripts and `caching.md` are updated to remove
the per-tool environment variables, and the help text templates are simplified.

**Sketch:** Review how often (if ever) `<TOOL>_OFFLINE` is genuinely used to
selectively disable network for one tool while leaving others online. If it's
only ever used as a fallback or never used in practice compared to
`AGENT_OFFLINE`, remove the per-tool checks and strictly read `AGENT_OFFLINE`.

## Evaluate error-trapped feature probing for fish completions in install.sh (2026-07-28)

**Problem:** `install.sh` generates fish completions for tools like `hcloud`,
`gog`, and `bat`/`batcat`. Recently, `bat`/`batcat` completion was updated to
feature-probe `--completion fish` and trap errors
(`if "$bat_cmd" --completion fish >"$tmp_comp" 2>/dev/null; ...`) so that older
tool versions or unexpected CLI flag changes do not halt `install.sh` under
`set -e`. Other tool completions in `install.sh` (e.g. `hcloud`, `gog`) still
execute `x <cmd> completion fish >...` directly without trapping errors, which
could cause `install.sh` to fail if a tool lacks completion support.

**Goal:** Review all fish completion generation logic in `install.sh` to ensure
consistency and guard against `install.sh` aborts on unsupported CLI completion
flags.

**Criteria:**

- Review completion generation for `hcloud`, `gog`, and any other tools in
  `install.sh`.
- Ensure completion generation is safe and non-fatal across different tool
  versions while maintaining `x` trace logging where appropriate.

**Sketch:**

- Audit `hcloud`, `gog`, and `bat` completion blocks in `install.sh`.
- Determine whether a common helper or consistent error-trapped probing pattern
  should be applied across all completion entries.

## Refactor test-skill suite to assert structured plans and split monolithic test file (2026-07-22)

**Problem:** `test-skill` (`skills/workspace-config/tests/test-skill`) has grown
into a 2,000+ line monolithic test file containing 85 test cases. A significant
portion of the suite relies on matching exact human-readable output strings and
error banners, which causes brittle test failures and heavy file churn whenever
CLI text formatting or phrasing is updated.

**Goal:** Shift `skill` test verification from full string matching to asserting
against structured plan representations, and modularize `test-skill` into
smaller, focused test files. Part of reducing test churn and improving
maintainability when updating `skill`.

**Criteria:**

- `skills/workspace-config/tests/test-skill` is broken down into smaller,
  domain-specific test files under `skills/workspace-config/tests/`.
- Test assertions primarily inspect structured output (e.g. via a `--json`
  output flag or structured plan inspection) rather than exact human-readable
  CLI strings, reserving string checks only for user-facing formatting
  contracts.
- The full test suite continues to pass hermetically.

**Sketch:**

- Investigate adding a `--json` output mode to
  `skills/workspace-config/scripts/skill` (or leveraging `build_reconcile_plan`)
  to output structured data suitable for test parsing (e.g., using `jq` or
  Python helpers).
- Group test cases into logical modules (such as `test-skill-reconcile`,
  `test-skill-doctor`, `test-skill-apply`, `test-skill-plugins`).

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

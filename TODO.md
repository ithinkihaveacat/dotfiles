# TODO

## Make installed git hooks propagate fixes and uninstall cleanly (2026-08-09)

**Problem:** Three unrelated mechanisms install hooks, all three copy the
hook file, and nothing detects that a copy has gone stale.

- `init.templatedir` (`home/.gitconfig:123`) copies
  `etc/git/templates/global/hooks/post-checkout` at clone time.
- `bin/git-hook-node` runs `git init --template=`, which only applies at
  `git init`. An existing repository can never be updated by it, so the
  pre-commit index fix (686f52d, PR #146) reaches no checkout that already
  exists.
- `bin/git-hook-agent` installs through `git-hook-multiplexer install`,
  which does reach existing repositories but leaves a frozen `cp` of the
  source.

`git-hook-multiplexer doctor` then tests only `-x` on the sub-hook, so a
copy that is years out of date reports `ok`. `~/workspace/ptracker` and
`~/workspace/inkyframe` are the live instance: both carry a diverged
pre-commit hook, and no command in this repository can say so.

Removal is all-or-nothing in the other direction. `bin/git-hook-none` is
`rm -rf "$(git rev-parse --git-dir)/hooks"`, which also deletes third-party
hooks (the Gerrit hook that `git-hook-gerrit` installs, husky), every
`<hook>.d/` directory, and the `00-legacy` hook the multiplexer carefully
preserved on install — with no confirmation and no way to drop one hook.

Three mechanics were measured against git 2.43.0 on 2026-08-09, since the
choice between copy and symlink turns on them:

- `git init --template=` preserves a symlink verbatim, so a symlink in a
  template only survives if its target is absolute.
- A dangling symlink at `.git/hooks/pre-commit` is *silently skipped*: the
  commit succeeded and exited 0. Moving or renaming `~/.dotfiles` would
  therefore disable every symlinked hook with no signal.
- A stub whose `exec` target is missing fails loudly — `exec: not found`,
  exit 1, commit aborted.

**Goal:** An installed hook should track its source in this repository, so
that fixing a hook here fixes it everywhere it is installed without a
manual re-copy; a hook whose source has gone away should fail loudly rather
than quietly stop running; and removing one hook should leave every other
hook alone. Part of making the hook system trustworthy enough to keep
putting policy in it — the pre-commit fix showed that a bug in a hook is
both easy to ship and, once copied, impossible to recall.

**Criteria:**

- Editing a hook source under `etc/git/` changes the behaviour of an
  already-set-up repository with no re-install step.
- A drifted or orphaned installation is a `doctor` finding that exits
  non-zero; today a stale copy reports `ok`.
- The node pre-commit hook can be installed into an existing repository
  without `git init`.
- Removing one managed hook leaves other managed hooks, third-party
  sub-hooks and `00-legacy` in place; when the last managed sub-hook goes,
  `00-legacy` is restored as the plain hook.
- `tests/test-git-hook-multiplexer` and `tests/test-git-hook-agent` cover
  install → drift → remove → restore.

**Sketch:** The decision the evidence above points to is a *trampoline*: the
installed file is a generated stub whose body is
`exec <absolute path into this repo> "$@"`. It keeps a symlink's
propagation without a symlink's silent-skip failure, and unlike a real
symlink it survives `git init --template=` without an absolute path baked
into a tracked file. This is not a new pattern —
`etc/git/templates/global/hooks/post-checkout` is already exactly this,
execing `$HOME/.dotfiles/bin/git-setup` — so the work is mostly applying it
consistently, resolving the absolute path at install time rather than
hardcoding `~/.dotfiles`.

The second-order benefit is what makes drift detectable at all: a stub's
content is generated and never changes, so `doctor` can compare it
byte-for-byte, where a copy of a hook can only be compared against a moving
target.

Other findings worth keeping:

- `git-hook-multiplexer` bakes `$hook_name` into the body it generates.
  Deriving the name from `basename "$0"` instead would make one generic
  file serve every hook name (git invokes the hook by its own path, so both
  `dirname "$0"` and `basename "$0"` still resolve correctly through a
  stub), and the multiplexer itself then becomes a trampoline too.
- Removal wants the `add`/`remove` pair from `cli-tools.md`:
  `remove <hook> <key>` with an `rm` alias, plus a `clean` that drops only
  managed hooks the way `permission clean` does. `git-hook-none` can stay
  as the nuclear option if it enumerates what it will delete and requires
  `--force`.
- Moving the node pre-commit hook onto the multiplexer retires
  `git init --template=` for content hooks, and is what would make
  ptracker and inkyframe fixable in place. `init.templatedir` then keeps
  exactly one job: the clone-time post-checkout trampoline.
- Six commands cover this one domain today (`git-hook-agent`,
  `-node`, `-gerrit`, `-none`, `-multiplexer`, plus the deprecated
  `git-updatehooks` stub, which prints "use 'git init' instead"). That is
  the hyphenated-command shape `cli-tools.md` says to avoid; a single
  `git-hook <verb>` manager is the Appendix A shape, with the current
  names kept as aliases since `bin/git-setup`, `home/.gitconfig` and the
  docs all reference them. Whether that consolidation belongs inside this
  item or after it is open.
- A `--copy` escape hatch is worth keeping for a machine that has no
  dotfiles tree to point at.

**Constraints:** A hook must never silently stop running — where loud
failure and silent skip trade off, take loud failure. `rm .git/hooks/<name>`
by hand must keep working as the documented escape hatch, and the
`00-legacy` preservation contract must survive. If this tooling ever moves
under a skill, `clean` and the `git-hook-none` equivalent need declaring
in that skill's `permissions/unsafe`; as `bin/` scripts they are not
pre-approved today. Out of scope: `core.hooksPath` as a delivery mechanism,
adopting a hook framework (husky, lefthook, pre-commit), and the read-only
`git-hook list` surface — this item only owes `doctor` the ability to see
drift.

## Auto-fix mechanically fixable commit messages (2026-08-09) — done

`etc/git/templates/agent/hooks/commit-msg` now rewraps over-long body/footer
lines in place instead of rejecting them; a non-Conventional-Commits or
over-50-character *subject* still exits 1, since fixing either would change
what the author said. The wrapper is a ~230-line PEP 723 script (stdlib
only, `dependencies = []`) piped into `uv run --script -` via a heredoc and
embedded directly in the hook file, since hooks here are copied rather than
linked — a separate companion script would silently stop tracking its
source. It runs after the existing `Co-Authored-By:`/`TAG=`/`CONV=` trailer
strip and before validation, and is skipped (like validation) for
`Merge`/`Revert`/`fixup!`/`squash!` subjects.

`mdformat` was evaluated first and rejected: it escaped `5*3` to `5\*3` and
`*.ts` to `\*.ts` on a realistic fixture (backslashes `git log` renders
literally), turned an indented block into a fenced one, and joined a
trailer block into a paragraph — with no escape-free mode, since the
escaping is part of its round-trip guarantee. A hand-rolled classifier does
better: each body line is fence, blank, table row (`|...|`), bullet
(`-`/`*`/`+`/`N.`/`N)`), indented (≥4 spaces or a tab), or prose; runs of
prose and bullet continuation lines are joined and re-flowed with
`textwrap.wrap(..., break_long_words=False, break_on_hyphens=False)`,
`initial_indent`/`subsequent_indent` giving bullets their hanging indent.
Fences, tables, indented blocks and a trailing trailer block pass through
byte-identical — the trailer block's boundary is found by asking
`git interpret-trailers --only-trailers --only-input --no-divider` (not by
hand-parsing trailer syntax) and checking whether its output equals the
message's own tail, which also handles folded multi-line trailer values
correctly. A single token longer than 72 (a URL) is left over-length rather
than split, since `break_long_words=False` already refuses to split it.
Idempotence (`wrap(wrap(x)) == wrap(x)`) falls out for free: wrapping
rejoins words with single spaces before re-wrapping, so a second pass sees
the same word sequence and produces the same breaks. A change is announced
on stderr (`commit-msg: rewrapped body/footer text to fit 72 characters`);
git's own comment lines (`^#`) are located and left untouched.

Opt-out is `git config hooks.commitMsgWrap false`, matching the
`hooks.preCommitRegexp` precedent in `home/.gitconfig`. The `uv`-failure
question the constraints raised is answered by falling back to the old
strict 72-character rejection (with an stderr note naming why) rather than
either silently accepting an over-long line or hard-failing the commit
outright — `command -v uv` missing and a non-zero `uv run` exit both take
this path, verified by removing `uv` from `PATH` and confirming the strict
check still fires. Verified working under both `bash` and `dash` (the
hook's shebang is `#!/bin/sh`).

Left as a hard rejection, not auto-fixed: the blank-second-line check. The
Criteria section only specified wrap-then-proceed behavior for body/footer
length and continued rejection for subject defects; inserting a blank
separator was not in the Criteria list (unlike wrapping, it also was not
evaluated against real fixtures the way `mdformat` was), so it stayed out of
scope rather than being added on an inference from the Problem section's
looser phrasing.

Review on PR #147 found three more real bugs, all fixed: a compliant
multi-line prose run (every line already ≤72) was still being rejoined and
re-flowed, changing the author's deliberate line breaks for no reason; a
nested bullet's own marker (`  - child` under `- parent`) satisfied the
parent's continuation-line check and got swallowed into the parent's
reflowed text, destroying the nested list; and blockquote lines (`> ...`)
had no dedicated handling at all, so wrapping a multi-line quote kept the
`>` only on the first output line. Fixed by: skipping the rejoin-and-wrap
step whenever every raw line in a run already fits WIDTH (prose, bullets
and blockquotes all check this before doing anything); checking for a
bullet marker before checking for plain continuation, so any line that
opens its own bullet — nested or not — always starts a fresh run instead of
being folded into whichever bullet is currently open; and giving
blockquotes their own run type, keyed on the exact quote-depth prefix (`>`
vs `>>`) so distinct depths never merge, with `>` as both
`initial_indent`/`subsequent_indent` so every wrapped line keeps its
marker.

`tests/test-git-hook-agent` grew from 8 to 19 cases: one per Criteria
bullet (rewrap-and-proceed, idempotence, fence/table/indented-block/trailer
byte-fidelity, the unbroken-URL case, bullet hanging indent, the stderr
announcement), the opt-out, and the three review fixes above. Test 5's old
fixture — two 73-character lines of repeated `x` with no spaces — is
exactly the unbreakable-token case now, so it no longer produces length
errors; only the pre-existing subject
and blank-line failures remain asserted. No code is shared with
`bin/markdown-format`; the 50/72 numbers stayed in `git.md`, untouched.

## Fix the node pre-commit hook's staged-file handling (2026-08-05) — done

The third sketched approach won: `etc/git/templates/node/hooks/pre-commit` now
formats the *index* and never re-adds from the working tree. For each staged
`.ts`/`.md` path it reads the staged blob (`git ls-files --stage` for the mode
and sha, `git cat-file blob` for the content), pipes it through
`prettier --stdin-filepath "$path"`, and stages the result with
`git hash-object -w` plus `git update-index --cacheinfo`. The working tree is
never read to decide what to commit, which is what the three reproductions all
came down to.

The cheaper "skip partially staged files" option was rejected because it cannot
meet the second criterion: a staged edit to a file deleted from the working tree
*is* a partially staged file, and skipping it either commits it unformatted or
refuses, where the criterion asks for the edit to be committed. It also answers
`git add -p` — the workflow the bug targets — with a refusal rather than with a
formatted commit, which is the whole point of having the hook.

Formatting happens in two passes: pass one formats every blob into a temp
directory, pass two stages the results. Nothing reaches the index unless every
file formatted successfully, so a missing or failing formatter aborts the commit
with the index exactly as the author staged it. `prettier` is resolved as
`npx --no-install prettier` first and a global `prettier` second — the template
now matches what the two installed copies actually do — and the commit fails
outright when neither exists, rather than the old behaviour of silently
re-staging without ever formatting.

The working tree still gets the formatting, but only where it is safe to give
it: when `git diff --quiet` says the file matches what was staged, the hook runs
`git checkout-index -f` after updating the index, so smudge filters apply and
the tree stays consistent. Where the tree carries unstaged work (or the file is
gone), it is left untouched and the hook says so on stderr. That closes the
"working tree still holds the unformatted text" cost the sketch attached to this
approach for every case except the one where the alternative is destroying
someone's edits.

Four smaller things fell out along the way. Paths are read `-z` from
`git diff --cached --name-only` into a bash array and never passed through
`xargs`, so a space is just a character. Pathspecs are `:(literal)` (git 1.9+):
without it, staging both `a1.ts` and `a[1].ts` makes the bracketed path's
pathspec match its sibling, and the sibling's content gets staged under the
wrong name — a corruption worse than the one being fixed, and now test 9.
Symlinks (120000) and gitlinks (160000) are skipped, since running a symlink's
target text through a markdown formatter is not formatting. And empty formatter
output for non-empty input is treated as a failure, so a `.prettierignore`d path
cannot blank a file. Unmerged paths never arrive: `--diff-filter=ACMR` excludes
them.

`tests/test-git-hook-node` covers all of it in 10 hermetic cases — the three
reproductions, the four failure modes, and the three edge cases above. The hook
runs with `PATH` pointing at a directory holding symlinks to the handful of
commands it needs plus a stub formatter (quotes normalised, trailing whitespace
stripped, so "formatted" is observable), which means no case can reach a real
prettier or the network, and the absent-formatter case is genuinely absent
rather than stubbed to fail. Separately verified by hand against real prettier
3.8.1: the partially staged commit contains only the staged hunk, the deleted
file's staged edit commits as an edit, and `my notes.md` commits.

Not done: `~/workspace/ptracker` and `~/workspace/inkyframe` still hold the old
copies. Hooks here are copied rather than linked, so both need a manual re-copy;
nothing in this repository can detect or fix that. Bash 3.2 was not verified
against a real 3.2 build (none available in the sandbox this ran in) — the hook
uses no 4.x feature, and the one 3.2 parser trap on record, a here-document
inside a command substitution, does not appear in it.

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

## Extend the offline convention to scripts that do not cache (2026-07-28) — done

`c405f27` audited "the five scripts that cache something", which was the right
scope for the cache rules and the wrong scope for everything else: it left ~30
scripts that make network calls outside any rule, because `cli-tools.md` bound
only tools that "fetch over the network **and** cache the result". Two of them
were actively lying about failures.

`caching.md` now opens with **Scope: Three Obligations**, each binding a smaller
set than the one before: legible failure for every script that makes a call, the
offline switch for scripts an agent or CI job drives, the cache rules only for
scripts that cache. A first draft made the switch universal too, which the repo
violated the day it landed — `whatismyip` and friends were left ungated — and
the fix was to narrow the standard rather than gate another ten scripts. The
line for the switch is whether a tool *spends* something before failing: a retry
budget, an agent loop, side effects on a device. A one-shot pipe that fails in a
second gains nothing from it that a clear error does not already give.

The distinction the section turns on is that a declared offline mode and an
absent network are different conditions — `AGENT_OFFLINE` is a policy stated up
front and means make no call at all, while a missing network is discovered by
failing and so has to fail legibly. A tool with nothing worth caching is exempt
from the cache rules regardless: a cache that could never be usefully read is
complexity with no payoff. `cli-tools.md` and `shell.md` were re-scoped to
match, the latter gaining the `set -e` trap that caused the worst of the bugs
below.

Rejected on the way: "a script with tests supports the switch, otherwise not".
Objective and checkable, but it tracks the wrong thing — it would keep
`markdown-extract-body` (a one-shot stdin pipe) and drop `popper`, which drives
a phone through an agent loop, and it makes adding a test incur new obligations,
which argues against writing tests.

Fixed, both cases of reporting a network failure as a result:

- `jetpack-samples` — a Gitiles fetch that failed for any reason printed
  `no files found for path <p>`, so a sandboxed caller concluded the artifact
  had no samples. It now has jetpack's `http_get` shape (no cache: it extracts a
  fresh tree into a caller-named directory, so there is nothing to serve), and
  separates a 404 from an unreachable host. `JETPACK_SAMPLES_OFFLINE` fails up
  front rather than spending the `--retry 5 --retry-delay 4` budget on calls the
  environment already forbade. Module archives now download to a file rather
  than straight into `tar`, so a per-module 404 can warn and continue while a
  lost network stops the run instead of under-reporting the module count.
- The Gemini family (`emerson`, `pascal`, `satisfies`, `screenshot-describe`,
  `token-count`, `photo-smart-crop`, `markdown-extract-body`,
  `uihierarchy-describe`, `uihierarchy-compare`) shared a copy-pasted
  `RESPONSE=$(... | curl -s ...)`. Under `set -euo pipefail` a curl that could
  not resolve the host killed the script *before* its error handler, so the
  caller got exit 6 and not one byte of output. All nine now read
  `-w '%{http_code}'` and capture curl's exit code. None of the nine carries the
  offline switch: each makes a single request and fails at once, so all nine
  copies of the shared block stay identical.

The status decides, not the exit code — found by the new test, in `token-count`,
whose curl is the tail of a `jq | curl` pipeline: under `pipefail` `CURL_STATUS`
is the pipeline's status, so a curl that answered 429 fine surfaced as a network
failure. `-w` emits three digits whenever a response arrived and `000` only when
none did, which is the authoritative signal; the exit code is kept for the
message.

`jetpack`'s own `http_get` had the same inversion, and there it was not latent:
the comment above the condition already cited curl exiting 56 on a complete 404
as the reason for reading `-w` at all, and then the condition `OR`-ed in
`curl_status -ne 0` and reported exactly that case as an unreachable host. Two
cases in `test-jetpack-offline` pin it, stubbing curl rather than trying to
provoke a real server into the behaviour; both fail against the old condition.
An empty status is now treated as "no response" too, which the old check missed
because it only compared against the literal `000`.

Python tools took the same split: `pacioli` and `photo-query` both gained a
`URLError`/`TimeoutError` arm distinct from the existing `HTTPError` one.
`photo-query` also takes the switch, since one invocation makes a request per
image across a glob; `pacioli` does not, being one email per run. `socrates`
gates at `get_client()` and `popper` immediately after argument parsing — before
it connects to the device, rewrites the screen timeout, unlocks, or launches an
app, so an offline run cannot leave the phone in a changed state — with
`--dump-layout` exempt, as it never calls the API. Both SDK tools keep
`APIError.code` for the "server said no" side.

Two `skill` nits from the same audit: `fetch_skill_md` checked its TTL before
the offline branch, the exact inversion `c405f27` fixed in `fetch_github` two
functions up, so the warm-then-freeze workflow took the silent path in the
common case; and `doctor` now reports mode, cache location and remote age, which
`jetpack doctor` already did.

Left alone, and why: `whatismyip`, `url-cat-*`, `url-save-markdown`,
`gh-markdown` (live PR state), `node`/`python`/`ruby-install` and the `*-init`
scripts — one-shot tools that fail fast, now covered by the first obligation
only. `emumanager` delegates downloads to `sdkmanager`, which owns its own
cache, and its `catalog` error already names the network.

One more thing the switch cannot reach, now recorded in `caching.md`: the four
PEP 723 tools run under `uv run --script`, which resolves and may download
dependencies before the interpreter reaches any check the script makes. A cold
`uv` cache still hits PyPI however `AGENT_OFFLINE` is set; it has to be paired
with `UV_OFFLINE`, which `tests/README.md` already does for the suites.

Tests are hermetic in both new files. `test-gemini-transport` runs three cases —
no response, an API error, a truncated 200 — against all nine scripts rather
than a representative, since drifting out of the shared block is what it exists
to catch; stub `curl` and `magick` on `PATH` force each outcome without touching
the network, needing ImageMagick, or needing a real `GEMINI_API_KEY`.
`test-jetpack-samples` gains four in the same style, and `test-jetpack-offline`
two for the truncated-transfer case.

Second review round, five more:

- `jetpack-samples` treated every non-2xx alike, so a 429 or 5xx from Gitiles
  read as "no files found" and an archive 5xx was skipped while the run still
  exited 0 with fewer modules. `http_get` now returns 1 only for 404/410 —
  actual evidence of absence — and 3 for a server that answered but did not
  serve, which is fatal at both call sites.
- `emerson` did not parse under bash 3.2, the version `shell.md` targets and the
  macOS default. Pre-existing (the merge-base fails too), but the new transport
  test surfaced it: 3.2 tokenizes a here-document body while scanning for the
  closing paren of a command substitution, so the apostrophe in "the user's
  prompt" inside `SYSTEM_INSTRUCTION=$(cat <<'EOF' ...)` broke the whole file.
  Rewritten as `IFS= read -r -d '' ... <<'EOF'`, which takes no such scan; the
  prompt text is byte-identical. Verified against a real 3.2 build, which also
  confirmed the other ten scripts and the two new tests are clean.
- `photo-query` checked offline inside the per-image request, and `run_query`
  catches per-image errors and continues — so a directory invocation
  preprocessed and cached every image before printing the same refusal once per
  file. One check in `main`, before path expansion.
- `socrates answer --mode model:...` reserved a run index with a placeholder
  answer before `get_client()` ran, so an offline run left a zombie responder in
  the database. Gated before `init_db`, and only for `model` modes — `shell` and
  `interactive` make no API call.
- `shell.md` still required the switch of every networked script, contradicting
  the narrowed scope in `caching.md`. Re-scoped to match.

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

## Continue evaluating jetpack with skill-eval-harness (2026-07-27) — done

All 6 `library-lookup` tune cases and all 6 `trigger` cases have been run, and
the harness earned its keep: three fixes landed as a direct result.

`skill-benchmark` over the 6 `pos-*` cases (Codex, workspace-write + network,
one run per variant) gives `with_skill` 1.0 against `without_skill` 0.42,
`case_flags` empty, sign-flip p=0.031. The lift is entirely *process*: with the
network open, the baseline arm answers most of these correctly by curling
`developer.android.com` or `android.googlesource.com` by hand, so the outcome
assertions are base-saturated and only the `command_ran` assertions
discriminate. That is worth knowing before reading any future outcome delta on
this manifest as a capability claim.

What the harness caught, in the order it caught it:

- **A real jetpack bug** (`c5b6d0b3`). Running under `run-codex`'s default
  sandbox — read-only, which is what a warmed cache is supposed to make
  survivable — `jetpack version` exited 1 with an xmllint parser error while the
  answer sat in the cache. `mktemp` had failed, `tmp=$(mktemp)` swallowed it,
  and the empty path reached `cp "$cache_file" ""`, which BSD cp resolves to
  `./<basename>`: a stray `maven-metadata.xml` in the caller's working
  directory. `version`, `list versions`, `list dependencies`, `resolve`, and
  `search` now read the cache where it lies and need no writable filesystem;
  `source`/`inspect` still need somewhere to extract a JAR and now say so,
  naming `--output`.
- **A leaky assertion in this repo's own manifest** (`bf7c4f9f`).
  `pos-inspect-implementation` asserted /`TileService\.(kt|java)`/ meaning "read
  the real source". The arm that downloaded and read the published source failed
  it (a good answer quotes signatures, not filenames) while the arm that did not
  passed on a citation URL ending in `TileService.java` — the oracle scored the
  two arms backwards.
- **A trigger false positive** (`997d6efc`). `skill-trigger-matrix` (claude,
  sonnet+opus, 3 runs per query) fired the skill on "teach me the basics of
  composables and state hoisting" in 5 of 6 runs, because the description ended
  in a bare keyword list and "jetpack" matches any mention of Jetpack Compose.
  Rewriting it around the class of question cut that to 2 of 6 and moved the
  matrix 27/36 → 29/36.

Two things the harness did *not* catch, both oracle-side.
`pos-resolve-coordinate` scored `without_skill` 0.0 on an answer that was
correct: the model emitted a zero-width space inside the coordinate and the
regex missed it, so that case's outcome delta is spurious. And a `--workers 3`
trigger run had 29 of 36 invocations fail outright (exit 1,
`observation_complete: false`); the summary table scored those as trigger
failures rather than excluding them, reporting a catastrophic 0/18 regression
that was nothing but a failed run. Check `observation_complete` before believing
any trigger number.

Left deliberately undone: `--runs-per-variant` stayed at 1 for the benchmark
side, so the pass@k/pass^k reliability plumbing is still unexercised; the
holdout and holdback splits are still empty; and Sonnet's recall on
`trig-pos-coordinate-request` (1/3 before the description change, 0/3 after) is
a real gap that three runs cannot resolve either way.

## Make jetpack work offline with a pre-warmed cache (2026-07-27) — done

`scripts/jetpack` now has a single HTTP primitive (`http_get`) that every
network call goes through — `fetch_maven_metadata`, the source JAR and POM
downloads in `source`/`inspect` (including the KMP platform artifacts), and the
snapshot version metadata in `list dependencies`. It writes every successful
response through to `$CACHE_DIR/http/<host>/<path>`, mirroring the URL rather
than hashing it so the cache can be listed, seeded by a test fixture, and pruned
by hand. The cache is only *read* when offline, so adding it cannot change what
an online run answers: warming is a side effect of normal use rather than a new
staleness window. The GMaven index keeps its existing 24h TTL and its
`CACHE_DIR`/`INDEX_FILE` location, which the HTTP cache sits beside rather than
replacing.

`JETPACK_OFFLINE` (falling back to `AGENT_OFFLINE`) makes every subcommand skip
the network entirely. Cached answers are served at any age with that age on
stderr (`offline: using cached <url> (cached 3 days ago)`), so stdout stays
parseable and an agent has the caveat it needs. A miss names the exact URL and
the command that would have warmed it, and exits 1 — the `3a410bf` "report a
failure, don't guess" contract, extended to the offline case. When *not* offline
and the network fails, the behaviour is unchanged (still an error) except that
the message now names the cached copy and the switch that would use it, which is
the one thing an agent that just lost its network can act on alone.

The cold-environment question the original sketch left open is answered by none
of (a), (b) or (c) as written: write-through already covers it. Running a
command with network caches every resource that same command needs offline, so
the warm-up *is* the command, and a miss quotes the failing invocation back
(`run this where there is network to populate the cache: jetpack version androidx.wear.tiles:tiles ALPHA`)
— a more precise remedy than any generic warm command, because it cannot be
wrong about what was wanted. A `warm cache` subcommand was built first and then
removed: it could only ever guess which version, and with or without sources, a
later run would ask for, and each wrong guess is a miss the caller still hits.
(b), a snapshot checked into the repo, was rejected outright: the GMaven class
index is ~10MB compressed and changes daily. `jetpack doctor` is the other half
of the CI/sandbox story — read-only, reports dependencies, offline mode, cache
location and index age, and exits non-zero on any WARN/ERROR so a job can gate
on it before trusting an offline answer. It reports missing dependencies rather
than exiting 127 on the first one, and treats a missing index as INFO online
(self-healing) but ERROR offline.

Two guards exist because they destroy the only copy otherwise: `search --force`
refuses while offline (it deletes the index before rebuilding), and cache writes
are best-effort so an unwritable cache directory — a read-only sandbox — never
fails the command the user actually asked for.

`skills/jetpack/tests/test-jetpack-offline` covers all of this hermetically: 28
cases against a hand-seeded fixture cache with every request aimed at
`http://127.0.0.1:1/`, so a cached answer proves the cache was read and a "could
not reach" proves it was not, with no dependence on the machine's network. Fixed
along the way, found while exercising a pinned version: `list dependencies`
routed every version through `cmd_version`, which only accepts symbolic types,
so a pinned version (`list dependencies foo 1.6.1`) failed with "invalid version
type" and then built a POM URL out of an empty string.

## Normalize cache-directory and offline-mode conventions across skill scripts (2026-07-27) — done

The convention is written up in `skills/coding-standards/references/caching.md`,
referenced from `cli-tools.md` (interface), `shell.md` (the two bash traps:
guarding cache writes under `set -euo pipefail`, and distinguishing "no
response" from "an error response"), and the `coding-standards` SKILL.md. Cache
location is `${<TOOL>_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/<tool>}`, where
`<TOOL>_CACHE_DIR` names the tool's own directory rather than the base it sits
in, one root per tool.

The naming question is decided as both, not either: `<TOOL>_OFFLINE` wins when
set (including when set to `0`, to opt one tool out), otherwise the
workspace-wide `AGENT_OFFLINE` applies. That is not a compromise but the
existing two-tier rule in `workspace-config`'s SKILL.md — `AGENT_*` is policy a
human sets for an environment, `<TOOL>_*` is per-tool plumbing — and it matches
`UV_OFFLINE`, which the test suites already set. A caller who cannot enumerate
every command a build or agent session will invoke needs one switch for all of
them; a `--offline` flag alone cannot do that, so the variable is primary.

Audit of the five scripts that cache something:

- `jetpack` — `JETPACK_CACHE_DIR` + offline mode + `doctor` (see the item
  above).
- `skill` — `SKILL_CACHE_DIR` meant the *base*
  (`$SKILL_CACHE_DIR/skill/remotes`); now it names the cache directory itself,
  via a new `get_cache_dir()` that both `get_cache_base()` and
  `get_catalog_dir()` derive from. Gained `SKILL_OFFLINE` /`AGENT_OFFLINE`:
  `fetch_github` serves a previously downloaded remote skill at any age
  (ignoring `--force`, which cannot be honoured without network) and reports how
  old it is, or dies naming `skill add <name>` if it was never fetched; catalog
  metadata degrades quietly since it is only descriptions. This matters most for
  `preflight`, which gates agent launch and should not depend on GitHub being
  reachable.
- `context` — gained `CONTEXT_CACHE_DIR` and `CONTEXT_OFFLINE`/`AGENT_OFFLINE`.
  Only URL targets are gated; local directories and entries are built from the
  machine itself and are left alone. Two cases added to `test-context`.
- `photo-query` — cached under `agent-tools/photo-query`, the only script
  grouping by skill rather than by tool; moved to `photo-query` with a
  `PHOTO_QUERY_CACHE_DIR` override. No offline mode, recorded in its docstring:
  the cache holds locally derived thumbnails, not fetched data, and the Gemini
  call the tool exists to make cannot be served from it. The old directory's
  contents are regenerated on demand.
- `oracle` — `ORACLE_CACHE_DIR` added for symmetry, no offline mode, reason
  recorded inline: `~/.cache/oracle` is a transcript of past consultations, not
  a response cache. Every run is a fresh model call against a new prompt, so
  there is nothing there to serve a later run from.

`tests/README.md` documents `AGENT_OFFLINE=1` alongside `UV_OFFLINE=1` (the two
cover different layers: dependency resolution vs. the scripts' own calls) and
points at `test-jetpack-offline` as the pattern for tests that need a specific
cache state.

## Enable more of ruff's default rule set (2026-07-26) — done

Confirmed real access to ruff 0.16.0 (`uvx ruff@0.16.0`; PyPI's actual latest,
not just a locally cached `uvx ruff` resolving to 0.15.8) before starting.
Pinned the version too, not just the selection: `RUFF_SELECT`/`RUFF_IGNORE` in
`skills/coding-standards/scripts/python-format` now pair with a `RUFF_VERSION`
that both `RUFF_CHECK`/`RUFF_FORMAT` invoke via `uvx ruff@"$RUFF_VERSION"`, so a
future ruff release changing defaults or rule behavior can't cause the same
silent drift this item was filed to fix — bumping the version is now a
deliberate, reviewed edit like extending the selection.

Determined the true 0.16 default set per-repo via
`ruff check --isolated --show-settings` rather than trusting family-name sizing,
then adopted it selectively: most new families (`UP`, `RUF`, `FURB`, `PIE`,
`DTZ`, `I`, plus several zero-violation families like `EXE`/`PYI`/`YTT`) are
selected as whole families since blanket selection matched or nearly matched
their actual 0.16 default subset here. A second group (`SIM`, `TRY`, `PERF`,
`PLC`, `PLW`) is selected as whole families with a short `RUFF_IGNORE` carving
out the few codes that don't earn their keep. A third group (`PLR`, `T`, `S`,
`RET`, `D`, `PTH`) is narrowed to specific codes because their 0.16 default
subset itself (not just the full family) mixes good rules with ones unsuited to
this repo.

`BLE001` and `S110` (blind/broad exception handling) turned out to be the noisy
tail predicted by the original sizing — not the `PLR` complexity rules ruff's
actual 0.16 defaults already exclude those. Both hit the documented top-level
CLI error/signal boundary pattern in `coding-standards/references/python.md`
almost exclusively (113 and 27 hits) and are excluded with that rationale
recorded inline, rather than added as noqa-per-site. Every other family/code
left out gets its own one-line reason in the comment above `RUFF_SELECT`, per
the criteria.

Net: 96 real violations surfaced across the 15 Python entrypoints; 44 fixed by
`--fix`, 30 more (reviewed diff-by-diff, all correct) via `--unsafe-fixes`, and
22 by hand — mostly `subprocess.run(..., check=False)` made explicit,
`datetime.now()` made tz-aware via `.astimezone()`, nested `if`s merged
(`SIM102`), a `TypeError` swapped in for a type-check `ValueError` (`TRY004`),
and two ad hoc `set` class attributes converted to `frozenset` (`RUF012`).
`python-format --check` is clean on all 15 entrypoints, all pre-existing tests
for the touched scripts still pass.

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
(…)" (or "cannot resolve the declared skill set (…)" when only declaration-side
defects exist), findings render as one aligned per-item list
(`emumanager   disk only (linked in .claude/skills, not in AGENT_REQUIRED_SKILLS)`),
and remediation is phrased as sync directions with concrete effects: "Make disk
match env (link X; delete the Y symlink): skill apply" versus "Make env match
disk (declare Y; keep the symlink): envrc add skills Y && direnv reload" (raw
`export` variant without `.envrc`). Every suggested `envrc` command carries the
`direnv reload` step, since the environment stays stale until then. A per-skill
mixing hint prints only when there are two or more differences. The
blocked-prune note is self-contained (preflight suppresses the freshness WARNING
it used to reference) and names the by-hand `skill remove` fallback; when stale,
`envrc add` is not suggested for names `.envrc` already declares. Negated
(excluded) skills are still never suggested for re-declaration, and the verbose
success banner lost its `✔` glyph per the doctor output style. Tests
41/42/45/62/65 and 79–81 updated in `skills/workspace-config/tests/test-skill`;
the doctor example in `skills/coding-standards/references/cli-tools.md` follows
the new summary.

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
make these self-referential (as `tests/test-git-hook-multiplexer` already is)
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
allowance is for them, and `git-hook-multiplexer`, `skill`, `jetpack`, etc.
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

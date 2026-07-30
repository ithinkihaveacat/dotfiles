# jetpack evals

Measurements of whether the `jetpack` skill actually helps, and whether it loads
when it should. Run with
[skill-eval-harness](https://github.com/adewale/skill-eval-harness).

> **Temporary:** run the harness from the
> [`agy-adapter` branch of this fork](https://github.com/ithinkihaveacat/skill-eval-harness/tree/agy-adapter),
> not from upstream. It carries the Google Antigravity backend these evals use,
> which is not yet released upstream. Once it lands, use upstream and delete
> this note. The commands below use `uvx` to create a cached, isolated
> environment; they do not install executables into your `PATH`.

## What is here

| Path                                 | What it is                                                                                                 |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------- |
| `shared-benchmark.json`              | The manifest: 13 tune cases (7 `library-lookup`, 6 `trigger`) plus 2 declared ablations                    |
| `oracles/answer-names-added-symbols` | A grade-time oracle that recomputes a real source diff and checks the answer names every added declaration |

Two different tools read this one manifest, and they do not overlap:

- **`skill-benchmark`** runs the 7 `library-lookup` cases. Each is graded on two
  channels — a *process* assertion (did the model run `scripts/jetpack`?) and an
  *outcome* assertion (is the answer right?). Every case runs twice, once
  `with_skill` and once `without_skill`, and the score is the paired lift.
- **`skill-trigger-matrix`** runs the 6 `trigger` cases. These have no
  assertions: the tool mounts the skill where an agent discovers skills on its
  own, asks a raw question, and measures whether the skill loaded. Three are
  positive (should fire), three negative (should not).

`skill-benchmark prepare` silently emits only the `pos-*` rows. If you expect 13
tasks and get 7, nothing is broken.

## Running the answer cases

```bash
cd ~/.dotfiles

# Set this once in the shell that runs the evals.
HARNESS='git+https://github.com/ithinkihaveacat/skill-eval-harness@agy-adapter'

uvx --from "$HARNESS" skill-benchmark prepare skills/jetpack/evals/shared-benchmark.json \
  --split tune --runs-per-variant 1 --out /tmp/tasks.jsonl

# Codex. The sandbox override is required — see Gotchas.
uvx --from "$HARNESS" skill-benchmark run-codex --tasks /tmp/tasks.jsonl --runs /tmp/runs --timeout 600 \
  --codex-cmd "codex exec --json --sandbox workspace-write -c sandbox_workspace_write.network_access=true"

# Or any registered native backend: claude, codex, vibe, agy
uvx --from "$HARNESS" skill-benchmark run-agent --agent agy --model gemini-3.1-pro-high \
  --tasks /tmp/tasks.jsonl --runs /tmp/runs --timeout 600

uvx --from "$HARNESS" skill-benchmark benchmark skills/jetpack/evals/shared-benchmark.json \
  --runs /tmp/runs --split tune --allow-scripts --out /tmp/benchmark.json
```

Read the result with:

```bash
jq -r '.results[] | [.case_id, .variant, (.objective_pass_rate|tostring)] | @tsv' /tmp/benchmark.json
jq '.summary.with_skill.mean_objective_pass_rate, .paired_summary' /tmp/benchmark.json
```

## Running the trigger cases

```bash
uvx --from "$HARNESS" skill-trigger-matrix skills/jetpack/evals/shared-benchmark.json --split tune \
  --agent claude --model sonnet --model opus \
  --runs-per-query 3 --workers 1 --out /tmp/trigger.json
```

`--agent stub` runs the whole pipeline offline with no model, which is enough to
check that the manifest and mounting work before spending tokens.

## Gotchas

Every one of these cost real time to find.

- **Check `observation_complete` before believing any trigger number.** A failed
  invocation is scored as "did not trigger", not excluded, so a broken run is
  indistinguishable from a real activation collapse in the summary table. A
  `--workers 3` run here had 29 of 36 invocations fail and reported a
  catastrophic 0/18 that was pure noise. Use `--workers 1` and verify:

  ```bash
  jq '[.results[] | select(.observation_complete == false)] | length' /tmp/trigger.json
  ```

- **`run-codex` needs the sandbox override** for any case that writes or
  fetches. It inherits `codex exec`'s read-only default, which blocks `mktemp`
  and the network, so `source`/`inspect` cases fail in a way that looks like a
  jetpack bug. (`CodexBackend` hardcodes `sandbox="read-only"` upstream.)

- **`--allow-scripts` is required** or the `script` assertion on
  `pos-version-diff` fails closed with "script assertion skipped". It is opt-in
  because script assertions execute repo-owned commands.

- **The oracle needs network or a warm cache.** It downloads two versions of an
  artifact to recompute the diff. Warming beforehand makes grading fast and
  offline-safe:

  ```bash
  skills/jetpack/scripts/jetpack source androidx.compose.remote:remote-tooling-preview 1.0.0-alpha08 --output /tmp/warm08
  skills/jetpack/scripts/jetpack source androidx.compose.remote:remote-tooling-preview 1.0.0-alpha09 --output /tmp/warm09
  ```

- **Assertions are shape checks unless stated otherwise.** `returns-a-version`
  is `\b\d+\.\d+\.\d+\b` — a confidently stale answer passes exactly as well as
  a correct one. Only `pos-version-diff` holds an answer against live ground
  truth. Do not read a high outcome score as "the answer was right".

- **The mounted skill directory is named `SKILL.md`.** The manifest declares
  `skill_paths: ["SKILL.md"]` and the harness names the mounted root after that
  entry, so trigger runs mount to `.agents/skills/SKILL.md/`. Cosmetic —
  detection uses the frontmatter `name:` — but confusing in a trace.

- **`--agent agy` needs the forked harness** linked at the top. The other
  backends (`claude`, `codex`, `vibe`) work against upstream 0.6.0.

## Versions this was last run against

| Tool               | Version                                     |
| ------------------ | ------------------------------------------- |
| skill-eval-harness | 0.6.0 (`uvx --from "$HARNESS" …`)           |
| uv                 | 0.11.33                                     |
| codex-cli          | 0.145.0                                     |
| agy (Antigravity)  | 1.1.8 — `stream-json` output needs >= 1.1.8 |
| Claude Code        | 2.1.220                                     |

If `uv` refuses to install the harness's own `[test]` extra, it is the
`UV_EXCLUDE_NEWER` cutoff, not a broken dependency: a pinned tool version
published after the cutoff is filtered out. `UV_EXCLUDE_NEWER="1 day"` gets past
it.

## Last run: 2026-07-29

One run per variant. `pos-version-diff` was added partway through, so Codex's
aggregate covers the 6 cases that predate it and that case was run separately;
Antigravity's covers all 7.

| Runner                              | Cases | with_skill | without_skill | Notes                                       |
| ----------------------------------- | ----: | ---------: | ------------: | ------------------------------------------- |
| Codex (CLI default model)           |     6 |       1.00 |          0.42 | Δ +0.58, sign-flip p = 0.031, no case flags |
| Antigravity (`gemini-3.1-pro-high`) |     7 |       1.00 |          0.43 | Δ +0.57, p = 0.016, no case flags           |

One run per variant is enough to see a lift this size but not to settle per-case
differences; raise `--runs-per-variant` before reading anything finer.

Two findings worth carrying forward:

**The lift is process, not capability.** With the network open, the
`without_skill` arm answers most of these correctly by curling
`developer.android.com` by hand. The outcome assertions are base-saturated; only
the `command_ran` assertions discriminate. Checked after the fact against live
resolution — the baseline was genuinely correct every time.

**Except on `pos-version-diff`, and there the runners disagree.** That case asks
what changed between two alpha versions of an obscure artifact; the answer is
one `@RestrictTo` class and cannot be recalled.

| Runner      | with_skill | without_skill | How the baseline behaved                                       |
| ----------- | ---------: | ------------: | -------------------------------------------------------------- |
| Codex       |       1.00 |          0.50 | Hand-rolled `curl`+`unzip`+`diff`; right answer, 2× the tokens |
| Antigravity |       1.00 |      **0.00** | Ran **zero commands** and fabricated the answer                |

Antigravity's baseline had egress (verified: the same `curl` returns `200` under
the eval's own flags), so not looking was a choice. Same question, two agents,
two different failure modes — the skill shows up as *cost* against a diligent
agent and as *correctness* against one that guesses. Do not generalise a
token-efficiency conclusion from a single runner.

Trigger matrix, Claude sonnet + opus, 3 runs per query: 29/36 overall. Opus is
9/9 on positives; the residual failure is a false positive on generic "teach me
Jetpack Compose" questions.

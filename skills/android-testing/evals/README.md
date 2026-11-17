# android-testing evals

Measurements of whether the `android-testing` skill improves diagnostic accuracy
on non-obvious Wear OS and paired-device testing failure modes, and whether the
skill loads only when appropriate. Run with
[skill-eval-harness](https://github.com/adewale/skill-eval-harness).

> [!NOTE] **Temporary:** run the harness from the
> [`agy-adapter` branch of this fork](https://github.com/ithinkihaveacat/skill-eval-harness/tree/agy-adapter)
> when using `--agent agy`. The other backends (`claude`, `codex`, `vibe`,
> `stub`) work against upstream `>= 0.6.0`.

## What is here

| Path                             | What it is                                                                                          |
| -------------------------------- | --------------------------------------------------------------------------------------------------- |
| `shared-benchmark.json`          | The manifest: 11 tune cases (5 `wear-diagnostics`, 6 `trigger`) plus 5 declared component ablations |
| `oracles/answer-wear-diagnostic` | A grade-time oracle validating diagnostic accuracy and rejecting known baseline hallucinations      |

Two harness tools consume `shared-benchmark.json`:

- **`skill-benchmark`** runs the 5 `wear-diagnostics` cases across `with_skill`
  and `without_skill`, scoring paired outcome lift with both regex checks and
  `oracles/answer-wear-diagnostic`.
- **`skill-trigger-matrix`** runs the 6 `trigger` cases (3 positive, 3 negative
  false-friends) to verify autonomous skill activation without over-triggering
  on generic JVM JUnit, backend WebSocket, or consumer shopping prompts.

## Tune and holdout status

Every case in `shared-benchmark.json` is a visible `tune` case selected from
unprimed `without_skill` baseline probes where frontier models (`gemini-pro`,
`gemini-flash`, and `gemini-flash-lite`) failed or hallucinated OS mechanisms.
Candidate topics that baseline models already answered accurately without the
skill (`adb logcat -b events`, `strings` on native `.so` binaries, `LruCache`
`sizeOf()` for `Bitmap`s, and Compose `TextUnit` smali parameter ambiguity) were
excluded prior to authoring.

## Running the answer cases

```bash
cd ~/.dotfiles

HARNESS='git+https://github.com/ithinkihaveacat/skill-eval-harness@agy-adapter'

uvx --exclude-newer false --from "$HARNESS" skill-benchmark prepare \
  skills/android-testing/evals/shared-benchmark.json \
  --split tune --runs-per-variant 2 --out /tmp/android-testing-tasks.jsonl

uvx --exclude-newer false --from "$HARNESS" skill-benchmark run-agent \
  --agent agy --model gemini-3.1-pro-high \
  --tasks /tmp/android-testing-tasks.jsonl --runs /tmp/android-testing-runs --timeout 600

uvx --exclude-newer false --from "$HARNESS" skill-benchmark benchmark \
  skills/android-testing/evals/shared-benchmark.json \
  --runs /tmp/android-testing-runs --split tune --allow-scripts \
  --out /tmp/android-testing-benchmark.json
```

> [!TIP] **Behind proxies that strip PyPI upload timestamps:** if `uvx` fails
> dependency resolution due to `UV_EXCLUDE_NEWER`, pass `--exclude-newer false`
> to `uvx` (as shown above) so wheels missing upload-date metadata are not
> filtered out. Remember `--allow-scripts` on `benchmark` so
> `oracles/answer-wear-diagnostic` runs instead of failing closed.

## Running the trigger cases

```bash
uvx --exclude-newer false --from "$HARNESS" skill-trigger-matrix \
  skills/android-testing/evals/shared-benchmark.json --split tune \
  --agent claude --model sonnet \
  --runs-per-query 3 --workers 1 --out /tmp/android-testing-trigger.json
```

Pass `--agent stub` to verify manifest parsing and skill mounting offline before
spending model quota.

## Last run: 2026-11-16

Two runs per variant (`10` runs per arm) on `gemini-pro-latest`
(`gemini-3.1-pro-preview`, `thinkingLevel: "high"`, `maxOutputTokens: 8192`):

| Case                                             | `without_skill` |     `with_skill` | Baseline failure mode                                                                            |
| ------------------------------------------------ | --------------: | ---------------: | ------------------------------------------------------------------------------------------------ |
| `pos-wear-5s-socket-cutoff`                      |             0/2 |              2/2 | Blamed 10s+ cached-app freezer, missed `InetDiagMessage` (`0/2`)                                 |
| `pos-adb-run-as-unfreeze-observer-effect`        |             0/2 |              2/2 | Spun to `MAX_TOKENS` (`7.8k` thought tokens) without naming `am_unfreeze`                        |
| `pos-standalone-fcm-hipri-and-gtalk-diagnostics` |             0/2 |              2/2 | Missed watch-wide `HiPri` scope (`0/2`); 1/2 spun to `MAX_TOKENS` on `GcmDiagnostics`            |
| `pos-bridging-manager-auth-and-dismissal-sync`   |             1/2 |              2/2 | 1/2 omitted `WearableExtender.setDismissalId`, breaking dismissal sync once bridging is disabled |
| `pos-companion-cold-start-locked-qa`             |             0/2 |              2/2 | Caught BAL (`2/2`) but missed `WindowManager$BadTokenException` from `Dialog.show()` (`0/2`)     |
| **Total**                                        | **1/10 (0.10)** | **10/10 (1.00)** | **Δ +0.90**, median thinking tokens cut ~5× (`~4,400` → `~870` tokens/run)                       |

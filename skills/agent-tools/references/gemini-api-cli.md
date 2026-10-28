# Gemini API CLI

Notes on `gemini-api`, the beta CLI the `emerson`, `pascal` and `satisfies`
wrappers now run on. Pinned version: **v0.4.4** (see
[SKILL.md](../SKILL.md#gemini-api-cli) for installation).

The migration is a prototype: this file records what we found, what we depend
on, and what is worth telling the CLI's authors.

## The contract we rely on

| Surface       | What we assume                                                                                    | Guarded by                                          |
| ------------- | ------------------------------------------------------------------------------------------------- | --------------------------------------------------- |
| Command       | `gemini-api generate PROMPT --model M --stream=false --output-format json --body JSON`            | `test-gemini-cli-contract`                          |
| Flags         | `--model`, `--system`, `--body`, `--stdin`, `--stream`, `--output-format`, `--jq`                 | `test-gemini-cli-contract`                          |
| Request body  | `input`, `model`, `system_instruction`, `generation_config`, `response_format`, `store`, `stream` | `test-gemini-text`                                  |
| Text location | `.steps[] \| select(.type=="model_output") \| .content[] \| select(.type=="text") \| .text`       | `test-gemini-text`, `test-gemini-api-live`          |
| Storage       | `generate` keeps the interaction unless `store: false` is sent                                    | `test-gemini-cli-contract`, `test-gemini-api-live`  |
| Exit codes    | 0 ok, 1 runtime/API, 2 usage, 3 authentication                                                    | `test-gemini-cli-contract`, `test-gemini-transport` |
| Stdout        | With `--output-format json` and `--stream=false`, one JSON document and nothing else              | `test-gemini-cli-contract`                          |

Everything the wrappers share lives in `libexec/gemini-text`: it forces
`store: false`, extracts the text, warns on a non-`completed` interaction, and
maps CLI failures to exit 1.

## Friction found while migrating

1. **The answer is not where the documentation suggests.** The README and the
   repository's own contract fixtures show `outputs: [{type: "text", ...}]`; the
   live service returns `steps: [{type: "model_output", content: [...]}]`. A
   tool written against the documented shape gets `null` from
   `--jq '.outputs[0].text'` and **exits 0**, so a boolean wrapper reports
   "false" instead of failing. This is the single most dangerous difference for
   script authors.

1. **`store` defaults to keeping the interaction, and the default is
   inconsistent.** `generate` sends no `store` field, so the service retains the
   prompt and response; `analyze` hard-codes `store: false`. Migrating a script
   from `generateContent` (which stores nothing) silently starts filing
   documents server-side. We force `store: false` in the helper.

1. **Unknown keys are rejected at the top level but dropped when nested.**
   `{"generationConfig": ...}` is refused with
   `did you mean "generation_config"`, which is excellent. But
   `{"generation_config": {"response_format": ...}}` is accepted and sent as
   `"generation_config": {}` with no warning, silently discarding the
   structured-output request. The nested case is the realistic mistake when
   porting from `generateContent`.

1. **`--server-url` has no environment variable or config key.** It is the only
   way to point the CLI at a test double, and it cannot be set globally, so our
   contract test needs a `gemini-api` shim on `PATH` that appends the flag. A
   `GEMINI_SERVER_URL` (like `GEMINI_API_VERSION`) would make hermetic tests
   trivial.

1. **No token counting.** There is no `countTokens` equivalent, so `token-count`
   cannot move to the CLI and stays on `generateContent`.
   `gemini-api models get` does not report token counts either.

1. **Two JSON contracts under one flag.** `analyze --output-format json` prints
   `{inputs, mime_types, model, question, text, usage}`;
   `generate --output-format json --stream=false` prints the raw interaction.
   Neither is documented next to the other, and a wrapper that handles one
   breaks on the other.

1. **`generate --stream=false` prints a metadata table, not the answer** (`id`,
   `model`, `status`, `steps`). Only `--jq` or `-o json` expose the text;
   `analyze` prints the answer directly. For a text-generation command the
   default is surprising, and an agent that forgets the flag gets no answer.

1. **No retry on 429.** The bundled SDK has a retry configuration, but a rate
   limited `POST /interactions` produced one request and an immediate
   `rate_limit_error`. Our scripts never retried either, so this is not a
   regression - but a CLI that looks like it should retry does not.

1. **No input preprocessing.** `analyze -i photo.jpg` inlines the original bytes
   (20 MB request budget, no resize, no re-encode). The skill's `photo-query`
   deliberately caps images at 384 px; the same small JPEG cost 1,072 prompt
   tokens through `analyze`. That is why the photo and screenshot tools were
   left alone.

1. **`--body` and `--stdin` both want stdin** when the body is JSON and the
   prompt is piped. `--body @file` works around it; the interaction is not
   documented.

1. **Exit codes collide with boolean conventions.** 1 means "runtime failure",
   so a tool that returns an answer via exit status must reserve 2 for errors
   (which is what `satisfies` now does). A distinct code for "the model produced
   no text" would help.

1. **Beta with no upgrade path.** Releases are GitHub tarballs, breaking changes
   are explicitly expected, and pull requests are not accepted. The only defence
   is pinning plus the contract tests in this directory.

## Recommendations to pass upstream

Ordered by how much they would have saved us. File these as issues against
`google-gemini/gemini-api-cli`.

1. **Document the response shape, or add an `output_text` convenience field.**
   Show a real `generate --stream=false` response (with `steps[]`) in the
   README, and make the docs' `outputs[]` examples match what the service
   returns. A `--jq .output_text`-style shortcut would let scripts avoid the
   expression entirely.
1. **State the storage default prominently, and align the commands.** Document
   that `generate` retains interactions unless `store: false`; consider making
   the CLI default `store: false` for one-shot commands (as `analyze` does), or
   add `--store=false` as a first-class flag. Script authors migrating from
   `generateContent` will not think to look.
1. **Warn on dropped nested keys.** Top-level validation already suggests
   `generation_config`; extend it inside known objects (`generation_config`,
   `response_format`) so a legacy `responseContentType`-style key cannot vanish.
1. **Add `GEMINI_SERVER_URL` (env + config).** It turns `--server-url` from a
   test-only flag into something fixtures and CI can set once.
1. **Add token counting.** `gemini-api count-tokens --stdin` (or
   `generate --count-tokens`) would let the last curl-based text tool migrate.
1. **Unify `--output-format json`.** Either make `analyze` return the raw
   interaction, or document both envelopes side by side with a `--raw` switch.
1. **Make `--stream=false` print the answer.** Or add `--print text`; a text
   command that prints a metadata table by default surprises both humans and
   agents.
1. **Retry 429/5xx by default, or document that it does not.** The SDK
   scaffolding already exists; a documented policy would end the guessing.
1. **Expose image downscaling** (`--max-image-size`, or a per-request input
   token budget). It is the difference between a cheap classification and an
   expensive one for any tool that runs over a photo library.
1. **Publish install artefacts** (Homebrew tap, apt/deb) and a short stability
   note per release ("flags changed since v0.4.x"). Tarballs plus "breaking
   changes may occur" is workable only with a pinned CI matrix.

## What was deliberately not migrated

- `token-count`: no `countTokens` command (friction 5).
- `photo-query`, `photo-smart-crop`, `screenshot-describe`,
  `screenshot-compare`: resize, alpha flattening, caching and local cropping are
  the value; the CLI has none (friction 9).
- `pacioli`: Python with `urllib`, one function, and a careful error taxonomy;
  it has none of the duplicated curl block the migration removes.
- `oracle`, `caxton`, `popper`, `socrates`: agent loops with tool calls, state
  and policy. They are not transport wrappers.
- `bin/uihierarchy-describe`, `bin/uihierarchy-compare`: same shape as the
  migrated scripts, but they live outside the skill and would need the skill's
  `libexec` on `PATH`. A separate decision.

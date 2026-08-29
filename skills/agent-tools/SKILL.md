---
name: agent-tools
description: >-
  Command-line AI tools and context gatherers for image analysis, screenshot diffing,
  smart cropping, token counting, technical essays (emerson), boolean condition evaluation,
  Android UI automation (popper), receipt extraction (pacioli), GitHub data formatting
  (gh-markdown), deep reasoning research (Oracle), and whole-tree text refactoring
  (Caxton).
  Use when analyzing images, comparing screenshots, evaluating conditions, extracting
  receipts, gathering domain context, automating Android apps, refactoring multi-file
  repositories with Caxton, or performing deep research with Oracle.
compatibility: >-
  Requires curl, jq, and uv. Image tools also need base64 and magick (ImageMagick).
  Needs a Gemini API key (GEMINI_API_KEY) and network access to generativelanguage.googleapis.com.
---

# Agent Tools

## Using Helper Scripts vs. Raw API Calls

Use the scripts in `scripts/` as the primary interface for AI-delegated analysis
and context gathering. References to `scripts/...` in this skill are relative to
this skill directory. They encapsulate API boilerplate and formatting logic:

- Proper image encoding (WebP conversion, alpha removal)
- Task-tuned default model selection
- Structured output handling (e.g. boolean responses mapped to shell exit codes)
- Formatting structured data (like GitHub PRs and issues) into LLM-friendly
  Markdown

**When to inspect script source:** If a script lacks a specific parameter or
fails due to a local dependency, inspect the script in `scripts/`. They
demonstrate correct API schemas, request structures, and retry behaviors that
you can adapt for custom calls.

## Quick Start

**Environment:** AI commands require a Gemini API key (reads from
`GEMINI_API_KEY`). Scripts will report clear errors if no key is found.
`gh-markdown` optionally accepts a `--token` for GitHub API access.

**Model selection:** Every Gemini-backed script accepts `--model MODEL` and
honors the `GEMINI_MODEL` environment variable (`--model` wins; each script's
built-in default applies when neither is set). Defaults vary per tool and are
tuned for its task; only override when you have a reason.

**Dependencies:** `curl`, `jq`, `uv` (all tools); `base64`, `magick` (image
tools only)

```bash
# Gather context and analyze
scripts/context show gemini-api | scripts/emerson "Explain the key features"

# Transform an entire directory of documents or code
scripts/caxton "Translate the guides into French" --edit docs/

# Fetch a GitHub PR, Issue, or Workflow Run as Markdown
scripts/gh-markdown https://github.com/owner/repo/pull/123

# Describe an image (generate alt-text)
scripts/screenshot-describe screenshot.png

# Compare two images for visual differences
scripts/screenshot-compare before.png after.png

# Smart crop image around the detected primary subject
scripts/photo-smart-crop photo.jpg cropped.jpg

# Check if a photo prominently features people (exit code = answer)
scripts/photo-query @people photo.jpg

# Generic image query with a JSON schema
scripts/photo-query "Is there a fireplace?" \
  --schema "has_fireplace bool" photo.jpg

# Generate essay-length analysis from text
scripts/emerson "Summarize the key changes" < documentation.md

# Evaluate a boolean condition against text
echo "Hello world" | scripts/satisfies "is a greeting"

# Extract a structured purchase record from a receipt email
scripts/pacioli < order.eml

# Count tokens in text
cat document.md | scripts/token-count

# Interact with an Android UI via AI
scripts/popper "start an exercise"
```

## Script Overview

### oracle

Consult the Oracle for a very carefully researched and considered answer. The
Oracle utilizes deep reasoning and Google Search grounding to provide the
highest quality response possible. It accepts arbitrary files and directories as
positional arguments, recursively walks directories, and automatically uploads
media files. Use this tool for deep research, complex architectural reasoning,
and synthesis requiring external data or massive repository context.

**Important Usage Guidelines:**

1. **Not for Quick Q&A:** The Oracle is designed for deep, context-heavy
   reasoning. It takes longer to run and consumes more tokens than standard
   tools. Do not use it for simple questions or basic syntax lookups.
1. **Stateless — One-Shot Consultations:** Every invocation is independent. The
   Oracle retains nothing between calls — including your own earlier Oracle
   calls in the same session. Never write "as you suggested earlier" or refer to
   a previous consultation; the Oracle has never seen it. To follow up, attach
   the previous answer as a context file (answers are saved automatically to
   `~/.local/state/oracle/answer_*.md`; the path is printed after each run)
   along with your new question and any critique.
1. **Self-Contained Prompts:** Write the prompt as if explaining the problem to
   an expert who has zero prior knowledge of your task. Do not use references
   like "the solution we implemented" without explaining exactly what that
   solution was. Prompts of several hundred words are normal; a one-line prompt
   is almost always a mistake.
1. **Broad File Context:** Include source files and directories as positional
   arguments because the Oracle needs the broadest possible view of the codebase
   to reason effectively. Err on the side of providing too much
   context—including files, directories, or documentation even if you think they
   are only marginally relevant—so the Oracle can discover non-obvious
   connections. The model on the other side handles very large context, and what
   you send is all it has: a well-fed consultation is typically tens to hundreds
   of KB. If your payload is under ~50 KB you have probably under-provided —
   prefer whole directories to hand-picked excerpts. The 1 MB ceiling is a
   guardrail, not a target.
1. **Write a Session Brief:** Much of what the Oracle needs is not in any file —
   requirements, decisions, constraints, and history from your conversation.
   Write them into a notes file (e.g. in your scratchpad directory) and pass it
   as context alongside the source files; do not rely on the prompt alone to
   carry them.
1. **Define the Meta-Context:** Beyond raw files (code, PDFs, logs), the most
   effective Oracle queries explicitly define the "meta-context" in the prompt.
   Before calling the tool, package up your intent. Define the **persona**, the
   ultimate **goals**, the **success criteria**, **constraints**, desired
   **format/style**, and provide **examples** or **assumptions**. A large,
   detailed prompt is expected.
1. **Describe What Didn't Work:** If you are calling the Oracle because you or
   an agent is stuck—e.g., many approaches have been tried but have failed or
   been rejected—explicitly summarise those failed attempts in the prompt.
   Describe each approach, why it failed or was ruled out, and any error
   messages or constraints encountered. This prevents the Oracle from
   re-proposing the same dead ends and directs its reasoning toward genuinely
   novel solutions.
1. **Planning Step:** The Oracle tool processes massive, expensive context
   payloads. Before executing a live Oracle request, formulate your prompt and
   target directories, and run the tool using the `--dry-run` flag:
   `scripts/oracle --dry-run "PROMPT" [FILE_OR_DIR ...]` First check the summary
   yourself against the size guidance above — if the payload is thin, go back
   and gather more context before involving anyone. Then present the dry-run
   summary (the total payload size, the list of resolved files, and your drafted
   prompt) to the user in the chat and ask whether to add more directories,
   exclude files, or tweak the prompt — unless the user has already specified
   the context and approved the run, in which case proceed directly with the
   live command (without `--dry-run`).

**Warning:** Output can be detailed and lengthy.

```bash
scripts/oracle [OPTIONS] "PROMPT" [FILE_OR_DIR ...]
```

**Options:**

- `--force`: Bypass context size limits (1MB for text, 20MB per media file). Use
  when you are confident the large context is necessary and the model can handle
  it.
- `--maps`: Use Google Maps grounding instead of Google Search. Use this for
  queries about locations, places, or general routing options. **Warning:**
  Specific details like live star ratings, current operating hours, or recent
  business closures may still be inaccurate or outdated and should be verified.
  Note: Cannot be combined with `--code`.
- `--code`: Enable Code Execution for Python. Use this whenever the task
  requires precise calculations, complex mathematics, data analysis on provided
  files, or programmatic logic. The model will write and execute Python code in
  a sandboxed environment.

**Environment:** `GEMINI_API_KEY` (Required)

**Exit codes:** 0 success, 1 error

**Examples:**

```bash
# Evaluate an architectural pattern
scripts/oracle "Evaluate this implementation against solid principles and propose a refactoring plan." src/

# Time-sensitive research based on context
scripts/oracle "What are the latest developments in this framework as of May 2026?" framework-docs.md
```

### caxton

Autonomous long-form text transformation, documentation audit, and harmonization
engine, scoped to the paths you name. Specialized for large-scale text reasoning
across whole repositories: auditing documentation drift, resolving cross-file
contradictions, standardizing style, and synchronizing documentation against
codebases. Combines Oracle's broad upfront bulk context inlining (up to 1 MB)
with Popper's autonomous tool-calling loop. It inlines the selected files into
the initial prompt and provides the model with exact byte-for-byte
`search_and_replace`, `write_file`, `delete_file`, `read_file`, and `list_files`
tools to execute changes across multiple documents before finalizing via
`complete_task`.

Unlike iterative coding tools that operate in tight compile/test loops, Caxton
is tailored for narrative text, specifications, and documentation corpuses where
giving the model a comprehensive global overview of multiple files prevents
documentation drift. Source code may be provided as read-only reference
(`--read`) to verify documentation accuracy, but mutations (`--edit`) target
prose, guides, and specifications.

```bash
scripts/caxton "PROMPT" [OPTIONS]
```

Each path is either **visible** (`--read`), **visible and writable** (`--edit`),
or invisible. Invisible means invisible: absent from the file listing and
refused by the read tool, not merely left out of the initial prompt. A third,
independent property — whether a visible file's contents are inlined into the
initial prompt — is controlled by `--inline`/`--no-inline`.

**Options:**

- `--read PATH...`: Make paths visible to the model (default: `.`).
- `--edit PATH...`: Make paths visible and writable. Any `--edit` makes this a
  mutation run and requires a clean git worktree. `--edit DIR` also permits
  creating and deleting files beneath `DIR`, except where a more specific
  `--read` carves part of it out; `--edit FILE` does not authorize creating
  siblings.
- `--read-from FILE` / `--edit-from FILE`: Read further paths from `FILE`, or
  `-` for standard input.
- `-0, --null`: Path list files are NUL-delimited rather than one path per line.
- `--inline PATH...`: Inline only these paths (default: every visible text
  file). Must be a subset of what is already visible — `--inline` narrows the
  initial context and can never widen access.
- `--no-inline`: Inline nothing; the agent reads files on demand.
- `-n, --dry-run`: Print the resolved policy and payload and exit without
  calling the API.
- `--force`: Bypass safety checks — the 1MB inlined-text threshold, the
  dirty-worktree guard, and the refusal to write paths git cannot restore.
- `--model MODEL`: Gemini model to use (default: `gemini-pro-latest`).
- `--thinking LEVEL`: Thinking level: `high`, `low`, `none` (default: `high`).
- `--search` / `--no-search`: Google Search grounding for live external context
  (default: on).
- `--code` / `--no-code`: Python code execution in cloud sandbox (default: on).
- `--serialize` / `--no-serialize`: Save request payload and final response to
  the state directory (`~/.local/state/caxton/`) (default: on).
- `--max-steps N`: Maximum agent tool steps before stopping (default: 100).
- `--timeout SECONDS`: Execution timeout in seconds (default: 1800).

`PROMPT` is the only positional argument and must come before the path options,
which each consume every following path.

**Environment:** `GEMINI_API_KEY` (Required), `CAXTON_STATE_DIR` (Optional),
`CAXTON_OFFLINE` / `AGENT_OFFLINE` (Optional)

**Exit codes:** 0 success, 1 error, 2 timeout, 127 git missing, 130 interrupted,
141 stdout closed early

**Scope and safety:**

- Caxton runs only inside a git worktree. The repository top level is the path
  namespace, so every path the model sees and reports is the one `git status`
  uses. The default selection is the current directory, which is not necessarily
  the repository root.
- Selection is enforced, not descriptive: the initial prompt, `list_files`,
  `read_file`, and every mutation tool consult one policy. Where two selections
  overlap the most specific wins, and at equal specificity the more restrictive
  one does, so `--edit docs/ --read docs/architecture.md` makes the directory
  writable with that one file carved out.
- Ignore filtering is git's alone
  (`git ls-files --cached --others --exclude-standard`), so negation
  (`!keep.log`), nested `.gitignore` files, anchored rules and
  `core.excludesFile` behave exactly as git defines them, and a deliberately
  tracked `dist/` is not second-guessed. A path typed on the command line
  overrides those rules; a path arriving from `--read-from`/`--edit-from`, or
  found by walking a selected directory, does not. Naming an ignored directory
  admits everything beneath it, including files force-tracked among ignored
  ones. Path-list entries are taken literally — no tilde expansion, and a
  NUL-delimited list is split without newline translation, so filenames
  containing a carriage return or newline survive intact. A backslash is an
  ordinary character in a filename here, not a separator, and is left alone.
- Anything writable must be restorable by git. A mutation run refuses to start
  on a dirty worktree, refuses to make a git-ignored path writable, and refuses
  to create one during the run — `git checkout -- .` and `git clean -fd` would
  not undo it. An ignored directory is refused as a creation root at preflight
  for the same reason, and a creation git cannot classify is refused rather than
  assumed safe. `--force` waives all of these. A run that adds an ignore rule
  covering something it created earlier is allowed — gitignoring generated
  output is an ordinary request — but the closing report names every such file
  and the command that removes it, since `git clean -fd` will not.
- Credential paths are never sent: `.ssh/`, `.gnupg/`, `.aws/` and similar
  directories, files such as `.npmrc`, `.netrc`, `.envrc` and
  `.git-credentials`, and patterns such as `*.pem`, `*.key` and `id_rsa*`.
  Naming one explicitly is an error rather than a silent omission. Project
  dotfiles (`.github/`, `.prettierrc`) stay visible. Creation is checked against
  the narrower rule that only credential directories are off limits, so adding a
  `.env.example` is not refused.
- Git's own metadata is never readable or writable, at any depth: `.git/` is
  outside every listing, `git clean -fd` never touches it, and a file dropped
  into it can execute on the next git command. Project dotfiles such as
  `.github/` and `.gitignore` stay ordinary content.
- Symlinks, submodules (checked out or not) and non-regular files (FIFOs,
  sockets and devices) are never included, and naming one explicitly is an
  error. That covers paths reached *through* a symlinked parent or a submodule
  boundary as well: a selector belongs to this repository only if every
  component of it does. Reads open regular files without following a final
  symlink, and `--timeout` covers directory traversal as well as the agent loop.
- Mutation tools are withheld entirely unless `--edit` names something.
- Tool paths are resolved with `realpath` and confined to the repository, as a
  backstop behind the per-path policy.
- Undoing a partial run takes both `git checkout -- .` (for files it modified)
  and `git clean -fd` (for files it created, which are untracked). Every run
  reports what it modified, created, and deleted on stderr, including when it
  times out or exhausts `--max-steps`.
- Because `--edit` rewrites files across a tree, `caxton` is declared unsafe in
  `permissions/unsafe` and always prompts rather than being pre-approved by
  `permission apply`.

**Examples:**

```bash
# Safe read-only architectural audit or repository Q&A (the default)
scripts/caxton "Count deprecated function usages and summarize"

# Edit two files while consulting a third that must not change
scripts/caxton "Update the parser but keep the documented behavior" \
  --edit src/parser.py tests/test_parser.py --read docs/architecture.md

# Edit a directory with one file carved out as read-only
scripts/caxton "Refresh the guides" --edit docs/ --read docs/architecture.md

# Preview the resolved policy without calling the API
scripts/caxton --dry-run "Translate the guides into French" --edit docs/

# Select many paths safely, inlining only what is needed
git ls-files -z '*.md' | scripts/caxton "Normalize headings" --edit-from - --null
```

### gh-markdown

Fetch GitHub Pull Requests, Issues, or Workflow Runs and format them as Markdown
for LLM Agents.

**Features:**

- **PRs**: Includes main description, comments, reviews, inline threads, and
  links to workflow runs for monitoring CI status.
- **Issues**: Includes title, description, labels, and comments.
- **Workflow Runs**: Includes run summary, duration, jobs, steps, and logs for
  failed jobs.

Requires `GITHUB_TOKEN` environment variable to be set with a GitHub Personal
Access Token.

**Token Setup:** You can generate a token at
<https://github.com/settings/personal-access-tokens>.

- **Minimum requirement for public repos**: Select **Repository access:
  Read-only access to public repositories** with **Permissions: None**.
- **For private repos**: Grant read access to Pull Requests, Issues, and Actions
  as needed.

```bash
scripts/gh-markdown URL
```

**Environment:** `GITHUB_TOKEN` (Required)

**Exit codes:** 0 success, 1 error

**Examples:**

```bash
# Fetch a PR
scripts/gh-markdown https://github.com/owner/repo/pull/123

# Fetch a Workflow Run
scripts/gh-markdown https://github.com/owner/repo/actions/runs/12345678
```

### context

Gathers the very latest, authoritative, up-to-date context for deep research on
various technical subjects (e.g., `gemini-api`, `mcp`, `home-assistant`) or
arbitrary GitHub directories. Run `context catalog` to see all available
entries. This script should be your first tool for gathering background
knowledge or the latest documentation for an unfamiliar domain. Supports passing
a full GitHub URL as a target (e.g.,
`https://github.com/owner/repo/tree/branch/path`).

**Warning:** Output can be very large. **Do not** read output directly into your
conversation history. Pipe to `emerson` for analysis, or redirect to a file to
search/read locally.

```bash
scripts/context show TARGET
```

**Commands:** `catalog` (list available entries), `show` (show context for
target), `template` (output plugin template)

**Exit codes:** 0 success, 1 error, 127 missing dependency

**Examples:**

```bash
# List available catalog entries
scripts/context catalog

# Gather context for Gemini API
scripts/context show gemini-api > gemini-context.md

# Pipe context directly to analysis
scripts/context show gemini-cli | scripts/emerson "How do commands work?"
```

### screenshot-describe

Generate concise alt-text for an image. Optimized for UI captures.

```bash
scripts/screenshot-describe IMAGE [PROMPT]
```

**Exit codes:** 0 success, 1 error, 127 missing dependency

### screenshot-compare

Compare two images for visual differences. Identifies layout shifts, color
changes, padding, and text updates.

```bash
scripts/screenshot-compare IMAGE1 IMAGE2 [PROMPT]
```

**Exit codes:** 0 differences found, 1 error (including missing ImageMagick), 2
images identical

### photo-smart-crop

Smart crop images around the detected primary subject (people, food, focal
points in a landscape) with a specified aspect ratio. Centers the maximal crop
box on the subject and enforces the aspect ratio. If no specific focal point is
found, crops around the central compositional area.

```bash
scripts/photo-smart-crop [--ratio W:H] INPUT OUTPUT
```

**Options:** `--ratio W:H` (default 5:3)

**Exit codes:** 0 success, 1 error (API error, invalid arguments), 2 rate
limited, 127 missing dependency

**Examples:**

```bash
# Default 5:3 aspect ratio
scripts/photo-smart-crop family.jpg family-cropped.jpg

# 16:9 for video thumbnails
scripts/photo-smart-crop --ratio 16:9 portrait.jpg thumbnail.jpg

# Square crop for profile pictures
scripts/photo-smart-crop --ratio 1:1 headshot.png avatar.png
```

### photo-query

Ask Gemini a question about one or more photos. The QUERY positional is either
an `@`-prefixed built-in or a free-form prompt:

- `@people` — boolean: do people feature prominently? Single-file mode encodes
  the answer in the exit code (`0` true / `1` false / `2` error); stdout silent;
  `-v` echoes `true`/`false` to **stderr**. Defaults to a 384px resize
  (single-tile token cost).
- Any free-form text is sent as the prompt. Add `--schema SPEC` (llm-style DSL
  like `'has_bed bool, count int'`) for structured output and `--filter FIELD`
  to print only paths whose boolean field is true.

Multiple files (or non-boolean queries) emit per-file lines on stdout; exit code
only reflects success/failure.

Default model is `gemini-3.5-flash-lite` — the cheapest/fastest Gemini 3 tier,
appropriate for high-volume classification and lightweight visual Q&A. Override
with `--model` for harder questions.

Deterministic image prep (EXIF rotate, alpha flatten, resize to `--max-size`
(default 768, 384 for `@people`), WebP encode) is content-addressed-cached at
`~/.cache/agent-tools/photo-query/` so repeated queries against the same images
skip the resize entirely. Use `--no-cache` to bypass.

```bash
# Boolean check (exit code idiom)
if scripts/photo-query @people photo.jpg; then echo "Found people"; fi

# Multi-file boolean: per-line `<path>\t<true|false>` on stdout
scripts/photo-query @people *.jpg

# Schema-constrained query with filter
scripts/photo-query --recursive \
  --schema "has_bedside_table bool" \
  --filter has_bedside_table \
  "Does this image feature a bedside table?" \
  ./photos/

# Free-text description per file
scripts/photo-query "Describe the scene in under 200 chars." room.jpg
```

**Exit codes:** 0 success (or true for single-file boolean), 1 false (only for
single-file boolean), 2 error (network, parse, missing file).

### emerson

Generate essay-length (~3000 words) analysis from text input. Produces
authoritative, footnoted Markdown. Operates as a strict, sandboxed tool that
relies entirely on the provided standard input (`stdin`). It performs
closed-book analysis without external search and acts as an elite technical
analyst instructed to treat the input as the sole source of truth to prevent
hallucination. Use this tool when you need summarization or formatting of
specific, pre-gathered text. Can be combined with `context` to provide rich
background material.

```bash
scripts/emerson "PROMPT" < input.txt
```

**Exit codes:** 0 success, 1 error, 127 missing dependency

### pascal

Ask a question and get a short, paragraph-style response (wrapped to 80
columns). Optimized for quick answers.

```bash
scripts/pascal [-] "QUESTION"
```

**Input:** Optional context via stdin. Pass `-` as the first argument to read
it; without `-`, stdin is ignored.

**Exit codes:** 0 success, 1 error, 127 missing dependency

**Examples:**

```bash
# Ask a quick question
scripts/pascal "What is the capital of Peru?"

# Summarize a file
cat article.md | scripts/pascal - "Summarize this article"

# Explain code
scripts/pascal - "Explain this code" < script.sh
```

### satisfies

Evaluate whether input text satisfies a condition. Returns boolean via exit
code.

```bash
echo "text" | scripts/satisfies [-v|--verbose] "CONDITION"
```

**Options:** `-v, --verbose` (output "true" or "false" to stderr)

**Exit codes:** 0 true (satisfies), 1 false (does not satisfy), 127 missing
dependency

**Examples:**

```bash
# Check if file mentions a topic
cat file.txt | scripts/satisfies "mentions Elvis" && echo "Found it"

# Validate content type
cat response.json | scripts/satisfies "is valid JSON with an 'id' field"

# Use in conditionals
if cat log.txt | scripts/satisfies "contains error messages"; then
  echo "Errors detected"
fi
```

### pacioli

Extract a structured purchase record from a receipt or order-confirmation email.
Reads one email (raw text or HTML) on stdin and prints a single JSON object:
vendor, brands, line items, category, order number/date, currency, total, and an
`is_purchase` flag. Category-agnostic and one-email-per-invocation, so a driver
can fan it out across a mailbox in parallel.

```bash
scripts/pacioli < order.eml
```

**Input:** the email on stdin; optional `From:/Subject:/Date:` header lines on
top help. HTML is stripped to text and truncated before the model call.

**Options:** `--model MODEL`, `--max-chars N`, `--text-only` (print the stripped
text instead of calling the model — useful for debugging)

**Exit codes:** 0 success, 1 API error, 2 usage/no input

**Examples:**

```bash
# Extract from a saved email
scripts/pacioli < order.eml

# Pipe an email message body through (e.g., using an email CLI client like gog)
gog gmail get "$id" --json | jq -r '"From: \(.headers.from)\nSubject: \(.headers.subject)\n\n" + .body' | scripts/pacioli

# Inspect what the model actually sees
scripts/pacioli --text-only < order.eml
```

### token-count

Count tokens in text using the Gemini API.

```bash
cat file.txt | scripts/token-count
```

**Exit codes:** 0 success, 1 error, 127 missing dependency

### gemini-api-doctor

Ping Gemini models to test API key validity and endpoint responsiveness. Runs
checks in parallel and enforces a 60-second timeout.

```bash
scripts/gemini-api-doctor [MODELS...]
```

**Input:**

- stdin: API Key (if not set in environment).

**Environment:** `GEMINI_API_KEY` (Optional. Used if set, otherwise reads from
stdin)

**Options:**

- `--help`: Display help message.

**Examples:**

- `echo "YOUR_API_KEY" | scripts/gemini-api-doctor`
- `scripts/gemini-api-doctor gemini-3.5-flash-lite`

**Exit codes:** 0 success, 1 error

### popper

Interact with Android UIs using an AI agent powered by `uiautomator2` and
Gemini. This allows semantic control of the device by providing a goal in
natural language. Screenshots are captured at each step and saved to a unique
run directory in an XDG-compliant temporary location.

```bash
scripts/popper "GOAL"
```

**Options:** `--launch PACKAGE` (launch a package before starting),
`--stay-in-app` (restrict the run to a single application package),
`--dump-layout` (print the current simplified UI layout as JSON and exit),
`--agent-screenshots` / `--no-agent-screenshots` (enable/disable sending
screenshots to API), `--local-screenshots` / `--no-local-screenshots`
(enable/disable saving screenshots locally), `--screenshot-dir DIR` (override
directory to save screenshots)

**Environment:** `ANDROID_SERIAL` (optional, target specific device)

**Exit codes:** 0 success (task completed), 1 error (task failed), 2 timeout

**Examples:**

```bash
# General UI task
scripts/popper "accept all permissions"

# Launch an app and keep the run inside it
scripts/popper --launch com.example.fitness --stay-in-app "start a running exercise"

# Target specific device
env ANDROID_SERIAL=12345 scripts/popper "open settings"
```

## Image Encoding Notes

- Screenshot tools encode to lossless WebP; `photo-query` uses lossy WebP and
  `photo-smart-crop` uses HEIF (both resize first to limit token cost)
- Alpha handling varies by tool: `screenshot-describe` drops the alpha channel
  (`-alpha off`); `screenshot-compare` flattens onto a magenta background, so
  transparency differences show up in comparisons; `photo-query` flattens onto
  white
- Base64: use `-w 0` (Linux) or `-b 0` (macOS) for single-line output
- Single-image prompts: image before text (Gemini best practice)
- Multi-image comparison: text before images (Gemini best practice)

## Safety Notes

- Scripts require network access to the Gemini API
- Requires a Gemini API key (reads from `GEMINI_API_KEY`)
- API calls may incur usage costs
- Large images increase request size and latency
- Scripts do not store or log input data

## Reference Material

- **Command Reference**: Detailed documentation for each script. See
  [references/command-index.md](references/command-index.md).
- **Troubleshooting**: Common issues and solutions. See
  [references/troubleshooting.md](references/troubleshooting.md).
- **Agent Function Notation (AFN)**: A notation for describing agent behaviour
  as functions. See [references/afn.md](references/afn.md).
- **Software Installation**: How to install optional CLI tools such as codex,
  claude, agy, and build-brief. See
  [references/software-installation.md](references/software-installation.md).

# Command Index

<!-- markdownlint-disable MD013 MD024 -->

## Contents

- [screenshot-describe](#screenshot-describe) - Generate alt-text from images
- [screenshot-compare](#screenshot-compare) - Compare two images for differences
- [photo-smart-crop](#photo-smart-crop) - Smart crop around the primary subject
- [photo-query](#photo-query) - Ask Gemini about photos (boolean / schema /
  free-text)
- [oracle](#oracle) - Deep reasoning and synthesis over files or directories
- [emerson](#emerson) - Generate essay-length analysis from text
- [pascal](#pascal) - Ask a question and get a short response
- [context](#context) - Generate aggregated context for analysis
- [satisfies](#satisfies) - Evaluate boolean conditions against text
- [token-count](#token-count) - Count tokens in text
- [popper](#popper) - Interact with Android UIs using an AI agent
- [gh-markdown](#gh-markdown) - Format GitHub PRs/Issues/Runs as Markdown
- [gemini-api-doctor](#gemini-api-doctor) - Ping Gemini models to test the API
  key
- [Image Encoding](#image-encoding) - Platform-specific encoding details
- [Request Structure](#request-structure) - API request patterns

## Maintenance

The `Help` sections below are generated from each script's `--help` output by
`command-index-sync` (in the coding-standards skill). Do not edit the fenced
blocks between `<!-- generated: ... -->` markers by hand: change the script's
`usage()` text instead, then run `command-index-sync` on this file.

______________________________________________________________________

## screenshot-describe

Generate a text description of a screenshot using the Gemini API.

### Help

<!-- generated: ../scripts/screenshot-describe --help -->

```text
Usage: screenshot-describe [OPTIONS] [IMAGE] [PROMPT]

Generate a text description of a screenshot using the Gemini API. Optimized for
screenshots and UI captures; the default prompt focuses on UI elements, text,
colors, and layout.

Arguments:
  IMAGE       Path to a screenshot, or '-' for stdin (default: '-')
  PROMPT      Custom prompt for the AI model (optional)

Options:
  --help         Display this help message and exit
  --model MODEL  Gemini model to use (default: gemini-3.5-flash)

Environment:
  GEMINI_API_KEY  Required. Your Gemini API key.
  GEMINI_MODEL    Optional. Default model if --model is not given.

Exit Codes:
  0    Success
  1    General error (API error, missing file)
  127  Missing required dependency

Examples:
  screenshot-describe screenshot.png
  screenshot-describe screen-capture.png "What objects are in this image?"
  screenshot-describe ui-mockup.png "List all UI elements visible"
```

<!-- /generated -->

### Raw API Command

Model: `gemini-3.5-flash`

```bash
IMAGE_BASE64=$(magick image.png -alpha off -define webp:lossless=true webp:- | base64 -w 0)

curl -s -X POST \
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent" \
  -H "x-goog-api-key: $GEMINI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "contents": [{
      "parts": [
        {"inlineData": {"mimeType": "image/webp", "data": "'"$IMAGE_BASE64"'"}},
        {"text": "Generate concise alt text (up to 300 chars) describing the content of this screenshot."}
      ]
    }]
  }' | jq -r '.candidates[0].content.parts[0].text'
```

______________________________________________________________________

## screenshot-compare

Compare two screenshots using the Gemini API to identify visual differences.

### Help

<!-- generated: ../scripts/screenshot-compare --help -->

```text
Usage: screenshot-compare IMAGE1 IMAGE2 [PROMPT]

Compare two screenshots using the Gemini API. Identifies visual differences like
layout shifts, color changes, padding, or text updates.

Arguments:
  IMAGE1      Path to the first screenshot (baseline/before), or '-' for stdin
  IMAGE2      Path to the second screenshot (comparison/after), or '-' for stdin
  PROMPT      Custom prompt for the AI model (optional)

Options:
  --help         Display this help message and exit
  --version      Display version number and exit
  --model MODEL  Gemini model to use (default: gemini-3.5-flash)

Environment:
  GEMINI_API_KEY  Required. Your Gemini API key.
  GEMINI_MODEL    Optional. Default model if --model is not given.

Examples:
  screenshot-compare before.png after.png
  screenshot-compare v1.png v2.png "Check for font size changes in the header"

Exit Codes:
  0    Success (differences found and described)
  1    General error (API error, usage, missing file, etc.)
  2    Images are identical (no differences to describe)
```

<!-- /generated -->

### Raw API Command

Model: `gemini-3.5-flash`

```bash
IMG1_B64=$(magick before.png -background magenta -flatten -define webp:lossless=true webp:- | base64 -w 0)
IMG2_B64=$(magick after.png -background magenta -flatten -define webp:lossless=true webp:- | base64 -w 0)

curl -s -X POST \
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent" \
  -H "x-goog-api-key: $GEMINI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "contents": [{
      "parts": [
        {"text": "Compare these two screenshots. Describe the visual differences."},
        {"inlineData": {"mimeType": "image/webp", "data": "'"$IMG1_B64"'"}},
        {"inlineData": {"mimeType": "image/webp", "data": "'"$IMG2_B64"'"}}
      ]
    }]
  }' | jq -r '.candidates[0].content.parts[0].text'
```

______________________________________________________________________

## photo-smart-crop

Smart crop images around the primary subject (people, food, focal points in a
landscape) detected via the Gemini API.

### Help

<!-- generated: ../scripts/photo-smart-crop --help -->

```text
Usage: photo-smart-crop [OPTIONS] <input> <output>

Smart crop images to focus on the primary subject with a specified aspect ratio.

Arguments:
  input        Input image file
  output       Output image file (explicit path)

Options:
  --ratio W:H    Aspect ratio for crop (default: 5:3)
  --model MODEL  Gemini model to use (default: gemini-3.5-flash)
  --help         Display this help message and exit

Processing:
  Uses Gemini API to detect the primary subject (people, food, landscapes, etc.)
  and calculates the maximum possible crop box with the specified aspect ratio,
  centered on the subject. Works with any input orientation (portrait or landscape).

Environment:
  GEMINI_API_KEY  Required. Your Gemini API key.
  GEMINI_MODEL    Optional. Default model if --model is not given.

Exit Codes:
  0    Success (cropped output written)
  1    Error (API error, missing file, invalid arguments)
  2    Rate limited (API returned 429)
  127  Missing required command

Examples:
  photo-smart-crop photo.jpg cropped.jpg
  photo-smart-crop --ratio 16:9 portrait.jpg landscape-16x9.jpg
  photo-smart-crop --ratio 4:3 ~/Photos/family.jpg ./output/family-4x3.jpg
```

<!-- /generated -->

### Processing Details

1. Asks the Gemini vision API for a bounding box around the primary subject (for
   people, centered on the face/head area; otherwise the most aesthetically
   pleasing focal region)
1. If no specific focal point is found, the model returns a box covering the
   central compositional area
1. Converts the normalized (0-1000) coordinates to pixels
1. Computes the maximum crop box with the requested aspect ratio and centers it
   on the subject, clamped to the image boundaries
1. Applies the crop using ImageMagick with auto-orient for EXIF handling

______________________________________________________________________

## photo-query

Ask Gemini a question about one or more photos. The QUERY positional is either
an `@`-prefixed built-in (e.g. `@people`) or a free-form prompt; built-ins ship
with their own prompt, schema, and tuned defaults. Image pre-processing (EXIF
rotation, alpha flatten, resize, WebP encode) is content-addressed-cached so
repeated queries against the same images skip all redundant work.

### Help

<!-- generated: ../scripts/photo-query --help -->

```text
usage: photo-query [--help] [--max-size N] [--model MODEL] [--no-cache]
                   [--recursive] [--schema SCHEMA] [--filter FILTER_FIELD]
                   [-v]
                   QUERY FILE_OR_DIR [FILE_OR_DIR ...]

Ask Gemini a question about one or more photos.

positional arguments:
  QUERY                 @-prefixed built-in (@people) or a free-form prompt
  FILE_OR_DIR

options:
  --help                Show this help message and exit
  --max-size N          Longest-edge resize cap, in px (default: 768; built-
                        ins may use a smaller default)
  --model MODEL         Gemini model id (default: $GEMINI_MODEL if set, else
                        gemini-3.1-flash-lite)
  --no-cache            Bypass the resize cache
  --recursive           Recurse into directory arguments
  --schema SCHEMA       llm-style schema_dsl, e.g. 'has_bed bool, count int'.
                        Not allowed with @ built-ins.
  --filter FILTER_FIELD
                        Print only paths whose boolean FIELD is true
  -v, --verbose         Echo true/false to stderr (single-file boolean mode)
```

<!-- /generated -->

### Built-in queries

| Name      | Description                                                   |
| --------- | ------------------------------------------------------------- |
| `@people` | Do people feature prominently? Boolean. 384px resize default. |

### Examples

```bash
# Boolean exit-code idiom (single file)
if scripts/photo-query @people photo.jpg; then echo "Found"; fi

# Multi-file boolean: tab-separated <path> <true|false> on stdout
scripts/photo-query @people *.jpg

# Schema-constrained free-form prompt with filter (one-field bool also exit-codable)
scripts/photo-query --recursive \
  --schema "has_bedside_table bool" \
  --filter has_bedside_table \
  "Does this image feature a bedside table?" \
  ./photos/

# Multi-field schema, JSON output per file
scripts/photo-query \
  --schema "fireplace bool, art_over_fireplace bool" \
  "Does this image show a fireplace? Artwork above it?" \
  *.jpg

# Free-text description
scripts/photo-query "Describe the scene in under 200 chars." room.jpg
```

### Cache

Pre-processed WebP bytes are stored at
`~/.cache/agent-tools/photo-query/<sha256>-<max_size>-v<N>.webp`. Cache key
includes the file's content hash, so renames/moves still hit. Clear manually if
it grows unbounded; no automatic eviction.

### Exit-Code Semantics

The exit code encodes the answer **only** when a single file is passed and the
query produces a single boolean field (`@people`, or a free-form prompt with a
one-field bool schema). Otherwise the exit code reflects success/failure only.

| Mode                      | Code | Description                                |
| ------------------------- | ---- | ------------------------------------------ |
| Single-file boolean       | 0    | True                                       |
| Single-file boolean       | 1    | False                                      |
| Multi-file or non-boolean | 0    | All images processed successfully          |
| Any mode                  | 2    | Error (network, parse, missing file, etc.) |

______________________________________________________________________

## oracle

Consult the Oracle for a very carefully researched and considered answer
utilizing deep reasoning and Google Search grounding.

### Help

<!-- generated: ../scripts/oracle --help -->

```text
Usage: oracle [OPTIONS] "PROMPT" [FILE_OR_DIR ...]

Consult the Oracle for a very carefully researched and considered answer.
Designed for the highest quality response possible, utilizing deep reasoning
and Google Search grounding.

The Oracle is not a standard, quick-reply AI. It is designed to process massive
amounts of information and synthesize authoritative answers. It has no memory
of previous conversations or your current session.

Best Practices for Context:
  To get the most out of the Oracle, you must provide comprehensive context.
  - Self-Contained Prompts: Write the prompt as if explaining the problem to an
    expert who has zero prior knowledge of your task. Do not use references like
    "the solution we implemented" without explaining exactly what it was.
  - Broad File Context: Include source files and directories as positional
    arguments. Err on the side of providing too much context—including files,
    directories, or documentation even if you think they are only marginally
    relevant—so the Oracle can discover non-obvious connections.
  - Persona & Audience: Who are you, and who is this answer for?
  - Goals & Intent: What is the ultimate objective of this request?
  - Success Criteria: How will you know the answer is correct or useful?
  - Format & Style: Should the output be a technical spec, an essay, or a report?
  - Constraints: What must the Oracle explicitly avoid doing?
  - Examples: Provide a "few-shot" example of what a good output looks like.
  - Assumptions: Clarify ambiguous terms or state decisions already made.
  - Failed Attempts: If you are stuck, describe what approaches have already
    been tried and why each failed or was rejected (including any error messages
    or constraints). This prevents the Oracle from re-proposing dead ends and
    focuses its reasoning on genuinely novel solutions.

Arguments:
  PROMPT        The specific question or task for the Oracle.
  FILE_OR_DIR   Optional. Files or directories to include as context. Directories
                are recursively walked (ignoring hidden files and standard ignore
                lists like node_modules). Text files are inlined; media files are
                uploaded to the Gemini API (and cleaned up automatically).

Input:
  stdin         Optional. Context or reference material piped into the script.

Options:
  --force       Bypass context size limits (1MB for text, 20MB per media file).
  --maps        Use Google Maps grounding instead of Google Search. (Cannot be combined with --code).
  --code        Enable Code Execution for Python.
  --dry-run     Output a summary of the payload (resolved files, sizes, and prompt) without calling the Gemini API.
  --model MODEL Gemini model to use (default: gemini-3.1-pro-preview).
  --serialize   Save the self-contained payload to a file in the cache (Default: on).
  --no-serialize Disable saving the payload to the cache.
  --help        Display this help message and exit.

Environment:
  GEMINI_API_KEY  Required. Your Gemini API key.
  GEMINI_MODEL    Optional. Default model if --model is not given.

Examples:
  cat codebase.md | oracle "Propose a refactoring plan" -
  oracle "Does this code match the spec?" src/ spec.pdf
```

<!-- /generated -->

### Raw API Command

Model: `gemini-3.1-pro-preview` with `thinking_level="high"` and Google Search
tools enabled. *(Complex Python script recursively walking directories and
processing media files.)*

### Exit Codes

| Code | Description                 |
| ---- | --------------------------- |
| 0    | Success                     |
| 1    | General error               |
| 127  | Missing required dependency |

______________________________________________________________________

## emerson

Generate essay-length (~3000 words) analysis from text input using Gemini 3 Pro.
Operates as a strict, sandboxed, closed-book text-generation tool with no access
to external search, instructed to prevent hallucination by strictly adhering to
the provided text.

### Help

<!-- generated: ../scripts/emerson --help -->

```text
Usage: emerson [OPTIONS] "PROMPT" < INPUT_FILE

Generates an essay-length answer (approx. 3000 words) to the PROMPT, based
primarily on the text provided via standard input. Uses the Gemini 3 Pro
Preview model by default.

Arguments:
  PROMPT      The question or topic to address.

Input:
  stdin       The reference material (text) to use for the response.

Options:
  --help         Display this help message and exit
  --model MODEL  Gemini model to use (default: gemini-3.1-pro-preview)

Environment:
  GEMINI_API_KEY  Required. Your Gemini API key.
  GEMINI_MODEL    Optional. Default model if --model is not given.

Exit Codes:
  0    Success
  1    General error (usage, no input, API error)
  127  Missing required dependency

Examples:
  cat documentation.md | emerson "Summarize the key architectural changes"
  emerson "Explain the new features" < release_notes.txt
```

<!-- /generated -->

### Raw API Command

Model: `gemini-3.1-pro-preview`

```bash
PROMPT="Summarize the key points"

# --rawfile avoids ARG_MAX limits on large inputs
curl -s -X POST \
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-pro-preview:generateContent" \
  -H "x-goog-api-key: $GEMINI_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$(jq -n \
    --rawfile text document.txt \
    --arg prompt "$PROMPT" \
    '{
      contents: [{
        role: "user",
        parts: [
          {text: ("Reference Material:\n\n" + $text)},
          {text: ("\n\nTask/Question:\n" + $prompt)}
        ]
      }],
      generationConfig: {temperature: 1.0, maxOutputTokens: 8192}
    }')" | jq -r '.candidates[0].content.parts[0].text'
```

______________________________________________________________________

## pascal

Asks a question to the Gemini 3 Flash model and prints a short, paragraph-style
response (wrapped to 80 columns).

### Help

<!-- generated: ../scripts/pascal --help -->

```text
Usage: pascal [OPTIONS] [-] PROMPT

Asks a question to the Gemini 3 Flash model and prints a short, paragraph-style
response (wrapped to 80 columns).

Arguments:
  -           Read context from stdin and include it with the question.
              Without a leading '-', stdin is ignored.
  PROMPT      The question to ask.

Options:
  --help         Display this help message and exit
  --model MODEL  Gemini model to use (default: gemini-3.5-flash)

Environment:
  GEMINI_API_KEY  Required. Your Gemini API key.
  GEMINI_MODEL    Optional. Default model if --model is not given.

Exit Codes:
  0    Success
  1    General error (usage, API error)
  127  Missing required dependency

Examples:
  pascal "What is the capital of Peru?"
  cat article.md | pascal - "Summarize this article"
  pascal - "Explain this code" < script.sh
```

<!-- /generated -->

### Raw API Command

Model: `gemini-3.5-flash`

```bash
PROMPT="What is the capital of Peru?"
SYSTEM_INSTRUCTION="You are a helpful assistant. Provide a short, direct answer \
(less than 300 characters) in a single full paragraph. Do not use point form, \
lists, or markdown formatting (like bold or headers). Just plain text."

curl -s -X POST \
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent" \
  -H "x-goog-api-key: $GEMINI_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$(jq -n \
    --arg system_instruction "$SYSTEM_INSTRUCTION" \
    --arg user_prompt "$PROMPT" \
    '{
      system_instruction: { parts: [{ text: $system_instruction }] },
      contents: [{ role: "user", parts: [{ text: $user_prompt }] }],
      generationConfig: { temperature: 1.0, maxOutputTokens: 2048 }
    }')" | jq -r '.candidates[0].content.parts[0].text' | fmt -w 80
```

______________________________________________________________________

## context

Generate aggregated context for various topics (e.g., `gemini-api`,
`gemini-cli`) by fetching data from GitHub or local execution. Run
`scripts/context --list` to see all available topics. Outputs XML format
suitable for `emerson`.

**Note:** The output is often extremely large. Agents should **not** consume
this output directly. Instead, pipe it to `emerson` for analysis, or redirect it
to a file to search locally.

### Help

<!-- generated: ../scripts/context --help -->

```text
usage: context [--help] [--list] [--force] [--plugin-template] [topic]

Generate aggregated context for a specific topic, a GitHub URL, or a local directory. Fetches resources (repositories, files, URLs) and emits them as structured XML for AI agent consumption.

GitHub URL support:
  Pass a full GitHub URL as the topic to fetch and package its contents.
  Example: https://github.com/owner/repo/tree/branch/path

Local Directory support:
  Pass a local directory path to package its contents.
  Example: /path/to/local/dir

Topics:
  compose-architecture   Android Compose Architecture documentation
  firebase               Firebase CLI and hosting documentation
  gemini-api             Gemini API documentation and examples
  gemini-cli             Gemini CLI documentation
  gemini-sdk-js          Google Gemini JavaScript SDK codegen instructions
  homeassistant          Home Assistant integration, automation, API and CLI documentation
  inkyframe              Pimoroni Inky Frame documentation
  mcp-server             MCP server documentation and specification
  meshtastic             Meshtastic documentation
  prompting              Prompt engineering guides for Claude, Gemini, and OpenAI
  rpi                    Raspberry Pi documentation
  skills                 Agent skills format specification and authoring guide

positional arguments:
  topic              Topic to generate context for

options:
  --help             show this help message and exit
  --list             List available topics (names only)
  --force            Force cache rebuild
  --plugin-template  Output a template/documentation for creating a Python
                     plugin
```

<!-- /generated -->

### Examples

```bash
# List available topics
scripts/context --list

# Gather context for Gemini API
scripts/context gemini-api > gemini-context.xml

# Pipe context directly to analysis
scripts/context gemini-cli | scripts/emerson "How do commands work?"

# Combine with other tools
scripts/context mcp-server | grep "protocol"
```

### Exit Codes

| Code | Description                         |
| ---- | ----------------------------------- |
| 0    | Success                             |
| 1    | General error (unknown topic, etc.) |
| 127  | Missing required dependency         |

______________________________________________________________________

## satisfies

Evaluate whether input text satisfies a condition using the Gemini API. Returns
a boolean result via exit code.

### Help

<!-- generated: ../scripts/satisfies --help -->

```text
Usage: satisfies PROMPT

Evaluates if the input from stdin satisfies the PROMPT.
Returns true (exit 0) or false (exit 1).

Arguments:
  PROMPT      The condition or question to evaluate (e.g., "mentions Elvis")

Options:
  --help         Display this help message and exit
  --model MODEL  Gemini model to use (default: gemini-2.5-flash-lite)
  -v, --verbose  Output "true" or "false" to stderr

Environment:
  GEMINI_API_KEY  Required. Your Gemini API key.
  GEMINI_MODEL    Optional. Default model if --model is not given.

Exit Codes:
  0  True (satisfies prompt)
  1  False (does not satisfy prompt)

Examples:
  cat file.txt | satisfies "mentions Elvis"
  echo "hello world" | satisfies "is a greeting" && echo "It is!"
```

<!-- /generated -->

### Raw API Command

Model: `gemini-2.5-flash-lite`

```bash
CONDITION="mentions Elvis"

# --rawfile avoids ARG_MAX limits on large inputs
RESPONSE=$(curl -s -X POST \
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent" \
  -H "x-goog-api-key: $GEMINI_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$(jq -n \
    --rawfile input file.txt \
    --arg cond "$CONDITION" \
    '{
      contents: [{
        parts: [
          {text: $input},
          {text: ("Does the above text satisfy the condition: " + $cond)}
        ]
      }],
      generationConfig: {
        responseMimeType: "application/json",
        responseSchema: {
          type: "object",
          properties: {satisfies: {type: "boolean"}},
          required: ["satisfies"]
        }
      }
    }')")

# Extract and check result
RESULT=$(echo "$RESPONSE" | jq -r '.candidates[0].content.parts[0].text' | jq -r '.satisfies')
if [ "$RESULT" = "true" ]; then
  exit 0
else
  exit 1
fi
```

______________________________________________________________________

## token-count

Count tokens in text using the Gemini API's countTokens endpoint.

### Help

<!-- generated: ../scripts/token-count --help -->

```text
Usage: token-count < INPUT_FILE
       echo "text" | token-count

Counts the tokens in the text provided via standard input using the Gemini API.

Input:
  stdin       The text to count tokens for.

Options:
  --help         Display this help message and exit
  --model MODEL  Gemini model to use (default: gemini-2.0-flash)

Environment:
  GEMINI_API_KEY  Required. Your Gemini API key.
  GEMINI_MODEL    Optional. Default model if --model is not given.

Exit Codes:
  0    Success (outputs token count)
  1    General error (usage, empty input, API error)
  127  Missing required dependency

Examples:
  echo "The quick brown fox jumps over the lazy dog." | token-count
  token-count < document.txt
  cat *.md | token-count
```

<!-- /generated -->

______________________________________________________________________

## popper

Interact with Android UIs using an AI agent powered by `uiautomator2` and
Gemini. This allows semantic control of the device by providing a goal in
natural language.

### Help

<!-- generated: ../scripts/popper --help -->

```text
usage: popper [--launch PACKAGE] [--stay-in-app] [--timeout SECONDS]
              [--output-format {text,stream-json}]
              [--agent-screenshots | --no-agent-screenshots]
              [--local-screenshots | --no-local-screenshots]
              [--local-screenshot-dir DIR] [--output-dir DIR] [--dump-layout]
              [--model MODEL] [--help]
              [goal]

Interact with Android UIs using an AI agent.

positional arguments:
  goal                  The goal for the AI to achieve (e.g. 'start an
                        exercise')

options:
  --launch PACKAGE      Launch the specified app before starting (e.g.
                        com.example.fitness)
  --stay-in-app         Restrict the agent to a single application package for
                        the entire run
  --timeout SECONDS     Maximum execution time in seconds (default: 180; exit
                        code 2 on timeout)
  --output-format {text,stream-json}
                        Output format: 'text' (default, human-readable) or
                        'stream-json' (NDJSON to stdout)
  --agent-screenshots, --no-agent-screenshots
                        Enable/disable transmitting screenshots to the Gemini
                        API (default: enabled)
  --local-screenshots, --no-local-screenshots
                        Enable/disable saving screenshots to the local disk
                        for debugging (default: enabled)
  --local-screenshot-dir DIR
                        Directory to save step-by-step debug screenshots
                        (default: XDG_RUNTIME_DIR/popper or fallback to tmp)
  --output-dir DIR      Directory to save explicit screenshots requested by
                        the agent (default: current directory)
  --dump-layout         Dump the UI layout as JSON and exit
  --model MODEL         Gemini model to use (default: $GEMINI_MODEL if set,
                        else gemini-3.5-flash)
  --help                show this help message and exit

Environment:
  ANDROID_SERIAL  Serial number of device to connect to (see 'adb devices -l').
                  To target a specific device, use:
                    env ANDROID_SERIAL=<serial> popper "accept all permissions"
  GEMINI_API_KEY  Required. Your Gemini API key.
  GEMINI_MODEL    Optional. Default model if --model is not given.
```

<!-- /generated -->

### Examples

```bash
# General UI task
scripts/popper "accept all permissions"

# Launch an app and keep the run inside it
scripts/popper --launch com.example.fitness --stay-in-app "start a running exercise"

# Dump the current simplified layout without running the agent
scripts/popper --dump-layout

# Target specific device
env ANDROID_SERIAL=12345 scripts/popper "open settings"
```

### Raw API Command

*This script delegates complex control flow, image capture, XML parsing, and
planning to a python script (`uv run --script`). It cannot be reasonably reduced
to a single curl command. Please see `scripts/popper` for the implementation
details.*

### Exit Codes

| Code | Description              |
| ---- | ------------------------ |
| 0    | Success (task completed) |
| 1    | Error (task failed)      |
| 2    | Timed out                |

______________________________________________________________________

## gh-markdown

Fetch GitHub Pull Requests, Issues, or Workflow Runs and format them as Markdown
for LLM agents, including review threads (with resolution status) and logs for
failed workflow jobs. See the skill's SKILL.md for GitHub token setup.

### Help

<!-- generated: ../scripts/gh-markdown --help -->

```text
Usage: gh-markdown <url>

Fetches GitHub PR, Issue, or Workflow Run details and prints formatted Markdown.
Requires GITHUB_TOKEN environment variable.

Options:
  --help      Display this help message and exit

Examples:
  gh-markdown https://github.com/owner/repo/pull/123
  gh-markdown https://github.com/owner/repo/actions/runs/12345678
```

<!-- /generated -->

### Exit Codes

| Code | Description                                |
| ---- | ------------------------------------------ |
| 0    | Success                                    |
| 1    | General error (API error, unsupported URL) |

______________________________________________________________________

## gemini-api-doctor

Ping Gemini models to test API key validity and endpoint responsiveness. Runs
checks in parallel with a 60-second timeout; successes go to stdout, failures to
stderr.

### Help

<!-- generated: ../scripts/gemini-api-doctor --help -->

```text
usage: gemini-api-doctor [--help] [--model MODEL] [models ...]

Ping Gemini models to test API key validity. Takes API key from GEMINI_API_KEY
environment variable or stdin.

positional arguments:
  models         Models to ping. If omitted, uses $GEMINI_MODEL if set, else
                 defaults.

options:
  --help         Show this help message and exit
  --model MODEL  Ping a single model (equivalent to passing it as a positional
                 argument)
```

<!-- /generated -->

### Exit Codes

| Code | Description                 |
| ---- | --------------------------- |
| 0    | All pinged models responded |
| 1    | At least one model failed   |

______________________________________________________________________

## Image Encoding

### Platform Differences

The scripts handle platform differences automatically, but for raw API commands:

**Linux:**

```bash
base64 -w 0  # Single-line output
```

**macOS:**

```bash
base64 -b 0  # Single-line output
```

### Encoding Process

1. Convert to lossless WebP format
1. Remove alpha channel (`-alpha off`)
1. Encode to base64 (single line)

```bash
# Full encoding command
magick input.png -alpha off -define webp:lossless=true webp:- | base64 -w 0
```

### Why WebP?

- Lossless compression preserves detail for accurate analysis
- Consistent encoding across different input formats
- Smaller payload than uncompressed formats

### Alpha Channel Handling

The `-alpha off` flag (used by `screenshot-describe`) removes transparency, so
images differing only in alpha channel are treated as identical.
`screenshot-compare` instead flattens onto a magenta background
(`-background magenta -flatten`), which makes transparency differences visible
in comparisons. `photo-query` flattens onto white.

______________________________________________________________________

## Request Structure

### Single-Image Prompts

Place image **before** text (Gemini best practice):

```json
{
  "contents": [
    {
      "parts": [
        { "inlineData": { "mimeType": "image/webp", "data": "<base64>" } },
        { "text": "Describe this image" }
      ]
    }
  ]
}
```

### Multi-Image Comparison

Place text **before** images (Gemini best practice):

```json
{
  "contents": [
    {
      "parts": [
        { "text": "Compare these images" },
        { "inlineData": { "mimeType": "image/webp", "data": "<base64-1>" } },
        { "inlineData": { "mimeType": "image/webp", "data": "<base64-2>" } }
      ]
    }
  ]
}
```

### Text Analysis

Structure with reference material first, then task:

```json
{
  "contents": [
    {
      "role": "user",
      "parts": [
        { "text": "Reference Material:\n\n<content>" },
        { "text": "\n\nTask/Question:\n<prompt>" }
      ]
    }
  ],
  "generationConfig": {
    "temperature": 1.0,
    "maxOutputTokens": 8192
  }
}
```

### Boolean Evaluation

Use structured output to get JSON boolean response:

```json
{
  "contents": [
    {
      "parts": [
        { "text": "<input text>" },
        { "text": "Does the above text satisfy the condition: <condition>" }
      ]
    }
  ],
  "generationConfig": {
    "responseMimeType": "application/json",
    "responseSchema": {
      "type": "object",
      "properties": { "satisfies": { "type": "boolean" } },
      "required": ["satisfies"]
    }
  }
}
```

<!-- markdownlint-restore MD013 MD024 -->

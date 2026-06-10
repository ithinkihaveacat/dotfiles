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
- [Image Encoding](#image-encoding) - Platform-specific encoding details
- [Request Structure](#request-structure) - API request patterns

______________________________________________________________________

## screenshot-describe

Generate a text description of a screenshot using the Gemini API.

### Synopsis

```bash
scripts/screenshot-describe [OPTIONS] [IMAGE] [PROMPT]
```

### Arguments

| Argument | Description                                                                                 |
| -------- | ------------------------------------------------------------------------------------------- |
| `IMAGE`  | Path to a screenshot (any format supported by ImageMagick), or `-` for stdin (default: `-`) |
| `PROMPT` | Custom prompt for the AI model (optional)                                                   |

### Options

| Option          | Description                                       |
| --------------- | ------------------------------------------------- |
| `--help`        | Display help message and exit                     |
| `--model MODEL` | Gemini model to use (default: `gemini-3.5-flash`) |

### Environment Variables

| Variable         | Required | Description                             |
| ---------------- | -------- | --------------------------------------- |
| `GEMINI_API_KEY` | Yes      | Your Gemini API key                     |
| `GEMINI_MODEL`   | No       | Default model if `--model` is not given |

### Examples

```bash
# Basic usage with default prompt
scripts/screenshot-describe screenshot.png

# Custom prompt for specific analysis
scripts/screenshot-describe ui-mockup.png "List all UI elements visible"

# Analyze login screen
scripts/screenshot-describe login-screen.png "What objects are in this image?"
```

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

### Exit Codes

| Code | Description                                   |
| ---- | --------------------------------------------- |
| 0    | Success                                       |
| 1    | General error (API error, missing file, etc.) |
| 127  | Missing required dependency                   |

______________________________________________________________________

## screenshot-compare

Compare two screenshots using the Gemini API to identify visual differences.

### Synopsis

```bash
scripts/screenshot-compare IMAGE1 IMAGE2 [PROMPT]
```

### Arguments

| Argument | Description                                                        |
| -------- | ------------------------------------------------------------------ |
| `IMAGE1` | Path to the first screenshot (baseline/before), or `-` for stdin   |
| `IMAGE2` | Path to the second screenshot (comparison/after), or `-` for stdin |
| `PROMPT` | Custom prompt for the AI model (optional)                          |

Only one of `IMAGE1`/`IMAGE2` may be `-`.

### Options

| Option          | Description                                       |
| --------------- | ------------------------------------------------- |
| `--help`        | Display help message and exit                     |
| `--version`     | Display version number and exit                   |
| `--model MODEL` | Gemini model to use (default: `gemini-3.5-flash`) |

### Environment Variables

| Variable         | Required | Description                             |
| ---------------- | -------- | --------------------------------------- |
| `GEMINI_API_KEY` | Yes      | Your Gemini API key                     |
| `GEMINI_MODEL`   | No       | Default model if `--model` is not given |

### Examples

```bash
# Basic comparison
scripts/screenshot-compare before.png after.png

# Check for specific changes
scripts/screenshot-compare v1-header.png v2-header.png "Check for font size changes in the header"

# Compare UI states
scripts/screenshot-compare production-capture.png ui-mockup.png
```

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

### Exit Codes

| Code | Description                                                               |
| ---- | ------------------------------------------------------------------------- |
| 0    | Success (differences found and described)                                 |
| 1    | General error (API error, usage, missing file, missing ImageMagick, etc.) |
| 2    | Images are identical (no differences to describe)                         |

______________________________________________________________________

## photo-smart-crop

Smart crop images around the primary subject (people, food, focal points in a
landscape) detected via the Gemini API.

### Synopsis

```bash
scripts/photo-smart-crop [OPTIONS] INPUT OUTPUT
```

### Arguments

| Argument | Description                                               |
| -------- | --------------------------------------------------------- |
| `INPUT`  | Path to input image (any format supported by ImageMagick) |
| `OUTPUT` | Path for cropped output image                             |

### Options

| Option          | Description                                       |
| --------------- | ------------------------------------------------- |
| `--ratio W:H`   | Aspect ratio for crop (default: 5:3)              |
| `--model MODEL` | Gemini model to use (default: `gemini-3.5-flash`) |
| `--help`        | Display help message and exit                     |

### Environment Variables

| Variable         | Required | Description                             |
| ---------------- | -------- | --------------------------------------- |
| `GEMINI_API_KEY` | Yes      | Your Gemini API key                     |
| `GEMINI_MODEL`   | No       | Default model if `--model` is not given |

### Examples

```bash
# Default 5:3 aspect ratio
scripts/photo-smart-crop family.jpg family-cropped.jpg

# 16:9 for video thumbnails
scripts/photo-smart-crop --ratio 16:9 portrait.jpg landscape-16x9.jpg

# Square crop for profile pictures
scripts/photo-smart-crop --ratio 1:1 headshot.png avatar.png

# 4:3 standard photo ratio
scripts/photo-smart-crop --ratio 4:3 ~/Photos/vacation.jpg ./output/vacation-4x3.jpg
```

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

### Exit Codes

| Code | Description                                        |
| ---- | -------------------------------------------------- |
| 0    | Success (cropped output written)                   |
| 1    | Error (API error, invalid arguments, missing file) |
| 2    | Rate limited (API returned 429)                    |
| 127  | Missing required dependency                        |

______________________________________________________________________

## photo-query

Ask Gemini a question about one or more photos. The QUERY positional is either
an `@`-prefixed built-in (e.g. `@people`) or a free-form prompt; built-ins ship
with their own prompt, schema, and tuned defaults. Image pre-processing (EXIF
rotation, alpha flatten, resize, WebP encode) is content-addressed-cached so
repeated queries against the same images skip all redundant work.

### Synopsis

```bash
scripts/photo-query [OPTIONS] QUERY FILE_OR_DIR [FILE_OR_DIR ...]
```

### Built-in queries

| Name      | Description                                                   |
| --------- | ------------------------------------------------------------- |
| `@people` | Do people feature prominently? Boolean. 384px resize default. |

### Arguments

| Argument      | Description                                                                    |
| ------------- | ------------------------------------------------------------------------------ |
| `QUERY`       | `@name` built-in, or free-form prompt text.                                    |
| `FILE_OR_DIR` | One or more image files, or directories (top-level only unless `--recursive`). |

### Options

| Option           | Description                                                                                                                     |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| `--max-size N`   | Longest-edge resize cap, px. Default: 768 (built-ins may use a smaller default, e.g. 384 for `@people`).                        |
| `--model M`      | Override Gemini model (default: `$GEMINI_MODEL` if set, else `gemini-3.1-flash-lite` — cheapest/fastest Gemini 3 tier).         |
| `--no-cache`     | Skip the resize cache and re-process every image.                                                                               |
| `--recursive`    | Recurse into directory arguments (`*.{jpg,jpeg,png,webp,heic,heif}`).                                                           |
| `--schema SPEC`  | llm-style DSL: comma-separated `name [type] [: description]`. Types: `bool`, `int`, `float`, `str`. Not allowed with built-ins. |
| `--filter FIELD` | Print only paths whose boolean FIELD is true (requires a schema, built-in or `--schema`).                                       |
| `-v, --verbose`  | In single-file boolean mode, echo `true`/`false` to **stderr**.                                                                 |
| `--help`         | Display help and exit.                                                                                                          |

### Environment Variables

| Variable         | Required | Description                             |
| ---------------- | -------- | --------------------------------------- |
| `GEMINI_API_KEY` | Yes      | Your Gemini API key                     |
| `GEMINI_MODEL`   | No       | Default model if `--model` is not given |

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

### Synopsis

```bash
scripts/oracle [OPTIONS] "PROMPT" [FILE_OR_DIR ...]
```

### Arguments

| Argument      | Description                                                                                                                                           |
| ------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| `PROMPT`      | The research question, analysis goal, or refactoring plan. Must be exhaustive and self-contained.                                                     |
| `FILE_OR_DIR` | Arbitrary files and directories. Directories are recursively walked, and media files are uploaded automatically. Pass `-` to read context from stdin. |

### Options

| Option           | Description                                                                       |
| ---------------- | --------------------------------------------------------------------------------- |
| `--force`        | Bypass context size limits (1MB for text, 20MB per media file)                    |
| `--maps`         | Use Google Maps grounding instead of Google Search (cannot combine with `--code`) |
| `--code`         | Enable Code Execution for Python                                                  |
| `--dry-run`      | Summarize the payload (files, sizes, prompt) without calling the API              |
| `--model MODEL`  | Gemini model to use (default: `gemini-3.1-pro-preview`)                           |
| `--serialize`    | Save the self-contained payload to the cache (default: on)                        |
| `--no-serialize` | Disable saving the payload to the cache                                           |
| `--help`         | Display help message and exit                                                     |

### Environment Variables

| Variable         | Required | Description                             |
| ---------------- | -------- | --------------------------------------- |
| `GEMINI_API_KEY` | Yes      | Your Gemini API key                     |
| `GEMINI_MODEL`   | No       | Default model if `--model` is not given |

### Examples

```bash
# Evaluate an architectural pattern
scripts/oracle "Evaluate this implementation against solid principles." src/

# Time-sensitive research based on context
scripts/oracle "What are the latest developments in this framework as of May 2026?" framework-docs.md
```

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

### Synopsis

```bash
scripts/emerson [OPTIONS] "PROMPT" < INPUT_FILE
```

### Arguments

| Argument | Description                      |
| -------- | -------------------------------- |
| `PROMPT` | The question or topic to address |

### Input

| Source  | Description                                       |
| ------- | ------------------------------------------------- |
| `stdin` | Reference material (text) to use for the response |

### Options

| Option          | Description                                             |
| --------------- | ------------------------------------------------------- |
| `--help`        | Display help message and exit                           |
| `--model MODEL` | Gemini model to use (default: `gemini-3.1-pro-preview`) |

### Environment Variables

| Variable         | Required | Description                             |
| ---------------- | -------- | --------------------------------------- |
| `GEMINI_API_KEY` | Yes      | Your Gemini API key                     |
| `GEMINI_MODEL`   | No       | Default model if `--model` is not given |

### Examples

```bash
# Summarize documentation
cat documentation.md | scripts/emerson "Summarize the key architectural changes"

# Context-aware analysis
scripts/context gemini-api | scripts/emerson "Explain the key features"

# Analyze release notes
scripts/emerson "Explain the new features" < release_notes.txt

# Generate report from API spec
scripts/emerson "What are the breaking changes?" < api-spec.md
```

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

### Exit Codes

| Code | Description                               |
| ---- | ----------------------------------------- |
| 0    | Success                                   |
| 1    | General error (API error, no input, etc.) |
| 127  | Missing required dependency               |

______________________________________________________________________

## pascal

Asks a question to the Gemini 3 Flash model and prints a short, paragraph-style
response (wrapped to 80 columns).

### Synopsis

```bash
scripts/pascal [OPTIONS] [-] PROMPT
```

### Arguments

| Argument | Description                                       |
| -------- | ------------------------------------------------- |
| `-`      | Read context from stdin (must precede the prompt) |
| `PROMPT` | The question to ask.                              |

### Input

| Source  | Description                                                                                 |
| ------- | ------------------------------------------------------------------------------------------- |
| `stdin` | Optional context to include with the question. Only read when `-` is passed as an argument. |

### Options

| Option          | Description                                       |
| --------------- | ------------------------------------------------- |
| `--help`        | Display help message and exit                     |
| `--model MODEL` | Gemini model to use (default: `gemini-3.5-flash`) |

### Environment Variables

| Variable         | Required | Description                             |
| ---------------- | -------- | --------------------------------------- |
| `GEMINI_API_KEY` | Yes      | Your Gemini API key                     |
| `GEMINI_MODEL`   | No       | Default model if `--model` is not given |

### Examples

```bash
# Ask a question
scripts/pascal "What is the capital of Peru?"

# Summarize an article (note the '-' to read stdin)
cat article.md | scripts/pascal - "Summarize this article"
```

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

### Exit Codes

| Code | Description                 |
| ---- | --------------------------- |
| 0    | Success                     |
| 1    | General error               |
| 127  | Missing required dependency |

______________________________________________________________________

## context

Generate aggregated context for various topics (e.g., `gemini-api`,
`gemini-cli`) by fetching data from GitHub or local execution. Run
`scripts/context --list` to see all available topics. Outputs XML format
suitable for `emerson`.

**Note:** The output is often extremely large. Agents should **not** consume
this output directly. Instead, pipe it to `emerson` for analysis, or redirect it
to a file to search locally.

### Synopsis

```bash
scripts/context TOPIC
scripts/context --list
```

### Arguments

| Argument | Description                                  |
| -------- | -------------------------------------------- |
| `TOPIC`  | The topic to generate context for (required) |

### Options

| Option              | Description                                    |
| ------------------- | ---------------------------------------------- |
| `--list`            | List available topics (names only)             |
| `--force`           | Force cache rebuild                            |
| `--plugin-template` | Output a template for creating a Python plugin |
| `--help`            | Display help message and exit                  |

### Environment Variables

None required. (Uses `curl`, `jq`, `python3`)

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

### Synopsis

```bash
echo "text" | scripts/satisfies [OPTIONS] "CONDITION"
```

### Arguments

| Argument    | Description                                             |
| ----------- | ------------------------------------------------------- |
| `CONDITION` | The condition or question to evaluate against the input |

### Input

| Source  | Description              |
| ------- | ------------------------ |
| `stdin` | Text content to evaluate |

### Options

| Option          | Description                                            |
| --------------- | ------------------------------------------------------ |
| `-v, --verbose` | Output "true" or "false" to stderr                     |
| `--model MODEL` | Gemini model to use (default: `gemini-2.5-flash-lite`) |
| `--help`        | Display help message and exit                          |

### Environment Variables

| Variable         | Required | Description                             |
| ---------------- | -------- | --------------------------------------- |
| `GEMINI_API_KEY` | Yes      | Your Gemini API key                     |
| `GEMINI_MODEL`   | No       | Default model if `--model` is not given |

### Examples

```bash
# Check if text mentions a topic
cat file.txt | scripts/satisfies "mentions Elvis"

# Use in shell conditionals
if cat log.txt | scripts/satisfies "contains error messages"; then
  echo "Errors detected"
fi

# Validate content
cat response.json | scripts/satisfies "is valid JSON with an 'id' field"

# Chain with other commands
cat README.md | scripts/satisfies "has installation instructions" && echo "Ready to use"
```

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

### Exit Codes

| Code | Description                                  |
| ---- | -------------------------------------------- |
| 0    | True (input satisfies the condition)         |
| 1    | False (input does not satisfy the condition) |
| 127  | Missing required dependency                  |

______________________________________________________________________

## token-count

Count tokens in text using the Gemini API's countTokens endpoint.

### Synopsis

```bash
cat file.txt | scripts/token-count
echo "text" | scripts/token-count
```

### Options

| Option          | Description                                       |
| --------------- | ------------------------------------------------- |
| `--help`        | Display help message and exit                     |
| `--model MODEL` | Gemini model to use (default: `gemini-2.0-flash`) |

### Environment Variables

| Variable         | Required | Description                             |
| ---------------- | -------- | --------------------------------------- |
| `GEMINI_API_KEY` | Yes      | Your Gemini API key                     |
| `GEMINI_MODEL`   | No       | Default model if `--model` is not given |

### Examples

```bash
# Count tokens in a file
cat document.md | scripts/token-count

# Count tokens in a string
echo "The quick brown fox" | scripts/token-count

# Count tokens across multiple files
cat *.md | scripts/token-count
```

### Exit Codes

| Code | Description                    |
| ---- | ------------------------------ |
| 0    | Success (outputs token count)  |
| 1    | Error (empty input, API error) |
| 127  | Missing required dependency    |

______________________________________________________________________

## popper

Interact with Android UIs using an AI agent powered by `uiautomator2` and
Gemini. This allows semantic control of the device by providing a goal in
natural language.

### Synopsis

```bash
scripts/popper [OPTIONS] "GOAL"
```

### Arguments

| Argument | Required | Description                                                                          |
| -------- | -------- | ------------------------------------------------------------------------------------ |
| `GOAL`   | Yes      | The natural language goal for the agent to achieve (not needed with `--dump-layout`) |

### Options

| Option                                           | Description                                                                                                                                 |
| ------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------- |
| `--launch PACKAGE`                               | Launch the specified package before starting.                                                                                               |
| `--stay-in-app`                                  | Restrict the agent to a single application package for the entire run. If used with `--launch`, that launched package becomes the boundary. |
| `--timeout SEC`                                  | Maximum execution time in seconds (default: 180). Exits with code `2` on timeout.                                                           |
| `--output-format`                                | Output format: `text` or `stream-json` (NDJSON telemetry to stdout).                                                                        |
| `--agent-screenshots` / `--no-agent-screenshots` | Enable/disable transmitting screenshots to the Gemini API (default: enabled).                                                               |
| `--local-screenshots` / `--no-local-screenshots` | Enable/disable saving debug screenshots to local disk (default: enabled).                                                                   |
| `--local-screenshot-dir DIR`                     | Directory for step-by-step debug screenshots (default: `XDG_RUNTIME_DIR/popper` or tmp).                                                    |
| `--output-dir DIR`                               | Directory for screenshots explicitly requested by the agent (default: current directory).                                                   |
| `--model MODEL`                                  | Gemini model to use (default: `gemini-3.5-flash`).                                                                                          |
| `--dump-layout`                                  | Print the current simplified UI layout as JSON and exit.                                                                                    |
| `--help`                                         | Display help message and exit.                                                                                                              |

### Environment Variables

| Variable         | Required | Description                               |
| ---------------- | -------- | ----------------------------------------- |
| `GEMINI_API_KEY` | Yes      | Your Gemini API key                       |
| `GEMINI_MODEL`   | No       | Default model if `--model` is not given   |
| `ANDROID_SERIAL` | No       | Target a specific Android device/emulator |

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

_This script delegates complex control flow, image capture, XML parsing, and
planning to a python script (`uv run --script`). It cannot be reasonably reduced
to a single curl command. Please see `scripts/popper` for the implementation
details._

### Exit Codes

| Code | Description              |
| ---- | ------------------------ |
| 0    | Success (task completed) |
| 1    | Error (task failed)      |
| 2    | Timed out                |

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

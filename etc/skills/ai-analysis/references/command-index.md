# Command Index

## Contents

- [screenshot-describe](#screenshot-describe) - Generate alt-text from images
- [screenshot-compare](#screenshot-compare) - Compare two images for differences
- [photo-smart-crop](#photo-smart-crop) - Smart crop around detected people
- [emerson](#emerson) - Generate essay-length analysis from text
- [pascal](#pascal) - Ask a question and get a short response
- [context](#context) - Generate aggregated context for analysis
- [satisfies](#satisfies) - Evaluate boolean conditions against text
- [token-count](#token-count) - Count tokens in text
- [Image Encoding](#image-encoding) - Platform-specific encoding details
- [Request Structure](#request-structure) - API request patterns

---

## screenshot-describe

Generate a text description of a screenshot using the Gemini API.

### Synopsis

```bash
scripts/screenshot-describe IMAGE [PROMPT]
```

### Arguments

| Argument | Description                                                |
| -------- | ---------------------------------------------------------- |
| `IMAGE`  | Path to a screenshot (any format supported by ImageMagick) |
| `PROMPT` | Custom prompt for the AI model (optional)                  |

### Options

| Option       | Description                   |
| ------------ | ----------------------------- |
| `-h, --help` | Display help message and exit |

### Environment Variables

| Variable         | Required | Description         |
| ---------------- | -------- | ------------------- |
| `GEMINI_API_KEY` | Yes      | Your Gemini API key |

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

Model: `gemini-2.5-flash`

```bash
IMAGE_BASE64=$(magick image.png -alpha off -define webp:lossless=true webp:- | base64 -w 0)

curl -s -X POST \
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent" \
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

---

## screenshot-compare

Compare two screenshots using the Gemini API to identify visual differences.

### Synopsis

```bash
scripts/screenshot-compare IMAGE1 IMAGE2 [PROMPT]
```

### Arguments

| Argument | Description                                      |
| -------- | ------------------------------------------------ |
| `IMAGE1` | Path to the first screenshot (baseline/before)   |
| `IMAGE2` | Path to the second screenshot (comparison/after) |
| `PROMPT` | Custom prompt for the AI model (optional)        |

### Options

| Option       | Description                   |
| ------------ | ----------------------------- |
| `-h, --help` | Display help message and exit |

### Environment Variables

| Variable         | Required | Description         |
| ---------------- | -------- | ------------------- |
| `GEMINI_API_KEY` | Yes      | Your Gemini API key |

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

Model: `gemini-3-flash-preview`

```bash
IMG1_B64=$(magick before.png -alpha off -define webp:lossless=true webp:- | base64 -w 0)
IMG2_B64=$(magick after.png -alpha off -define webp:lossless=true webp:- | base64 -w 0)

curl -s -X POST \
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent" \
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

| Code | Description                                          |
| ---- | ---------------------------------------------------- |
| 0    | Success (differences found and described)            |
| 1    | General error (API error, usage, missing file, etc.) |
| 2    | Images are identical (no differences to describe)    |
| 127  | Missing required dependency                          |

---

## photo-smart-crop

Smart crop images around detected people using Gemini API for face detection.

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

| Option        | Description                          |
| ------------- | ------------------------------------ |
| `--ratio W:H` | Aspect ratio for crop (default: 5:3) |
| `-h, --help`  | Display help message and exit        |

### Environment Variables

| Variable         | Required | Description         |
| ---------------- | -------- | ------------------- |
| `GEMINI_API_KEY` | Yes      | Your Gemini API key |

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

1. Detects all people in the image using Gemini vision API
2. Calculates bounding box around all detected faces (prioritizes heads over
   bodies)
3. Expands box by 20% for headroom
4. Adjusts to match the requested aspect ratio
5. If full body cannot fit, crops from bottom (preserving heads)
6. Applies crop using ImageMagick with auto-orient for EXIF handling

### Exit Codes

| Code | Description                                                         |
| ---- | ------------------------------------------------------------------- |
| 0    | Success (cropped output written)                                    |
| 1    | Error (no people found, API error, invalid arguments, missing file) |
| 2    | Rate limited (API returned 429)                                     |
| 127  | Missing required dependency                                         |

---

## emerson

Generate essay-length (~3000 words) analysis from text input using Gemini 3 Pro.

### Synopsis

```bash
scripts/emerson "PROMPT" < INPUT_FILE
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

| Option       | Description                   |
| ------------ | ----------------------------- |
| `-h, --help` | Display help message and exit |

### Environment Variables

| Variable         | Required | Description         |
| ---------------- | -------- | ------------------- |
| `GEMINI_API_KEY` | Yes      | Your Gemini API key |

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

Model: `gemini-3-pro-preview`

```bash
INPUT_TEXT=$(cat document.txt)
PROMPT="Summarize the key points"

curl -s -X POST \
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-pro-preview:generateContent" \
  -H "x-goog-api-key: $GEMINI_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$(jq -n \
    --arg text "$INPUT_TEXT" \
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

---

## pascal

Asks a question to the Gemini 3 Flash model and prints a short, paragraph-style
response (wrapped to 80 columns).

### Synopsis

```bash
scripts/pascal PROMPT
```

### Arguments

| Argument | Description          |
| -------- | -------------------- |
| `PROMPT` | The question to ask. |

### Input

| Source  | Description                                    |
| ------- | ---------------------------------------------- |
| `stdin` | Optional context to include with the question. |

### Options

| Option       | Description                   |
| ------------ | ----------------------------- |
| `-h, --help` | Display help message and exit |

### Environment Variables

| Variable         | Required | Description         |
| ---------------- | -------- | ------------------- |
| `GEMINI_API_KEY` | Yes      | Your Gemini API key |

### Examples

```bash
# Ask a question
scripts/pascal "What is the capital of Peru?"

# Summarize an article
cat article.md | scripts/pascal "Summarize this article"
```

### Raw API Command

Model: `gemini-3-flash-preview`

```bash
PROMPT="What is the capital of Peru?"
SYSTEM_INSTRUCTION="You are a helpful assistant. Provide a short, direct answer \
(less than 300 characters) in a single full paragraph. Do not use point form, \
lists, or markdown formatting (like bold or headers). Just plain text."

curl -s -X POST \
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent" \
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

---

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

| Option       | Description                   |
| ------------ | ----------------------------- |
| `--list`     | List available topics         |
| `-h, --help` | Display help message and exit |

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

---

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

| Option          | Description                        |
| --------------- | ---------------------------------- |
| `-v, --verbose` | Output "true" or "false" to stderr |
| `-h, --help`    | Display help message and exit      |

### Environment Variables

| Variable         | Required | Description         |
| ---------------- | -------- | ------------------- |
| `GEMINI_API_KEY` | Yes      | Your Gemini API key |

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
INPUT_TEXT=$(cat file.txt)
CONDITION="mentions Elvis"

RESPONSE=$(curl -s -X POST \
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent" \
  -H "x-goog-api-key: $GEMINI_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$(jq -n \
    --arg input "$INPUT_TEXT" \
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

---

## token-count

Count tokens in text using the Gemini API's countTokens endpoint.

### Synopsis

```bash
cat file.txt | scripts/token-count
echo "text" | scripts/token-count
```

### Environment Variables

| Variable         | Required | Description         |
| ---------------- | -------- | ------------------- |
| `GEMINI_API_KEY` | Yes      | Your Gemini API key |

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

---

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
2. Remove alpha channel (`-alpha off`)
3. Encode to base64 (single line)

```bash
# Full encoding command
magick input.png -alpha off -define webp:lossless=true webp:- | base64 -w 0
```

### Why WebP?

- Lossless compression preserves detail for accurate analysis
- Consistent encoding across different input formats
- Smaller payload than uncompressed formats

### Alpha Channel Removal

The `-alpha off` flag removes transparency. Images differing only in alpha
channel are treated as identical. This is intentional for comparing visual
appearance on an opaque background.

---

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

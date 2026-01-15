---
name: screenshot
description: >
  Analyzes screenshots using AI vision models. Generates alt-text descriptions
  for accessibility, compares screenshots to identify UI differences, and
  produces essay-length analysis from text input. Use when describing images,
  comparing UI states, generating accessibility text, or analyzing visual
  changes between screenshots. Triggers: screenshot, screenshot analysis,
  compare screenshots, describe screenshot, alt text, image description, UI
  comparison, visual diff, gemini vision, screenshot diff.
compatibility: >
  Requires curl, jq, base64, magick (ImageMagick). Needs GEMINI_API_KEY
  environment variable and network access to generativelanguage.googleapis.com.
---

# Screenshot Analysis

## Quick Start

**Environment:** Set `GEMINI_API_KEY` before running any commands.

**Dependencies:** `curl`, `jq`, `base64`, `magick` (ImageMagick)

```bash
# Describe a screenshot (generate alt-text)
scripts/screenshot-describe screenshot.png

# Compare two screenshots for UI differences
scripts/screenshot-compare before.png after.png

# Generate essay-length analysis from text
scripts/emerson "Summarize the key changes" < documentation.md
```

## Script Overview

### screenshot-describe

Generate concise alt-text for a screenshot. Optimized for UI captures.

```bash
scripts/screenshot-describe IMAGE [PROMPT]
```

**Options:**
- `-h, --help` - Display help

**Exit codes:** 0 success, 1 error, 127 missing dependency

### screenshot-compare

Compare two screenshots for visual differences. Identifies layout shifts, color changes, padding, and text updates.

```bash
scripts/screenshot-compare IMAGE1 IMAGE2 [PROMPT]
```

**Options:**
- `-h, --help` - Display help

**Exit codes:** 0 differences found, 1 error, 2 images identical, 127 missing dependency

### emerson

Generate essay-length (~3000 words) analysis from text input. Produces authoritative, footnoted Markdown.

```bash
scripts/emerson "PROMPT" < input.txt
```

**Options:**
- `-h, --help` - Display help

**Exit codes:** 0 success, 1 error, 127 missing dependency

## Raw API Fallback

When scripts fail due to missing dependencies or environment issues, use these curl commands directly.

### Describing a Screenshot

Model: `gemini-2.5-flash`

```bash
# Encode image to base64 webp
IMAGE_BASE64=$(magick image.png -alpha off -define webp:lossless=true webp:- | base64 -w 0)

# API request
curl -s -X POST \
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent" \
  -H "x-goog-api-key: $GEMINI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "contents": [{
      "parts": [
        {"inlineData": {"mimeType": "image/webp", "data": "'"$IMAGE_BASE64"'"}},
        {"text": "Generate concise alt text describing this screenshot."}
      ]
    }]
  }' | jq -r '.candidates[0].content.parts[0].text'
```

### Comparing Two Screenshots

Model: `gemini-3-flash-preview`

```bash
# Encode both images
IMG1_B64=$(magick before.png -alpha off -define webp:lossless=true webp:- | base64 -w 0)
IMG2_B64=$(magick after.png -alpha off -define webp:lossless=true webp:- | base64 -w 0)

# API request (text before images for comparison tasks)
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

### Text Analysis (Emerson-style)

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

## Image Encoding Notes

- Images converted to lossless WebP for consistent encoding
- Alpha channel removed (`-alpha off`) so transparency-only differences are ignored
- Base64: use `-w 0` (Linux) or `-b 0` (macOS) for single-line output
- Single-image prompts: image before text (Gemini best practice)
- Multi-image comparison: text before images (Gemini best practice)

## Safety Notes

- Scripts require network access to the Gemini API
- `GEMINI_API_KEY` must be set in the environment
- API calls may incur usage costs
- Large images increase request size and latency
- Scripts do not store or log images

## References

- [Command Index](references/command-index.md) - Detailed documentation for each script
- [Troubleshooting](references/troubleshooting.md) - Common issues and solutions

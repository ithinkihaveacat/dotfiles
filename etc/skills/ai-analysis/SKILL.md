---
name: ai-analysis
description: >
  Command-line tools that delegate analysis tasks to AI models. Includes image
  description, screenshot comparison, essay generation from text, and boolean
  condition evaluation. Use for describing images, comparing UI states,
  generating reports, evaluating conditions, or any task requiring AI inference.
  Triggers: ai analysis, describe image, compare screenshots, generate essay,
  evaluate condition, alt text, image description, UI comparison, visual diff,
  satisfies condition, boolean evaluation, gemini.
compatibility: >
  Requires curl and jq. Image tools also need base64 and magick (ImageMagick).
  Needs GEMINI_API_KEY environment variable and network access to
  generativelanguage.googleapis.com.
---

# AI Analysis Tools

## Important: Use Scripts First

**ALWAYS prefer the scripts in `scripts/` over raw `curl` API calls.** Scripts
are located in the `scripts/` subdirectory of this skill's folder. They provide
features that raw commands do not:

- Proper image encoding (WebP conversion, alpha removal)
- Appropriate model selection for each task
- Structured output handling (boolean responses via exit codes)
- Meaningful exit codes for shell integration

**When to read the script source:** If a script doesn't do exactly what you
need, or fails due to missing dependencies, read the script source. The scripts
encode Gemini API best practices (image ordering, structured output schemas,
model selection) that may not be obvious—use them as reference when building
similar functionality.

## Quick Start

**Environment:** Set `GEMINI_API_KEY` before running any commands.

**Dependencies:** `curl`, `jq` (all tools); `base64`, `magick` (image tools
only)

```bash
# Describe an image (generate alt-text)
scripts/screenshot-describe screenshot.png

# Compare two images for visual differences
scripts/screenshot-compare before.png after.png

# Generate essay-length analysis from text
scripts/emerson "Summarize the key changes" < documentation.md

# Evaluate a boolean condition against text
echo "Hello world" | scripts/satisfies "is a greeting"
```

## Script Overview

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

**Exit codes:** 0 differences found, 1 error, 2 images identical, 127 missing
dependency

### emerson

Generate essay-length (~3000 words) analysis from text input. Produces
authoritative, footnoted Markdown.

```bash
scripts/emerson "PROMPT" < input.txt
```

**Exit codes:** 0 success, 1 error, 127 missing dependency

### satisfies

Evaluate whether input text satisfies a condition. Returns boolean via exit
code.

```bash
echo "text" | scripts/satisfies "CONDITION"
```

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

## Image Encoding Notes

- Images converted to lossless WebP for consistent encoding
- Alpha channel removed (`-alpha off`) so transparency-only differences are
  ignored
- Base64: use `-w 0` (Linux) or `-b 0` (macOS) for single-line output
- Single-image prompts: image before text (Gemini best practice)
- Multi-image comparison: text before images (Gemini best practice)

## Safety Notes

- Scripts require network access to the Gemini API
- `GEMINI_API_KEY` must be set in the environment
- API calls may incur usage costs
- Large images increase request size and latency
- Scripts do not store or log input data

## References

- [Command Index](references/command-index.md) - Detailed documentation for each
  script
- [Troubleshooting](references/troubleshooting.md) - Common issues and solutions

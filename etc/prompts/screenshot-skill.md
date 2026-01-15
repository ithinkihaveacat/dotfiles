# Prompt: Create Screenshot Analysis Skill

Create an Agent Skill that helps agents analyze screenshots and generate text
content using AI vision and language models. This skill should document the
screenshot analysis and text generation scripts and provide both script-first
and raw-API-fallback approaches.

## Goal

Produce a self-contained skill directory at `etc/skills/screenshot/` that an
agent can use to:

1. Run the bundled scripts directly (fast, deterministic)
2. When scripts fail (missing dependencies, environment issues), use raw `curl`
   commands to call the Gemini API as an authoritative fallback

## Research Phase

Before creating files, research the following:

1. **Review the Agent Skills specification and best practices**:
   - Specification: <https://agentskills.io/specification.md>
   - Best practices: <https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices>

2. **Examine the AI-powered scripts thoroughly**:
   - `bin/screenshot-describe` - Generate alt-text/descriptions from screenshots
   - `bin/screenshot-compare` - Compare two screenshots for UI differences
   - `bin/emerson` - Generate essay-length analysis from text input

   For each script, understand:
   - Purpose and when to use it
   - Dependencies (look for `require` calls)
   - The underlying Gemini API calls and models used
   - Input/output format
   - Environment variables required (`GEMINI_API_KEY`)
   - Error conditions and exit codes

3. **Understand the Gemini API patterns**:
   - Image encoding (base64 webp)
   - Request body structure for vision vs text tasks
   - Single-image vs multi-image prompts
   - Model selection (flash vs pro)

## Deliverable Structure

Create this exact structure:

```text
etc/skills/screenshot/
├── SKILL.md              # Required: frontmatter + instructions
├── scripts/              # Copies of the AI-powered scripts
└── references/           # Reference documentation
    ├── command-index.md
    └── troubleshooting.md
```

Do not create extra files like README.md, CHANGELOG.md, or INSTALLATION.md.

## Script Selection

Symlink these scripts into `scripts/` using relative paths:

- `bin/screenshot-describe`
- `bin/screenshot-compare`
- `bin/emerson`

Preserve filenames and executable permissions.

### Transitive Script Dependencies

These scripts are self-contained and do not call other scripts from `bin/`. No
additional scripts need to be symlinked.

## SKILL.md Requirements

### Frontmatter

Follow the Agent Skills specification exactly:

```yaml
---
name: screenshot
description: [See below]
---
```

**Name requirements:**

- Lowercase letters, numbers, hyphens only
- Max 64 characters
- Must match directory name

**Description requirements (critical for discovery):**

- Max 1024 characters
- Write in **third person** (the description is injected into system prompts)
  - Good: "Analyzes screenshots..." / "Generates descriptions..."
  - Bad: "I can help you..." / "You can use this to..."
- Include what the skill does AND when to use it
- End with explicit trigger phrases using "Triggers:" prefix for reliable
  discovery across different agent implementations

Include these trigger phrases: screenshot, screenshot analysis, compare
screenshots, describe screenshot, alt text, image description, UI comparison,
visual diff, gemini vision, screenshot diff

Example pattern:

```yaml
description: >
  Analyzes screenshots using AI vision models. Generates alt-text descriptions
  for accessibility, compares screenshots to identify UI differences, and
  produces essay-length analysis from text input. Use when describing images,
  comparing UI states, generating accessibility text, or analyzing visual
  changes between screenshots. Triggers: screenshot, screenshot analysis,
  compare screenshots, describe screenshot, alt text, image description, UI
  comparison, visual diff.
```

**Compatibility requirements (recommended):**

- Max 500 characters
- Include if the skill has external dependencies or environment requirements
- Mention required command-line tools, network access needs, or target platforms
- Example: `compatibility: Requires curl, jq, base64, magick (ImageMagick). Needs GEMINI_API_KEY environment variable and network access to generativelanguage.googleapis.com.`

For maximum compatibility across skill loaders, prefer a single-line
`description:` value and avoid YAML block scalars like `description: |` (some
implementations treat multi-line descriptions inconsistently). If you need line
wrapping, prefer a folded scalar (`description: >`) rather than a literal block
(`description: |`).

### Body Content

Keep the body under 500 lines. Structure it for progressive disclosure—agents
load this only when the skill activates, so be concise.

**Degrees of Freedom:** Match specificity to task fragility:

- **Low freedom** (exact commands): Use for fragile operations like API calls
  with specific request formats
- **High freedom** (guidance): Use for flexible tasks like choosing prompts

For screenshot analysis, most operations are deterministic (run this exact
command), so prefer low-freedom documentation with specific commands.

#### Quick Start

- Environment: `GEMINI_API_KEY` required
- Dependencies: `curl`, `jq`, `base64`, `magick` (ImageMagick)
- 3-4 highest-value commands to run first:
  - `scripts/screenshot-describe image.png` (generate alt-text)
  - `scripts/screenshot-compare before.png after.png` (find UI differences)
  - `scripts/emerson "Question" < document.txt` (essay-length analysis)
- Use paths relative to the skill: `scripts/screenshot-describe`

#### Script Overview

A compact reference for each script. For each, provide:

- **Purpose** (1-2 lines)
- **Basic usage**
- **Key options**
- **Exit codes**

Scripts to document:

1. **screenshot-describe** - Generate concise alt-text for a screenshot
   - Optimized for UI captures; default prompt focuses on elements, text, colors
   - Supports custom prompts for specific analysis needs
   - Uses gemini-2.5-flash model

2. **screenshot-compare** - Compare two screenshots for visual differences
   - Identifies layout shifts, color changes, padding, text updates
   - Detailed paragraph-form output for UI QA
   - Uses gemini-3-flash-preview model
   - Exit code 2 when images are identical

3. **emerson** - Generate essay-length (~3000 words) analysis from text input
   - Reads reference material from stdin
   - Produces authoritative, footnoted Markdown output
   - Uses gemini-3-pro-preview model

#### Model Selection

Document which models each script uses and why:

- `gemini-2.5-flash` - Fast, efficient for single-image description
- `gemini-3-flash-preview` - Balanced speed/quality for image comparison
- `gemini-3-pro-preview` - High quality for long-form text generation

#### Raw API Fallback

This is critical. Teach agents how to perform operations manually when scripts
don't work:

1. Show the Gemini API endpoint pattern
2. Explain image encoding requirements
3. Provide curl commands for each operation

Include worked examples:

##### Describing a Screenshot

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

##### Comparing Two Screenshots

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

##### Text Analysis with Emerson

```bash
# Read input and construct request
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

#### Image Encoding Notes

Document the image encoding conventions:

- Images are converted to lossless WebP for consistent encoding
- Alpha channel is removed (`-alpha off`) so images differing only in
  transparency are treated as identical
- Base64 encoding uses `-w 0` (Linux) or `-b 0` (macOS) for single-line output
- Image is placed before text for single-image prompts (Gemini best practice)
- Text is placed before images for multi-image comparison (Gemini best practice)

#### Safety Notes

- Scripts require network access to the Gemini API
- `GEMINI_API_KEY` must be set in the environment
- API calls may incur usage costs
- Large images increase request size and latency
- The scripts do not store or log images

## Reference Files

### references/command-index.md

If this file is longer than 100 lines, include a `## Contents` section at the
top (a short table of contents) so agents can see the full scope even when
previewing the file.

For each script, document:

- **Purpose** (1 line)
- **Synopsis** (usage pattern)
- **Arguments** (with descriptions)
- **Options** (flags and their effects)
- **Environment variables** (required and optional)
- **Examples** (2-3 practical examples)
- **Raw API commands** (the underlying curl commands)
- **Exit codes** (success/failure conditions)

Include a section on:

- **Gemini API models** used by each script
- **Image encoding** requirements and platform differences (macOS vs Linux)
- **Request structure** differences (image-first vs text-first)

### references/troubleshooting.md

If this file is longer than 100 lines, include a `## Contents` section at the
top (a short table of contents) so agents can see the full scope even when
previewing the file.

Cover:

- Missing `GEMINI_API_KEY` environment variable
- Missing dependencies (`curl`, `jq`, `base64`, `magick`)
- API errors (rate limits, invalid key, quota exceeded)
- Image file not found or unreadable
- Unsupported image format
- Images are identical (screenshot-compare exit code 2)
- No response text received from API
- Network connectivity issues
- Large image handling and timeouts
- Platform differences (macOS vs Linux base64 flags)

## Writing Guidelines

### Core Principle: Conciseness

The context window is shared with conversation history, other skills, and system
prompts. **Assume agents are already intelligent**—only provide information they
don't already know. Challenge each paragraph: "Does this justify its token
cost?"

Bad (verbose):
```markdown
Screenshots are image files that capture what is displayed on a screen. To
analyze a screenshot, you'll need to use an AI vision model...
```

Good (concise):
```markdown
Describe a screenshot:
```bash
scripts/screenshot-describe image.png
```

### Cross-Model Compatibility

Skills run on Claude (Haiku/Sonnet/Opus), Gemini CLI, and OpenAI Codex. Write
instructions that work across capability levels:

- Provide enough detail for simpler models (Haiku) to follow
- Don't over-explain for powerful models (Opus)
- Include explicit trigger phrases for reliable discovery
- Raw command fallbacks help when model-specific tool access varies

### Style

- Use imperative form ("Run this command" not "You can run this command")
- Include concrete examples with realistic filenames
- Document raw API commands prominently—they're essential fallbacks
- Keep file references one level deep from SKILL.md
- Avoid redundant sections

## Quality Checklist

Before finalizing, verify:

### Structure
- [ ] Skill directory exists at `etc/skills/screenshot/`
- [ ] `scripts/` contains symlinks to all three scripts
- [ ] Scripts are executable (`chmod +x`)
- [ ] No extraneous files (README.md, etc.)

### SKILL.md
- [ ] Valid frontmatter matching the spec
- [ ] Description is in third person
- [ ] Description ends with "Triggers:" and explicit keywords
- [ ] Compatibility field lists required tools and GEMINI_API_KEY
- [ ] Body is under 500 lines

### Content Coverage
- [ ] Both script-first AND raw-API-fallback approaches documented
- [ ] All three scripts documented (screenshot-describe, screenshot-compare, emerson)
- [ ] Gemini models explained (flash vs pro)
- [ ] Image encoding conventions documented
- [ ] Platform differences (macOS vs Linux) noted
- [ ] Examples use realistic filenames

### References
- [ ] `references/command-index.md` documents each script with raw API commands
- [ ] `references/troubleshooting.md` covers common issues
- [ ] Files over 100 lines have a Contents section

### Cross-Model Compatibility
- [ ] Instructions are clear enough for simpler models (Haiku)
- [ ] Instructions don't over-explain for powerful models (Opus)
- [ ] Raw commands provide fallback when tool access varies

## Implementation Notes

- Use `mkdir -p` to create directories
- Use `ln -s` to create relative symlinks (e.g.,
  `ln -s ../../../../bin/screenshot-describe scripts/screenshot-describe`)
- Verify executable bits with `chmod +x scripts/*` if needed
- Do not modify the original `bin/` scripts—only symlink into the skill
- Test that symlinked scripts work from the skill directory
- The scripts' `require` function checks for dependencies at runtime

## Example Filenames

Use these realistic examples throughout the documentation:

**Screenshots:**
- `screenshot.png`, `before.png`, `after.png`
- `login-screen.png`, `dashboard.png`
- `v1-header.png`, `v2-header.png`
- `ui-mockup.png`, `production-capture.png`

**Text files (for emerson):**
- `documentation.md`, `release_notes.txt`
- `api-spec.md`, `design-doc.txt`
- `meeting-notes.txt`, `research-paper.md`

# Prompt: Create AI Analysis Skill

Create an Agent Skill that helps agents perform AI-powered analysis tasks using
the Gemini API. This skill should document CLI tools that delegate to AI models
for image description, image comparison, text generation, and boolean
evaluation, and strongly encourage agents to use these scripts over raw API
calls.

## Goal

Produce a self-contained skill directory at `etc/skills/ai-analysis/` that an
agent can use to:

1. Run the bundled scripts directly (fast, deterministic, with proper error
   handling and model selection)
2. Only fall back to raw API calls when scripts fail due to missing dependencies

**Important:** The scripts provide significant value beyond raw curl commands
(e.g., proper image encoding, model selection, structured output handling,
meaningful exit codes). The skill must make agents prefer scripts by default and
only consult raw commands as a last resort by reading the script source.

## Research Phase

Before creating files, research the following:

1. **Review the Agent Skills specification and best practices**:
   - Specification: <https://agentskills.io/specification.md>
   - Best practices:
     <https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices>

2. **Examine the AI-powered scripts thoroughly**:
   - `bin/screenshot-describe` - Generate alt-text/descriptions from images
   - `bin/screenshot-compare` - Compare two images for visual differences
   - `bin/photo-smart-crop` - Smart crop images around detected people
   - `bin/emerson` - Generate essay-length analysis from text input
   - `bin/satisfies` - Evaluate boolean conditions against text input

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
   - Structured output for boolean responses

## Deliverable Structure

Create this exact structure:

```text
etc/skills/ai-analysis/
├── SKILL.md              # Required: frontmatter + instructions
├── scripts/              # Symlinks to the AI-powered scripts
└── references/           # Reference documentation
    ├── command-index.md
    └── troubleshooting.md
```

Do not create extra files like README.md, CHANGELOG.md, or INSTALLATION.md.

## Script Selection

Symlink these scripts into `scripts/` using relative paths:

- `bin/screenshot-describe`
- `bin/screenshot-compare`
- `bin/photo-smart-crop`
- `bin/emerson`
- `bin/satisfies`

Preserve filenames and executable permissions.

### Transitive Script Dependencies

These scripts are self-contained and do not call other scripts from `bin/`. No
additional scripts need to be symlinked.

## SKILL.md Requirements

### Frontmatter

Follow the Agent Skills specification exactly:

```yaml
---
name: ai-analysis
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
  - Good: "Analyzes images..." / "Evaluates conditions..."
  - Bad: "I can help you..." / "You can use this to..."
- Include what the skill does AND when to use it
- End with explicit trigger phrases using "Triggers:" prefix for reliable
  discovery across different agent implementations

Include these trigger phrases: ai analysis, describe image, compare screenshots,
smart crop, crop around people, face crop, generate essay, evaluate condition,
alt text, image description, UI comparison, visual diff, satisfies condition,
boolean evaluation, gemini

Example pattern:

```yaml
description: >
  Command-line tools that delegate analysis tasks to AI models. Includes image
  description, screenshot comparison, smart cropping around people, essay
  generation from text, and boolean condition evaluation. Use for describing
  images, comparing UI states, cropping photos around faces, generating reports,
  evaluating conditions, or any task requiring AI inference. Triggers: ai
  analysis, describe image, compare screenshots, smart crop, crop around people,
  face crop, generate essay, evaluate condition, alt text, image description, UI
  comparison, visual diff, satisfies condition, boolean evaluation, gemini.
```

**Compatibility requirements (recommended):**

- Max 500 characters
- Include if the skill has external dependencies or environment requirements
- Mention required command-line tools, network access needs, or target platforms
- Example:
  `compatibility: Requires curl and jq. Image tools also need base64 and magick (ImageMagick). Needs GEMINI_API_KEY environment variable and network access to generativelanguage.googleapis.com.`

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

For AI analysis, most operations are deterministic (run this exact command), so
prefer low-freedom documentation with specific commands.

#### Scripts First (Critical)

Add a prominent section at the top of SKILL.md body titled "Important: Use
Scripts First" that:

1. Tells agents to **ALWAYS prefer the scripts** over raw `curl` API calls
2. Notes that scripts are located in the `scripts/` subdirectory of the skill's
   folder
3. Lists specific features scripts provide that raw commands don't:
   - Proper image encoding (WebP, alpha removal)
   - Appropriate model selection for each task
   - Structured output handling (boolean responses)
   - Meaningful exit codes for shell integration
4. Explains when to read script source: if a script doesn't do exactly what's
   needed, or fails due to missing dependencies. The scripts encode Gemini API
   best practices (image ordering, structured output schemas, model selection)
   that may not be obvious—they serve as valuable reference when building
   similar functionality.

This section ensures agents see the scripts-first guidance immediately when the
skill activates.

#### Quick Start

- Environment: `GEMINI_API_KEY` required
- Dependencies: `curl`, `jq` (all tools); `base64`, `magick` (image tools only)
- 5 highest-value commands to run first:
  - `scripts/screenshot-describe image.png` (generate alt-text)
  - `scripts/screenshot-compare before.png after.png` (find visual differences)
  - `scripts/photo-smart-crop photo.jpg cropped.jpg` (crop around people)
  - `scripts/emerson "Question" < document.txt` (essay-length analysis)
  - `echo "text" | scripts/satisfies "condition"` (boolean evaluation)
- Use paths relative to the skill: `scripts/screenshot-describe`

#### Script Overview

A compact reference for each script. For each, provide:

- **Purpose** (1-2 lines)
- **Basic usage**
- **Key options**
- **Exit codes**

Scripts to document:

1. **screenshot-describe** - Generate concise alt-text for an image
   - Fast, optimized for UI captures
   - Default prompt focuses on elements, text, colors, layout
   - Supports custom prompts for specific analysis needs

2. **screenshot-compare** - Compare two images for visual differences
   - Identifies layout shifts, color changes, padding, text updates
   - Detailed paragraph-form output for UI QA
   - Exit code 2 when images are identical

3. **photo-smart-crop** - Smart crop images around detected people
   - Uses Gemini API for face/person detection
   - Configurable aspect ratio (--ratio W:H, default 5:3)
   - Prioritizes faces, expands for headroom, enforces aspect ratio
   - Exit code 2 when rate limited (allows retry logic)

4. **emerson** - Generate essay-length (~3000 words) analysis from text input
   - Reads reference material from stdin
   - Produces authoritative, footnoted Markdown output
   - High-quality output suitable for documentation and reports

5. **satisfies** - Evaluate whether text satisfies a condition
   - Reads input from stdin, returns boolean via exit code
   - Useful for shell conditionals and validation
   - Exit code 0 = true, 1 = false

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
- The scripts do not store or log input data

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

Include sections on:

- **Image encoding** requirements and platform differences (macOS vs Linux)
- **Request structure** differences (image-first vs text-first vs boolean)

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
- Missing stdin input (satisfies)
- Unexpected boolean results (satisfies)

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

````markdown
Describe an image:

```bash
scripts/screenshot-describe image.png
```
````

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
- Emphasize scripts over raw API calls. Scripts provide features (image
  encoding, model selection, exit codes) that raw commands don't.
- Do not duplicate raw API commands from scripts into SKILL.md. Tell agents to
  read the script source if they need the underlying command.
- Keep file references one level deep from SKILL.md
- Avoid redundant sections

## Quality Checklist

Before finalizing, verify:

### Structure

- [ ] Skill directory exists at `etc/skills/ai-analysis/`
- [ ] `scripts/` contains symlinks to all four scripts
- [ ] Scripts are executable (`chmod +x`)
- [ ] No extraneous files (README.md, etc.)

### SKILL.md

- [ ] Valid frontmatter matching the spec
- [ ] Description is in third person
- [ ] Description ends with "Triggers:" and explicit keywords
- [ ] Compatibility field lists required tools and GEMINI_API_KEY
- [ ] Body is under 500 lines

### Content Coverage

- [ ] `SKILL.md` has "Important: Use Scripts First" section at top of body
- [ ] All five scripts documented (screenshot-describe, screenshot-compare,
      photo-smart-crop, emerson, satisfies)
- [ ] Image encoding conventions documented (briefly, for troubleshooting)
- [ ] Platform differences (macOS vs Linux) noted
- [ ] Raw API commands are NOT in SKILL.md body (agents read script source)
- [ ] Examples use realistic filenames

### References

- [ ] `references/command-index.md` documents each script with raw API commands
- [ ] `references/troubleshooting.md` covers common issues
- [ ] Files over 100 lines have a Contents section

### Cross-Model Compatibility

- [ ] Instructions are clear enough for simpler models (Haiku)
- [ ] Instructions don't over-explain for powerful models (Opus)

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

**Images:**

- `screenshot.png`, `before.png`, `after.png`
- `login-screen.png`, `dashboard.png`
- `v1-header.png`, `v2-header.png`
- `ui-mockup.png`, `production-capture.png`

**Text files:**

- `documentation.md`, `release_notes.txt`
- `api-spec.md`, `design-doc.txt`
- `meeting-notes.txt`, `research-paper.md`
- `log.txt`, `response.json`

---
name: technical-writing-style
description: >
  Use this skill when authoring, reviewing, or editing technical documents,
  including bug reports, known issues, friction logs, PR descriptions, and the
  structural content and tone of commit messages. Use to ensure engineering
  content maintains a clear, factual, and constructive tone. Triggers: technical
  writing, bug report, known issue, friction log, PR description, pull request,
  commit message tone, review document.
---

# Technical Writing Style Guidelines

This skill provides guidelines and formatting standards for authoring various
types of technical and engineering documents.

## Core Principles

When writing or editing technical content, adhere to the following tonal and
structural principles:

- **Plain English:** Be direct, clear, and factual. Avoid corporate speak,
  overly formal detachment, and excessive jargon.
- **Constructive & Collegial:** Position yourself as an enthusiastic peer who
  wants the tool to succeed. Be supportive of the tool/library authors while
  remaining objective about the facts. Frame friction as opportunities for
  clarity, not as failures.
- **Avoid Exaggeration:** Do not use colloquial "cheerleading", subjective, or
  exclamatory language (e.g., avoid phrases like "massive quality-of-life
  improvement," "this tool shines," or "absolute powerhouse"). State the benefit
  factually instead (e.g., "This significantly simplifies parsing").
- **Focus on the "Why" & Context:** Assume the reader knows the codebase but not
  the specific problem you are solving. Provide enough background that the
  document makes sense in isolation. The code/log explains _what_ changed and
  _how_; your writing must explain _why_.
- **Defend Your Decisions:** Proactively explain controversial choices,
  trade-offs, or omissions (e.g., why tests weren't added, why a specific
  library was chosen).
- **Prohibition on Speculation:** Maintain objectivity. Do not interpret intent
  or attach qualitative judgment to behavior. Describe observable symptoms and
  factual outcomes. Save technical reasoning, hypotheses, and root cause
  analysis for dedicated "Analysis" or "Rationale" sections.

## Document Types

Depending on the specific document you are asked to write or review, consult the
relevant reference guide below:

### 1. Friction Logs

Use when documenting a first-time user experience or walkthrough of a new tool,
CLI, or API. **See:** [references/friction-logs.md](references/friction-logs.md)

### 2. Bug Reports

Use when documenting a defect, crash, or unexpected behavior that requires a fix
from library/tool maintainers. **See:**
[references/bug-reports.md](references/bug-reports.md)

### 3. Known Issues

Use when translating a "working as intended" bug or unfixable limitation into
documentation intended to help end-users navigate the current state of a
library. **See:** [references/known-issues.md](references/known-issues.md)

### 4. Commit Messages

Use when authoring or reviewing git commit messages. Ensures the immediate
technical "why" and factual record are clearly communicated for the permanent
history. **See:** [references/commit-messages.md](references/commit-messages.md)

### 5. Pull Request Descriptions

Use when authoring or reviewing pull request descriptions. Ensures the change is
persuasively justified and broad context is provided for reviewers. **See:**
[references/pr-descriptions.md](references/pr-descriptions.md)

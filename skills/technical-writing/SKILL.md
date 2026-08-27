---
name: technical-writing
description: >-
  Guidelines and structural standards for authoring, reviewing, and editing
  engineering documents with a factual, collegial, and constructive tone. Covers
  bug reports, known issues, friction logs, PR descriptions, commit message prose,
  TODO/task lists, Getting Started guides, and Agent Skills (SKILL.md). Use when
  drafting or reviewing technical documentation, friction logs, issue reports,
  PR descriptions, onboarding guides, or agent skill files.
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
  analysis for dedicated "Analysis" or "Rationale" sections (or, in TODO items,
  the "Sketch" field).

## Document Types & Reference Material

Depending on the specific document you are authoring or reviewing, consult the
relevant reference guide:

- **[Friction Logs](references/friction-logs.md)** — Documenting first-time user
  journeys, setup hurdles, and CLI walkthroughs.
- **[Bug Reports](references/bug-reports.md)** — Documenting defects, crashes,
  reproduction steps, and unexpected behaviors factually.
- **[Known Issues](references/known-issues.md)** — Explaining "working as
  intended" constraints, upstream limitations, and workarounds for end users.
- **[Commit Messages](references/commit-messages.md)** — Authoring the technical
  "why", context, and permanent history behind changes.
- **[PR Descriptions](references/pr-descriptions.md)** — Summarizing intent,
  justifying trade-offs, and guiding reviewers through diffs.
- **[Comments](references/comments.md)** — Writing direct, concise, and factual
  code review or issue comments.
- **[TODO Items](references/todos.md)** — Capturing tasks with Goal, Criteria,
  and Sketch fields without hardening into premature plans.
- **[Getting Started Guides](references/getting-started-guides.md)** — Building
  action-oriented onboarding golden paths from zero to first result.
- **[Agent Skills](references/skills.md)** — Authoring modular, decoupled, and
  self-contained `SKILL.md` files and reference documents.

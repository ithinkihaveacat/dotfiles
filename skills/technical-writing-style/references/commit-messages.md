# Commit Message Guidelines

This document outlines the standard for writing comprehensive commit messages.
The goal is to provide future maintainers with the context necessary to
understand _why_ a change was made via `git blame` or `git log`.

A commit message is a permanent, historical record attached to the code itself.

- **Goal:** Provide a factual, concise record of _what_ was changed and the
  immediate technical _why_.
- **Detail:** Proportional to complexity. The length and depth of the
  explanation should scale with the complexity or unexpected nature of the
  change. Omit sweeping user stories or broad PR-style justifications, but
  provide well-reasoned, detailed explanations when documenting non-trivial
  architectural shifts, non-obvious constraints, or rejected alternatives.
- **Tone:** Objective and matter-of-fact. State the problem and the resolution
  plainly.

## Mechanical Formatting

This document focuses on the structural content and tone of commit messages. For
rules regarding mechanical formatting (e.g., Conventional Commits syntax,
subject line length limits, or line wrapping), please search for and consult any
available coding standards or git guidelines within the workspace.

## Structural Archetypes

Choose a structure that best fits the nature of your change.

### The Bug Fix / Performance Improvement

Best for targeted fixes where the cause and effect are clear.

- **Problem:** What was the observable failure or bottleneck? (e.g., "Running
  `renderAllPreviews` took over 12 minutes and crashed with
  `OutOfMemoryError`.")
- **Cause:** The technical root cause. (e.g., "An infinite animation in
  `LoadingPreview` prevented layout stabilization, forcing the renderer to
  maximum frame limits.")
- **Solution:** How the cause was addressed. (e.g., "Made the preview static and
  increased heap size to 2048m.")
- **Results:** The measurable impact. (e.g., "Render time dropped from ~12.5
  minutes to 15 seconds. Resolved OOM crashes.")

### The Feature / Broad Refactor

Best for larger changes introducing new capabilities or restructuring code.

- **Summary / Goal:** A high-level overview of what the change achieves.
- **Proposed Changes:** A concise breakdown of the major components modified,
  grouped logically (e.g., by module or architectural layer).
- **Rationale & Safety:** Explain why the chosen approach is safe and discuss
  any specific trade-offs (e.g., adding stub classes).

### The Architectural Shift

Best for changes that replace underlying technologies or fundamentally alter how
a system operates.

- **Core Architectural Changes:** Use a clear, focused format (like Q&A) to
  justify major shifts.
  - _Why are we eliminating X?_ (Explain the flaws or limitations of the old
    system).
  - _Why use Y?_ (Explain the benefits and necessity of the new system).
- **Implementation Details / Strategies:** Highlight specific, complex build
  logic or implementation details and justify them.

## Essential Elements

Regardless of the archetype you choose, prioritize these sections when
applicable:

### Safety and Risk Assessment

If your change introduces potential fragility, touches critical paths, or relies
on assumptions, explicitly state why you believe it is safe.

> **Example:** "This change is safe because it merely aligns the `classpath`
> with the `testClassesDirs` changes introduced in PR #33. It only _appends_ the
> consumer's test classes to the existing resolution."

### Justifying Omissions (The "Why We Aren't..." Section)

If you are skipping standard practices (like adding automated tests for a new
feature), you _must_ explain why.

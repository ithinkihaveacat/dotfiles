# Pull Request Description Guidelines

This document outlines the standard for writing comprehensive Pull Request (PR)
descriptions. The goal is to provide reviewers with the context necessary to
understand the rationale behind technical decisions and how the change was
validated.

A PR description is your opportunity to advocate for the change. It is an
ephemeral document aimed at the maintainer or reviewer _right now_.

- **Goal:** Justify the change, provide broad context, and convince the
  maintainer that the approach is sound and necessary.
- **Detail:** High. Include extensive motivation, background on the use case,
  and narrative explanations of the problem space.
- **Tone:** Persuasive but professional. You are explaining why the project
  needs this change.

## Structural Archetypes

Choose a structure that best fits the nature of your change.

### The Bug Fix / Performance Improvement

Best for targeted fixes where the cause and effect are clear.

- **Problem:** What was the observable failure or bottleneck?
- **Cause:** The technical root cause.
- **Solution:** How the cause was addressed.
- **Results:** The measurable impact.

### The Feature / Broad Refactor

Best for larger changes introducing new capabilities or restructuring code.

- **Summary / Goal:** A high-level overview of what the change achieves.
- **Motivation:** Why this change is necessary for the broader project or
  usecase.
- **Proposed Changes:** A concise breakdown of the major components modified,
  grouped logically.
- **Rationale & Safety:** Explain why the chosen approach is safe and discuss
  any specific trade-offs.
- **Verification:** Detailed steps on how the change was tested, including
  environment details and manual reproduction steps.

### The Architectural Shift

Best for changes that replace underlying technologies or fundamentally alter how
a system operates.

- **Core Architectural Changes:** Use a clear, focused format (like Q&A) to
  justify major shifts.
  - _Why are we eliminating X?_
  - _Why use Y?_
- **Implementation Details / Strategies:** Highlight specific, complex build
  logic or implementation details and justify them.

## Essential Elements

Regardless of the archetype you choose, prioritize these sections when
applicable:

### Safety and Risk Assessment

If your change introduces potential fragility, touches critical paths, or relies
on assumptions, explicitly state why you believe it is safe.

### Justifying Omissions

If you are skipping standard practices (like adding automated tests), you _must_
explain why.

### Verification & Reproduction Steps

Provide concrete evidence that the change works. For complex integrations,
provide a "Steps to Reproduce" guide so reviewers can manually verify the
behavior in their own environment.

> **Example:**
>
> 1. Publish the library locally: `./gradlew publishToMavenLocal`
> 2. Run previews in the sample app: `./gradlew renderPreviews`
> 3. Verify screenshots are generated in `app/build/compose-previews/renders/`
>    and are not blank.

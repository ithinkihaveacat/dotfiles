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

## Core Principle: Separating Goal from Implementation

When a change is risky, originates from an untrusted source, or has multiple
viable approaches, it is crucial to structurally separate the _goal_ of the PR
from its _specific implementation details_.

This separation allows reviewers to agree that the underlying problem should be
solved (validating the goal), even if they determine the proposed approach (the
implementation) should be discarded or rewritten. The goal and motivation should
provide enough context that another engineer could independently arrive at a
similar implementation without seeing your code.

- **The Goal/Change:** Clearly articulate the underlying problem being solved
  and why achieving this state is valuable to the project.
- **The Implementation:** Detail how this specific PR achieves that goal,
  acknowledging alternative approaches or trade-offs if relevant.

## Self-Contained Requirement

A PR description MUST be self-contained. Do NOT refer to the conversation with
the agent, or to an artifact directory that may not be present for the reviewer.
If you need to provide screenshots or files for the user to upload, specify
their names and where they should be placed in the description, but do not
assume the reviewer can access the agent's local environment.

## Structural Archetypes

Choose a structure that best fits the nature of your change.

### The Bug Fix / Performance Improvement

Best for targeted fixes where the cause and effect are clear.

- **Problem:** What was the observable failure or bottleneck?
- **Cause:** The technical root cause.
- **Solution:** How the cause was addressed.
- **Results:** The measurable impact.

### The Feature / Broad Refactor

Best for larger changes introducing new capabilities or restructuring code. It
naturally separates the "why" from the "how".

- **Summary / Goal:** A high-level overview of what the change achieves and why
  it is necessary.
- **Proposed Implementation:** A concise breakdown of the major components
  modified to achieve the goal, grouped logically.
- **Rationale & Safety:** Explain why the chosen approach is safe and discuss
  any specific trade-offs or alternative implementations considered.
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

# Friction Log Guidelines

This document outlines the standard for writing friction logs.

## Intent and Audience

A **Friction Log** documents an engineer's initial walkthrough when adopting or
evaluating a new tool, API, or CLI, capturing the chronological reality of
setup, usage, and friction points.

- **Goal:** Provide product and engineering teams with actionable, constructive
  feedback from a user's perspective.
- **Audience:** Tool authors, library maintainers, and team peers.
- **Tone:** Constructive, collegial, and factual. Frame friction as
  opportunities for clarity rather than tool failures.

## Required Structure

A complete friction log consists of the following sections:

### 1. Document Metadata & Introduction

Provide the context of the evaluation:

- **Date:** The date the evaluation took place.
- **Environment:** The operating system and relevant environment details.
- **Perspective:** Your role (e.g., integration engineer) and mindset.
- **Introduction Paragraph:** A brief paragraph introducing why you are
  evaluating the tool and framing the document as a helpful contribution.

_Example Introduction:_

> "This document is a friction log detailing my experiences with the
> [Tool Name](link). I have previously built and maintained a suite of custom
> scripts that provide very similar capabilities for automating these tasks—I'm
> very glad to see these workflows standardized in an official tool! I imagine
> it will become an important asset for developers. This document captures my
> experiences with the tool. I hope the observations/suggestions are useful."

### 2. Executive Summary

Before jumping into the step-by-step log, highlight 3–4 core themes or systemic
issues identified during the walkthrough. Frame these constructively.

- Avoid authoritative judgments like "This lack of observability is a critical
  failure."
- Prefer constructive framing like "Adding `--verbose` flags would be helpful
  for debugging."

### 3. Chronological Walkthrough (The "Log")

Break down your interaction into distinct chronological steps (e.g.,
Installation, Setup, Core Command Execution).

For each step:

1. **Context/Action:** Describe what you were trying to do.
1. **Commands & Outputs:** Include the exact shell commands executed and their
   literal output (truncated if overly long). This proves _what_ happened.
1. **Observation:** Factually state what occurred or where the friction lies.
   Frame limitations as suggested improvements.

_Example Observation Block:_

> ```bash
> tool start --cold
> ```
>
> **Observation:** Testing the `start` command, I was glad to see it includes a
> `--cold` boot flag. However, a `--wipe-data` option is currently missing.
> Adding this flag would be very helpful, as returning to a clean state is a
> frequent requirement for reliable testing.

### 4. Feature Requests & General Observations

Conclude the document with any systemic feature requests or observations that
fall outside a specific chronological step. Explain _why_ these features matter
to your specific workflows. Link to examples of prior art (e.g., your own
dotfiles or scripts) to demonstrate the utility.

## Summary Checklist

Before finalizing a friction log, verify that:

- [ ] Tone is collegial, supportive, and objective, avoiding authoritative or
  hyperbolic critique.
- [ ] Steps follow a strict chronological walkthrough with exact commands and
  literal outputs.
- [ ] Friction points are paired with concrete suggestions or feature requests.
- [ ] Context metadata (date, environment, perspective) is clearly defined.

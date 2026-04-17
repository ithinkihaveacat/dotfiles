# Friction Log Guidelines

A **Friction Log** documents your initial experience and walkthrough when
attempting to adopt or evaluate a new tool, API, or CLI. It captures the raw,
chronological reality of setup, usage, and any resulting points of friction or
missing capabilities.

The goal is to provide product and engineering teams with actionable,
constructive feedback from a user's perspective, without sounding like a
detached software review or an overly subjective critique.

## Tone & Perspective

- **Collegial & Constructive:** You are a peer engineer offering observations.
  You want the tool to succeed. Frame friction as opportunities for clarity, not
  as failures.
- **Plain English:** Be direct and factual. Avoid excessive jargon and corporate
  speak.
- **Avoid Exaggeration:** Do not use colloquial "cheerleading" or exaggerations
  (e.g., instead of "massive quality-of-life update" or "absolute powerhouse,"
  use "significantly simplifies parsing" or "provides powerful capabilities").
- **Establish the "Why":** Set the stage in the opening paragraph. Acknowledge
  the value of the tool, validate its approach based on your own experience (if
  applicable), and express optimism for its future.

## Required Structure

A complete friction log consists of the following sections:

### 1. Document Metadata & Introduction

Provide the context of the evaluation:

- **Date:** The date the evaluation took place.
- **Environment:** The operating system and relevant environment details.
- **Perspective:** Your role (e.g., Android DevRel Engineer) and mindset.
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
- Prefer constructive framing like "Adding `--verbose` flags would be super
  helpful for debugging."

### 3. Chronological Walkthrough (The "Log")

Break down your interaction into distinct chronological steps (e.g.,
Installation, Setup, Core Command Execution).

For each step:

1. **Context/Action:** Describe what you were trying to do.
2. **Commands & Outputs:** Include the exact shell commands executed and their
   literal output (truncated if overly long). This proves _what_ happened.
3. **Observation:** Factually state what occurred or where the friction lies.
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

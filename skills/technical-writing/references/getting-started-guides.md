# Getting Started Guide Guidelines

This guide covers authoring, refactoring, and reviewing Getting Started guides
and onboarding documentation.

## Intent and Audience

A Getting Started Guide is a high-velocity, action-oriented document designed to
take a developer (or an automated AI agent) from a clean environment to a
tangible, successful outcome with minimum friction.

- **Goal:** Provide the exact sequence of commands needed to achieve a concrete
  milestone (the "Golden Path").
- **Audience:** Developers and AI agents seeking immediate setup instructions
  without extraneous background reading.
- **Tone:** Direct, action-first, and imperative.

## Core Principles

### 1. Action-First & High Focus (The "Golden Path")

- **Focus on the Immediate Goal:** Structure the guide around a single, highly
  practical milestone (e.g., *From Zero to Running Benchmark*).
- **Single Standard Path:** Guide the reader through one reliable, standard
  workflow. When authoring or refactoring guides, avoid branching into multiple
  alternative tools, secondary options, or experimental configurations in the
  primary walkthrough.
- **Commands Over Prose:** Minimize background exposition, design history, and
  theoretical rationales in the walkthrough. Keep prose concise so the user or
  agent can easily scan, copy, and run commands.

### 2. Dual Optimization: Agent-Executable & Human-Readable

- **Idempotency:** Every setup command must be safe to re-execute multiple times
  without failing, corrupting state, or appending duplicate configuration
  entries.
- **Non-Interactive by Default:** Commands must execute cleanly without blocking
  on interactive prompts or TTY inputs (e.g., pass `--headless`,
  `--non-interactive`, or `-y` where applicable).
- **Explicit Directory Context:** Never assume the shell is already in the
  correct working directory. Always declare, verify, or navigate to the target
  context (`cd "${FOO_HOME:-/opt/toolchain}"`).
- **Simple, Portable Shell Syntax:** Use standard, readable POSIX/Bash
  constructs. Avoid esoteric syntax, fragile pipelines, or complex subshell
  tricks.

### 3. Fail-Fast Prerequisite Checks

- **Scale Complexity Proportionally:**
  - **Simple Setups (1–3 Checks):** Prefer discrete, individual command lines or
    native `doctor` checks. Discrete commands are easier for human developers to
    read and copy one-by-one into an interactive terminal without having to
    unravel an entire wrapper script. Agents can easily execute them
    sequentially or group them on the fly.
  - **Complex Setups:** Consolidate into a single copy-pasteable script only
    when setup warrants it—such as when managing multiple interdependent
    binaries, dynamic filesystem path autodetection, or multi-step environment
    exports.
- **Prioritize Native `doctor` Commands:** If the tool provides a native health
  check command (e.g., `foo doctor`), use it as the primary verification step
  rather than writing redundant ad-hoc shell checks.
- **Standard Dependency Validation:** Use standard `command -v` checks that exit
  with standard exit code `127` when a required binary is missing.
- **Autodetection Over Manual Lookup:** When path lookups are required, prefer
  self-configuring shell snippets over asking users to manually search their
  filesystem.

### 4. Actionable Error Recovery & Co-Location

- **Anticipate Common Failure Modes:** Proactively identify a realistic range of
  frequent errors (e.g., missing auth, wrong working directory, missing
  dependencies) without attempting to document every possible edge case.
- **Co-Locate Troubleshooting Beside Commands:** For humans working through a
  guide step-by-step, it is often most helpful to place troubleshooting tips and
  recovery actions directly below the specific command that might fail, rather
  than relegating everything to a distant appendix.
- **Flexible Format:** Present troubleshooting inline (as brief notes/callouts
  beneath the relevant step) or in a consolidated summary table. Keep all fixes
  immediate, factual, and 1-line actionable.

### 5. Clear Separation: Walkthrough vs. Reference

- **Keep the Getting Started Flow Clean:** The walkthrough itself must contain
  only the sequential setup, execution, and verification steps.
- **Decouple Reference Material:** Place deep technical context (execution
  lifecycles, architectural overviews, full flag tables, JSON schemas, output
  artifact catalogs, and advanced workflows) outside the primary
  walkthrough—either in a distinct reference section or split into dedicated
  companion reference documents.

## Authoring Patterns & Examples

### 1. Writing Pre-requisite Checks

#### Pattern A: Discrete Checks (Preferred for 1–3 Simple Checks)

Keep simple checks as clean, standalone command lines that both humans and
agents can run directly:

```bash
# Verify required CLI binary is present
command -v foo >/dev/null 2>&1 || { echo >&2 "ERROR: 'foo' CLI not found on PATH." && exit 127; }

# Verify authentication status non-interactively
auth-status --check || auth-login --headless
```

#### Pattern B: Consolidated Script (For Complex Multi-Path / Autodetect Setups)

When setups involve dynamic path resolution or multiple interdependent
dependencies, group checks into an idempotent script:

```bash
#!/usr/bin/env bash
set -euo pipefail

# 1. Standard dependency checker (Exits 127 on missing binary)
require() {
  command -v "$1" >/dev/null 2>&1 || {
    echo >&2 "ERROR: '$1' not found. Ensure it is installed and on PATH."
    exit 127
  }
}

require git
require jq
require curl

# 2. Autodetect or verify toolchain directory
if [[ -d "/opt/toolchain/v2" ]]; then
  export FOO_HOME="/opt/toolchain/v2"
elif [[ -d "/usr/local/toolchain" ]]; then
  export FOO_HOME="/usr/local/toolchain"
else
  echo >&2 "ERROR: Required toolchain not found under standard paths."
  exit 1
fi
```

### 2. Writing Core Execution Commands

Provide the single, standard invocation for a lightweight sample task. Ensure
the working context is explicit and output artifacts are routed predictably:

```bash
# 1. Guarantee working directory context
cd "${FOO_HOME:-/tmp}"

# 2. Ensure output directory exists (Idempotent)
mkdir -p /tmp/foo-results

# 3. Execute sample task with explicit outputs and non-interactive flags
foo run \
  --config=samples/basic.yaml \
  --output-dir=/tmp/foo-results \
  --non-interactive \
  --verbose
```

### 3. Formatting Error Recovery & Troubleshooting

#### Pattern A: Co-Located Recovery (Preferred for Step-by-Step Walkthroughs)

Place immediate recovery notes directly beneath the command that might fail:

> **Troubleshooting:**
>
> - If `foo run` fails with `Authentication expired (401/403)`, run
>   `auth-login --headless` to refresh credentials.
> - If you receive `Permission denied` on the output directory, ensure write
>   permissions with `chmod -R 755 /tmp/foo-results`.

#### Pattern B: Summary Recovery Table (For Consolidated Multi-Error Overviews)

When aggregating multiple exit codes or failure conditions across the flow:

| Exit Code / Symptom   | Error Message / Condition            | Quick Actionable Fix                   |
| :-------------------- | :----------------------------------- | :------------------------------------- |
| **Exit `127`**        | `ERROR: 'foo' not found on PATH`     | `export PATH="/opt/foo/bin:$PATH"`     |
| **Exit `1`** (Auth)   | `Authentication expired (401/403)`   | Run `auth-login --headless` to refresh |
| **Exit `1`** (Config) | `Toolchain version mismatch`         | `export FOO_HOME="/opt/toolchain/v2"`  |
| **Exit `1`** (Disk)   | `Output directory permission denied` | `chmod -R 755 /tmp/foo-results`        |

## What Belongs vs. What Does Not

| Belongs in "Getting Started"            | Belongs in "Reference" / Upstream Docs    |
| :-------------------------------------- | :---------------------------------------- |
| Single, standard happy-path walkthrough | Multi-tool comparison tables & trade-offs |
| Discrete checks (or script if complex)  | Full architectural lifecycle diagrams     |
| Immediate command to run a sample task  | Exhaustive CLI flags & advanced options   |
| Direct URLs / paths to view outputs     | Experimental / edge-case configurations   |
| 1-line fixes for common failure modes   | Comprehensive schema specifications       |

## Summary Checklist

Before finalizing a Getting Started guide, verify that:

- [ ] The walkthrough follows a single, proven golden path from zero to a
  tangible milestone.
- [ ] Prerequisite checks are proportional (discrete checks for simple setups,
  consolidated script only if complex).
- [ ] Commands are non-interactive by default (`--headless`, `-y`, etc.) and
  directory context is explicit.
- [ ] Common failure modes have immediate, 1-line actionable recovery
  instructions.
- [ ] Deep technical context, architectural diagrams, and exhaustive flag
  references are decoupled into reference sections or companion docs.

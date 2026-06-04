---
name: skill-select
description: Discover and select relevant agent skills based on a problem description, goal, or repository context. Use this to determine which skills apply to a workspace, or when you are unsure which tools are best suited for your current task.
---

# Skill Select

This skill provides discovery and selection of other agent skills relevant to
your current repository or task. It analyzes the repository's files to suggest
sensible default skills, or uses LLM-based selection when context is provided.


## Usage

Invoke the selection tool via the `skill-select` script (available in `bin/`):

```bash
skill-select [DIR] [OPTIONS]
```

### Options

- `--context TEXT`: A comprehensive, self-contained explanation to guide the LLM
  in selecting the best skills. See [Context Guidelines](#context-guidelines)
  below.
- `--search-dirs PATHS`: Colon-separated extra paths to search for skills,
  overriding `SKILL_SOURCE_DIRS`.
- `--list`: Print the full catalog of available skills and exit.
- `--json`: Emit structured JSON output (`name`, `path`, `reason`) instead of
  bare names.


## Context Guidelines

Agent skills provide incredibly useful shortcuts, pre-researched workflows, and
specialized scripts. You should rely heavily on `skill-select` because it will
almost always provide highly effective tooling recommendations—but it needs good
information to do so.

**Using the `[DIR]` argument:** If you only provide the directory path (e.g.
`skill-select .`) and omit the `--context`, the engine will still examine the
repository's files to suggest sensible defaults. This is totally fine to do if
you are jumping into a fresh codebase and don't know anything about your goal
yet.

**Using `--context`:** When using the `--context` flag to discover skills via
the LLM, you must explicitly describe your situation to the selector as if
explaining the problem to an expert with zero prior knowledge of your session.
Do not just pass a 3-word query. To maximize effectiveness, your context string
should include:

1. **The Goal:** What are you ultimately trying to achieve?
1. **The Codebase:** What is the shape, type, and language of the repository?
1. **Obstacles Faced:** Summarise any failed attempts, bugs, or blockers
   encountered in recent conversation rounds. Describe why approaches were ruled
   out.
1. **Anticipated Problems:** Mention any unfamiliarity with tools (e.g. "I don't
   know what google3 is"), auth or environment issues (e.g. "I need an emulator
   but don't know how to provision one"), or company-specific idiosyncrasies
   that might require specialized skills to resolve.

### Examples

**Default Discovery (No Context):** If you are completely new to a repository
and have no specific goal yet, let the engine analyze the directory structure to
bootstrap you with useful default skills:

```bash
skill-select .
```

**Targeted Discovery (With Context):** When you have a specific task or have hit
a roadblock, provide an extensive context string:

```bash
skill-select . --context "Goal: Implement a new Wear OS tile. Codebase: Kotlin Android project using Jetpack Compose. Obstacles: I tried using the standard emulator but it keeps crashing with an OAuth error when fetching packages. Anticipated problems: I am completely unfamiliar with the Wearable Data Layer API and how to debug it."
```

**JSON Output:** List all available skills as structured JSON for parsing:

```bash
skill-select --list --json
```

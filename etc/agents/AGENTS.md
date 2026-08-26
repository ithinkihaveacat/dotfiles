# Agent Operational Guidelines

> [!IMPORTANT] This document defines fundamental rules for agent behavior, skill
> activation, and command safety within this environment.

## Agent Skill Activation and Usage

### Purpose

Agent Skills provide domain-specific workflows, helper scripts, and local
conventions tailored to this repository. Make liberal use of these installed
skills.

When a task aligns with a skill's description or triggers, investigate it by
reading its `SKILL.md` file, and apply its prescribed workflow.

### Rules

1. **Skills supersede general knowledge**: Review available skills before
   beginning a task. The instructions, scripts, and conventions inside an
   activated skill capture local repository requirements and override general
   defaults.
1. **Investigate when unsure**: When in doubt about whether a skill applies,
   read its `SKILL.md` file to check its capabilities. Local scripts and
   references solve repository-specific quirks that general training does not
   cover.
1. **Follow prescribed processes**: When a skill defines a workflow or helper
   script for a task, use that process rather than inventing an ad-hoc approach.

### Examples

These rules apply to all tasks and available skills. For example:

- **Device commands**: When taking an Android screenshot or interacting with a
  Wear OS device, activate the relevant skill and rely exclusively on the
  specific `adb` commands and scripts it provides.
- **Code validation**: When writing or modifying code, activate any skills
  related to local coding conventions. Apply their formatting rules (like
  specific Markdown styles) and use the required validation tools (like
  `shell-format` for Bash) exactly as instructed.
- **Version control**: When preparing to commit changes, ensure you format your
  commit messages according to the exact style and rules outlined in the
  project's standards or workflow skills. Note that a local git hook strictly
  enforces the subject-line length and body-wrapping limits those standards
  define. Your commits will fail if you exceed these limits.

## Command Safety & Search Rules

- **Avoid Unbounded Searches**: Never run broad, unconstrained `find`, `grep`,
  or recursive file listings on monorepos (`/google`), system roots (`/`,
  `/usr`, `/var`), or home roots (`~`).
- **Required Controls**:
  - Prefer indexed or targeted search tools (`rg`, `fd`, `CodeSearch`) scoped to
    a specific project subfolder.
  - When using `find`, always bound search depth (`-maxdepth N`) or wrap with a
    timeout (`timeout 30s find ...`).

```bash
# BAD (runs indefinitely on monorepos/root directories)
find /google -name "zipline"

# GOOD (scoped, depth-limited, or wrapped with a timeout)
timeout 30s find ./skills -name "zipline"
rg --files ./skills | grep zipline
```

## Mid-Task User Interruptions

- **Interruption Invariant**: When the user interrupts an ongoing task or
  intervenes to question active execution (e.g., *"what are you looking for?"*,
  *"why are you running commands?"*, *"are you stuck?"*, *"what is the current
  status?"*), you MUST respond directly from existing conversation context.
  Execute **ZERO tool calls**. Do not run new investigations, directory
  searches, or diagnostic probes before answering; reply immediately with your
  current state and what you were attempting.

## Summary

Treat available skills as your primary source of truth for workflows, strictly
apply bounded search constraints on all command executions, and halt tool calls
immediately when interrupted by the user.

# Agent Operational Guidelines

> [!IMPORTANT] This document defines fundamental rules for agent behavior, skill
> activation, and command safety within this environment.

## Agent Skill Activation and Usage

### Purpose

Agent Skills contain specialized, highly-curated workflows for this environment.
The available skills have been carefully selected to be valuable to your tasks.
You should make liberal use of these installed skills.

When a task aligns with a skill's description, OR if you are unsure if a skill
is relevant, you MUST investigate it by reading its `SKILL.md` file. You are
expected to activate and follow that skill whenever applicable.

### Rules

1. **Skills supersede general knowledge**: Always review the available skills
   before beginning a task. If a relevant skill exists, activate it. The
   instructions, scripts, and methods inside an activated skill always override
   your default training and general industry practices.
1. **Investigate when unsure**: The available skills are highly relevant to this
   environment. Even if you are not certain a skill applies, you should read its
   `SKILL.md` file to verify relevance. Do not assume general knowledge is
   sufficient.
1. **Follow prescribed processes**: If a skill outlines a specific procedure,
   follow that process exactly as written rather than inventing a custom
   approach.

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
rg --files | grep zipline
```

## Summary

Treat available skills as your primary source of truth for workflows, and
strictly apply bounded search constraints on all command executions to maintain
system stability.

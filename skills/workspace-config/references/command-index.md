# Command Index

<!-- markdownlint-disable MD013 -->

## Contents

- [skill](#skill)
- [permission](#permission)

## skill

The block below is `scripts/skill --help`, kept in sync by `command-index-sync`.

<!-- generated: ../scripts/skill --help -->

```text
Usage: skill <command> [skill...]

Manage per-workspace agent skills as untracked symlinks. Automatically detects
which agent is installed on PATH and applies symlinks and local git ignores:
  - Claude          -> .claude/skills
  - Codex/Agy/Jetski -> .agents/skills

Commands:
  apply           Synchronize workspace symlinks to match AGENT_REQUIRED_SKILLS
  suggest         Print advisory LLM skill recommendations (requires google-genai)
  add SPEC...     Add a skill: a local path or a plugin-provided catalog entry
  add -           Read skill names from stdin
  remove NAME...  Remove a skill and clean its exclude entry (alias: rm)
  list [--json]   List active skills on disk in the current workspace
  update SPEC...  Re-fetch a plugin-provided catalog entry; --all for every active
                  skill, --catalog to refresh the whole metadata index
  clean           Remove all skills and clear git excludes
  doctor          Diagnose mismatch between desired and on-disk skills (read-only)
  preflight LABEL Verify required skills and workspace health before agent launch
  catalog         List plugin-provided skills and sources
  resolve NAME    Print the source path 'add NAME' would symlink to
  show/info NAME  Show details and metadata of a skill

Options:
  --help             Display this help message and exit
  --plugin-template  Output a template/documentation for creating a Workspace plugin
```

<!-- /generated -->

## permission

The block below is `scripts/permission --help`, kept in sync by
`command-index-sync`.

<!-- generated: ../scripts/permission --help -->

```text
Usage: permission <command> [arguments]

Manage per-workspace agent tool permissions (allow/deny/ask rules) across
all detected local agents. Rules are written as clean command patterns
(e.g. "git show"); each agent backend translates to its native syntax.

Commands:
  add PATTERN...     Add rule patterns to the allowlist (--deny / --ask
                     for the other lists); 'add -' reads patterns from stdin
  remove PATTERN...  Remove rule patterns from all lists (alias: rm)
  list               List permission rules per agent (alias: ls)
  apply              Pre-approve the safe commands declared by this
                     workspace's installed skills (idempotent)
  clean              Clear all workspace-specific permission rules
  doctor             Report missing or drifted rules (read-only)

Options:
  --agent NAME       Operate on a single agent backend (agy, claude)
  --help             Display this help message and exit
  --plugin-template  Output a template/documentation for creating a Permission plugin

Agents:
  agy                Antigravity/jetski project config (under ~/.gemini)
  claude             Claude Code (.claude/settings.local.json, untracked)
```

<!-- /generated -->

<!-- markdownlint-restore MD013 -->

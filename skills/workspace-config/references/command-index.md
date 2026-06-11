# Command Index

<!-- markdownlint-disable MD013 -->

## Contents

- [skill](#skill)
- [skill-select](#skill-select)
- [permission](#permission)

## skill

The block below is `scripts/skill --help`, kept in sync by `command-index-sync`.

<!-- generated: ../scripts/skill --help -->

```text
Usage: skill <command> [skill...]

Manage per-workspace agent skills as untracked symlinks. Automatically detects
whether the current directory is a Git repository, Perforce workspace, or an
unmanaged directory, and applies the appropriate tracking mechanism. Extra
workspace types can be added via plugins in ~/.config/skill/plugins/.

Commands:
  apply           Provision skills for this workspace via skill-select (idempotent)
  suggest         Print skill-select recommendations without installing them
  add SPEC...     Add a skill: a local path or a plugin-provided catalog entry
  add -           Read skill names from stdin
  remove NAME...  Remove a skill this tool added (alias: rm)
  list [--json]   List skills this tool is managing in the current workspace
  update SPEC...  Re-fetch a plugin-provided catalog entry; --all for every managed
                  skill, --catalog to refresh the whole metadata index
  clean           Remove all skills this tool added and clear the tracking record
  doctor          Diagnose drift between desired and on-disk skills (read-only)
  repair          Re-link managed skills and regenerate tracking records
  catalog         List plugin-provided skills and sources
  resolve NAME    Print the source path 'add NAME' would symlink to

Options:
  --help             Display this help message and exit
  --plugin-template  Output a template/documentation for creating a Workspace plugin

Note: plugins, network, and AI functions are delegated to 'skill-select'.
```

<!-- /generated -->

## skill-select

The block below is `scripts/skill-select --help`, kept in sync by
`command-index-sync`.

<!-- generated: ../scripts/skill-select --help -->

```text
usage: skill-select [--help] [--context CONTEXT] [--search-dirs SEARCH_DIRS]
                    [--catalog] [--json] [--update [UPDATE ...]] [--doctor]
                    [--resolve NAME] [--repair] [--plugin-template]
                    [dir]

Skill Select: Discover relevant agent skills.

positional arguments:
  dir                   Directory to analyze (default: current).

options:
  --help                Display this help message and exit.
  --context CONTEXT     Comprehensive, self-contained context to guide
                        selection.
  --search-dirs SEARCH_DIRS
                        Colon-separated search directories (overrides
                        environment).
  --catalog             Print the full catalog of available skills and exit.
  --json                Emit structured output (name, source, reason) instead
                        of bare names.
  --update [UPDATE ...]
                        Re-fetch a plugin-provided catalog entry; --all for
                        every managed skill, --catalog to refresh the whole
                        metadata index
  --doctor              Diagnose drift between desired and on-disk skills
                        (read-only)
  --resolve NAME        Print the source path for a skill
  --repair              Repair catalog index (heal missing stubs without
                        forcing updates)
  --plugin-template     Output a template/documentation for creating a Python
                        plugin
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

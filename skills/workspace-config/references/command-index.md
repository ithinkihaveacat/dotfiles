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
unmanaged directory, and applies the appropriate tracking mechanism.

Commands:
  apply           Provision skills for this workspace via skill-select (idempotent)
  suggest         Print skill-select recommendations without installing them
  add SPEC...     Add a skill: a local path or a registered catalog entry
  add -           Read skill names from stdin
  remove NAME...  Remove a skill this tool added (alias: rm)
  list            List skills this tool is managing in the current workspace
  update SPEC...  Re-fetch a registered catalog entry; --all for every managed
                  skill, --catalog to refresh the whole metadata index
  clean           Remove all skills this tool added and clear the tracking record
  doctor          Diagnose drift between desired and on-disk skills (read-only)
  catalog         List registered skills and sources
  resolve NAME    Print the source path 'add NAME' would symlink to

Options:
  --help          Display this help message and exit

Note: registry, network, and AI functions are delegated to 'skill-select'.
```

<!-- /generated -->

## skill-select

The block below is `scripts/skill-select --help`, kept in sync by
`command-index-sync`.

<!-- generated: ../scripts/skill-select --help -->

```text
usage: skill-select [--help] [--context CONTEXT] [--search-dirs SEARCH_DIRS]
                    [--catalog] [--json] [--update [UPDATE ...]] [--doctor]
                    [--resolve NAME]
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
                        Re-fetch a registered catalog entry; --all for every
                        managed skill, --catalog to refresh the whole metadata
                        index
  --doctor              Diagnose drift between desired and on-disk skills
                        (read-only)
  --resolve NAME        Print the source path for a skill
```

<!-- /generated -->

## permission

The block below is `scripts/permission --help`, kept in sync by
`command-index-sync`.

<!-- generated: ../scripts/permission --help -->

```text
Usage: permission <command> [arguments]

Manage workspace-specific agent permissions.

Commands:
  add             Add a tool permission rule
  remove          Remove a tool permission rule (alias: rm)
  list            List permission rules (alias: ls)
  clean           Clear all workspace-specific permission rules

Options:
  --help          Display this help message and exit
```

<!-- /generated -->

<!-- markdownlint-restore MD013 -->

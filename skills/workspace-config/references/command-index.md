# Command Index

<!-- markdownlint-disable MD013 -->

## Contents

- [skill](#skill)
- [permission](#permission)
- [envrc](#envrc)

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
  suggest [DIR] [-] [PROMPT] Print advisory LLM skill recommendations guided by an
                          optional task prompt (pass '-' to read from stdin)
                          (requires google-genai)
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

## envrc

The block below is `scripts/envrc --help`, kept in sync by
`command-index-sync`.

<!-- generated: ../scripts/envrc --help -->

```text
Usage: envrc [options] <command> [args...]

Manage configuration blocks within a .envrc file. Blocks are delimited by
managed marker comments so multiple configurations can co-exist safely. The
'skills' block holds a list that can be edited item-by-item; the 'env' block
holds environment variables managed with set/unset/get.

Options:
  --output FILE  Path to the output file (default: .envrc)
  --help         Display this help message and exit

Commands:
  create <type> [args...]  Create a configuration block
  delete <type>            Delete an entire configuration block
  show <type>              Print a block's content
  add skills NAME...       Add skills to the skills block (creates it if needed)
  remove skills NAME...    Remove skills from the skills block (alias: rm);
                           names provided by the environment default are
                           excluded with a '-NAME' negation instead
  list [skills]            List active blocks, or the skills in the skills block
  set VAR VALUE            Set an environment variable in the env block
                           (creates the block if needed)
  unset VAR                Remove an environment variable from the env block
  get VAR                  Print a variable's value from any managed block
  catalog                  List available configuration types

Types:
  node [VERSION]           Adds Node.js direnv layout (default version: 24)
  ruby [VERSION]           Adds Ruby direnv layout (default version: 3.4)
  uv                       Adds Python uv direnv layout
  firebase <PROJECT_ID>    Adds Firebase project variables
  appengine <APP_ID> [URL] Adds Google App Engine variables
  skills [NAME...]         Adds the agent skills list (AGENT_REQUIRED_SKILLS)
  block <NAME>             Adds a raw block named NAME; content is read from
                           stdin

Examples:
  envrc create node 22
  envrc create uv
  envrc add skills adb jetpack
  envrc remove skills stillers
  envrc list skills
  envrc set API_ORIGIN https://api.example.com
  envrc get API_ORIGIN
  envrc create block corp <corp-fragment.sh
  envrc delete node

The skills block contains a 'skills NAME...' line (a direnv function defined
in ~/.direnvrc) that appends to the AGENT_REQUIRED_SKILLS environment
variable. Prefix a name with '-' or '!' to exclude a globally required skill;
'remove' writes the negation automatically when the name comes from the
environment default rather than from the block itself.

'set' writes single-quoted values, so values are always literal data: shell
syntax like $(...) is never evaluated when direnv loads the file. 'get' reads
the file statically (no shell is executed) and unquotes simple single- or
double-quoted values.
```

<!-- /generated -->

<!-- markdownlint-restore MD013 -->

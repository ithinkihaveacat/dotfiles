# Command Index

<!-- markdownlint-disable MD013 -->

## Contents

- [skill](#skill)
- [permission](#permission)
- [mcp](#mcp)
- [andon](#andon)

## skill

The block below is `scripts/skill --help`, kept in sync by
`command-index-format`.

<!-- generated: ../scripts/skill --help -->

```text
Usage: skill [-C DIR] [--scope SCOPE] <command> [skill...]

Manage agent skills as untracked symlinks, in the directories each installed
agent reads for the chosen scope:
  user       ~/.claude/skills (Claude) and ~/.agents/skills (Codex, Agy)
  workspace  .claude/skills and .agents/skills at the repository's skill
             anchor, plus a block in .git/info/exclude (the default)
  session    the calling agent's own session: $AGENT_SESSION_DIR/.claude/skills
             (Claude) or brain/<id>/scratch/skills + .agents/skills.json (Agy);
             only launchers that give a session its own directory support it
             (not 'claude remote-control' or Codex; see the agent-config
             skill, references/model.md)
  defaults   the default skills, which no agent reads; 'add --defaults' links
             each one into a workspace, session or user through this directory

Commands:
  add SPEC...     Link a skill straight to its source: a catalog entry from
                  'skill catalog', as NAME or NAMESPACE:NAME (replaces a
                  default's link)
  add -           Read skill names from stdin
  add --defaults  Link every default through the defaults directory, keeping
                  existing links; remove broken links to defaults (broken
                  links added by name are kept, with a warning); then fail if
                  'doctor' finds errors. Outside
                  a repository or plugin-recognized workspace, does nothing
                  unless the directory already has a skill folder
                  -q, --quiet: report only errors and warnings
  remove NAME...  Remove a skill's links and exclude entries (alias: rm)
  list [--json]   List linked skills, each 'default' or 'added', in the scope
  clean           Remove all skill links in the scope (and git excludes)
  doctor [--json] Check the scope's links and the catalog (read-only)
  bundle [SPEC...] Package skills into an archive or directory without installing
  update SPEC...  Re-fetch a plugin-provided catalog entry; --all for every
                  entry, --catalog to refresh the whole metadata index
  catalog [--json] List plugin-provided skills and sources; --json adds each
                  skill's description and structural profile (file counts and
                  sizes for scripts/, references/ and tests/)
  resolve NAME    Print the source path 'add NAME' would symlink to
  show/info NAME  Show details and metadata of a skill

Options:
  -C, --directory DIR  Run as if started in DIR instead of the current directory
  --scope SCOPE        'user', 'workspace' (default), 'session' or 'defaults';
                       only add, remove, list, doctor and clean take a scope
                       other than 'workspace'
  --help, -h           Display this help message and exit
  --plugin-template    Output a template/documentation for creating a Workspace plugin

Environment:
  AGENT_OFFLINE      Set to 1 to never fetch remote skills, serving whatever
                     has already been downloaded (at any age) instead. A skill
                     that has never been fetched is an error, not a guess.
  AGENT_SESSION_DIR  Session directory for --scope session under Claude; set
                     with AGENT_SESSION_ID by the claude wrapper, and honored
                     only while AGENT_SESSION_ID matches CLAUDE_CODE_SESSION_ID
  SKILL_CACHE_DIR    Cache directory for remote skills and catalog metadata
                     (default: ${XDG_CACHE_HOME:-$HOME/.cache}/skill)
  SKILL_DEFAULTS_DIR Directory of the defaults scope
                     (default: ${XDG_STATE_HOME:-$HOME/.local/state}/skill/defaults)

Examples:
  skill add coding-standards
  skill --scope session add jetpack
  skill --scope defaults add workspace-tools
  skill add --defaults
  printf '%s\n' adb emumanager | skill --scope session add -
  skill list --json
```

<!-- /generated -->

## permission

The block below is `scripts/permission --help`, kept in sync by
`command-index-format`.

<!-- generated: ../scripts/permission --help -->

```text
Usage: permission <command> [arguments]

Manage agent tool and filesystem permissions across all detected local
agents (Jetski CLI & Web, Antigravity, Claude Code, and Codex).

Namespaces:
  cmd add PATTERN...       Add command patterns to allowlist (--deny / --ask)
  cmd remove PATTERN...    Remove command patterns (alias: rm)
  cmd list                 List command rules per agent (alias: ls)

  path add PATH...         Grant access to filesystem directories (--ro for read-only)
  path remove PATH...      Revoke filesystem directory access (alias: rm)
  path list                List granted paths per agent (alias: ls)

Commands:
  list                     List all permission rules (commands and paths; alias: ls)
  apply                    Pre-approve safe commands and paths from installed skills
  clean [cmd|path]         Clear configured permission rules (default: all)
  doctor                   Report missing or drifted rules across commands and paths

Options:
  --agent NAME             Operate on a single agent backend
                           (agy, jetski, jetski-web, claude, codex)
  --help                   Display this help message and exit
  --plugin-template        Output a template/documentation for creating a Permission plugin

Agents:
  agy, jetski,       Antigravity / Jetski CLI & Web. User-wide: rules live in
  jetski-web         ~/.gemini/antigravity-cli/settings.json (agy),
                     ~/.gemini/jetski/cli/settings.json (jetski CLI), and
                     ~/.gemini/config/config.json (jetski-web; also synced by
                     jetski when ~/.gemini/config exists) and apply to every
                     workspace. Command patterns become command(regex:...)
                     rules; native resource grants (e.g. read_file(*)) are
                     preserved verbatim. Path grants become read_file/write_file
                     grants and enable allowNonWorkspaceAccess.
  claude             Claude Code. Workspace-local for commands (.claude/settings.local.json);
                     path grants update additionalDirectories and Read/Write rules
                     (workspace-local or user-wide via --global in ~/.claude/settings.json).
                     Patterns become Bash(PATTERN:*) prefix rules; deny beats ask
                     beats allow. 'allow' only skips the approval prompt and
                     leaves Claude Code's sandbox settings unchanged.
  codex              Codex CLI. Workspace-local: rules live in the untracked
                     .codex/rules/permission.rules, which Codex loads only for
                     trusted projects. Path grants update
                     ~/.gemini/trustedFolders.json. Patterns become prefix_rule()
                     token prefixes; ask and deny map to Codex's prompt and
                     forbidden, and the most restrictive match wins. 'allow'
                     also runs the command outside the Codex sandbox without
                     prompting, a stronger grant than the other agents give.
```

<!-- /generated -->

## mcp

The block below is `scripts/mcp --help`, kept in sync by `command-index-format`.

<!-- generated: ../scripts/mcp --help -->

```text
Usage: mcp <command> [options] [arguments]

Manage the MCP servers configured for each installed agent: Claude Code
(claude), Codex (codex) and OpenCode (opencode).

Commands:
  list [--json]              List configured servers per agent and scope
                             (alias: ls)
  add NAME URL               Add a remote (streamable HTTP) server
  add NAME -- COMMAND [ARG...]
                             Add a local (stdio) server
  remove NAME...             Remove servers from the scope (alias: rm)
  doctor                     Check that each agent's MCP configuration is
                             usable (read-only)

Options:
  --agent NAME               Operate on one agent (claude, codex or opencode);
                             by default, every installed agent
  --scope SCOPE              'user' or 'workspace'; add and remove default to
                             'user', list and doctor read both
  -e, --env KEY=VALUE        (add) Environment variable for a stdio server;
                             repeatable
  -H, --header 'NAME: VALUE' (add) HTTP header for a remote server; repeatable
  --json                     (list) Print servers as a JSON array
  -h, --help                 Display this help message and exit

Scopes:
  user       claude: mcpServers in ~/.claude.json; codex: ~/.codex/config.toml;
             opencode: ~/.config/opencode/opencode.json(c)
  workspace  claude: the repository's entry in ~/.claude.json (Claude's local
             scope, where add writes) and .mcp.json (Claude's project scope);
             opencode: opencode.json(c) or .opencode/opencode.json(c) at the
             repository root; codex has no workspace scope

Examples:
  # Add a remote server for every installed agent
  mcp add context7 https://mcp.context7.com/mcp

  # Add a stdio server to Claude Code only, for this repository
  mcp add --agent claude --scope workspace everything -- npx -y @modelcontextprotocol/server-everything

  # Pass a token through from the environment at add time
  mcp add api https://mcp.example.com/mcp --header "Authorization: Bearer $API_TOKEN"

  # Name the servers some agent has but Codex lacks
  mcp list --json | jq -r 'group_by(.name)[] | select(all(.agent != "codex")) | .[0].name'

add and remove run each agent's own CLI (claude mcp, codex mcp, opencode mcp
add); OpenCode has no remove command, so remove edits its config file and
keeps the file's comments. add skips an agent that already has the server in
the scope, and refuses before changing anything when an agent cannot take the
server (codex mcp add cannot set headers). add does not log in to a remote
server that uses OAuth; use the agent's own login (claude: /mcp, codex: codex
mcp login NAME, opencode: opencode mcp auth NAME). --env and --header values
are written as given; list shows only their names.
```

<!-- /generated -->

## andon

The shared store, triage CLI and stdio MCP server behind Andon. Agents can pull
through a harness plugin or MCP; people and fix sessions can list, inspect,
resolve and dismiss alerts. See [Andon MCP](andon-mcp.md) for the MCP interface.

### Help

<!-- generated: ../scripts/andon --help -->

```text
usage: andon [-h] COMMAND ...

Record and triage Andon alerts: defects agents report in their own instructions, skills and tools.

positional arguments:
  COMMAND
    pull            Pull the cord: record a new alert
    list            List alerts, newest first
    show            Show one alert in full
    prompt          Print a Markdown fix prompt that ends by resolving the
                    alert
    resolve         Mark an alert resolved
    dismiss         Mark an alert dismissed (not a real defect)
    reopen          Reopen a resolved or dismissed alert
    stats           Count alerts by status, color, kind, source and
                    fingerprint
    level           Print or set the default trigger level
    clear-resolved  Delete every resolved and dismissed alert
    mcp             Serve Andon tools over MCP (stdio only)

options:
  -h, --help        show this help message and exit

Examples:
  andon list --color red
  andon show e790
  andon resolve e790 --all-matching --note "Fixed the script path in SKILL.md"

  # Hand an alert to a fresh agent, which fixes the source and resolves it
  andon prompt e790 | claude -p

  # Serve tools to a local MCP client
  andon mcp --stdio

Agents pull the cord through their harness integration (a native tool), not
this command. Alerts live in $ANDON_STATE_DIR, else
${XDG_STATE_HOME:-~/.local/state}/andon. Reads never take the store's lock, so
list, show, prompt and stats work from a read-only sandbox.

Environment:
  ANDON_STATE_DIR  Directory holding events.jsonl and config.json.
  ANDON_LEVEL      Default trigger level (1-5); overrides 'andon level'.
```

<!-- /generated -->

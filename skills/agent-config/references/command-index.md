# Command Index

<!-- markdownlint-disable MD013 -->

## Contents

- [skill](#skill)
- [permission](#permission)

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

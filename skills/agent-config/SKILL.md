---
name: agent-config
description: >-
  Configures, governs and inspects coding agents: which skills each agent sees
  in a workspace, a single session, or user-wide, and the defaults every
  workspace gets (skill); which commands and directories Claude Code, Codex,
  and Antigravity may use, including the safe commands skills declare
  (permission); which MCP servers Claude Code, Codex and OpenCode connect to
  (mcp); and the defects agents report in their own instructions, skills and
  tools (andon). Use when installing, removing, choosing, bundling, or auditing
  agent skills; adding per-session or default skills; granting, restricting,
  or debugging agent command or directory permissions; writing a skill's
  permissions/unsafe file; listing, adding, removing, or checking MCP servers
  across agents; or installing the Andon plugin for Claude Code or OpenCode and
  triaging Andon alerts.
compatibility: >-
  Requires git and python3. Optional: uv, claude, codex, agy, or opencode.
---

# Agent Config

This skill sets up and governs the coding agents that work in a workspace: what
they see, what they may do, and what they are told. It consists of:

1. **`skill`**: The skill manager. Installs and tracks skills as untracked
   symlinks, automatically adapting to the environment (Git, Perforce, session
   artifact directories, or unmanaged directories; more via plugins). It is
   fully deterministic and dependency-free: it also enumerates what is
   installable (`skill catalog`) and manages remote plugin caching, but never
   calls a model to decide what a workspace needs — see
   [Choosing Skills (Workspace vs. Session)](#choosing-skills-workspace-vs-session).
1. **`permission`**: The permission manager. Maintains allow/deny/ask rules for
   every detected local agent (workspace-local for Claude Code and Codex,
   user-wide for Antigravity), including pre-approving the safe commands
   declared by installed skills.
1. **`mcp`**: The MCP server manager. Lists, adds, removes and checks the MCP
   servers each installed agent (Claude Code, Codex, OpenCode) is configured
   with, user-wide or for the workspace, through each agent's own CLI.
1. **`andon`**: The Andon cord. Records and triages defects agents report in
   their own instructions, skills, rules and tools, through harness plugins for
   Claude Code and OpenCode (`plugins/andon`).

For Git repositories, `skill add --defaults` and `permission apply` run
automatically on `git clone` via the global template's post-checkout hook (with
`hook apply` from the `workspace-tools` skill).

______________________________________________________________________

## Managing Skills (`skill`)

The `skill` tool (symlinked in `bin/`) manages agent skills as untracked
symlinks in your workspace or active session. It automatically detects your
environment and applies the correct tracking and ignoring mechanism.

```bash
skill <command> [arguments]
```

### Supported Environments & Scopes

- **Git Repositories (Workspace-Scoped / Persistent)**: Links skills under
  `.agents/skills/` and `.claude/skills/` for all sessions operating in the
  repository. A marker block in `.git/info/exclude` is dynamically generated to
  keep `git status` clean without dirtying the shared `.gitignore`. If another
  tool rewrites the exclude file, `skill doctor` detects the drift, and any
  `skill add` or `skill remove` rewrites the block.
- **Session Scope (Per-Session / Ephemeral / Temporary / Scratch)**:
  `skill --scope session add|remove|list|doctor|clean` manages the skills of the
  calling agent's own conversation, without touching the repository, `.envrc` or
  `~/.claude`:
  - **Claude Code** (started through the `claude` fish wrapper): links under
    `$AGENT_SESSION_DIR/.claude/skills`. The wrapper passes that directory to
    `claude --add-dir` and binds it to the session ID, so a nested agent
    (`claude -p`, `codex exec`) cannot write into it. Claude loads a newly added
    skill within the same turn.
  - **Antigravity & Jetski** (the session's `brain/<id>` directory, e.g.
    `~/.gemini/antigravity-cli/brain/<id>`, found from
    `ANTIGRAVITY_CONVERSATION_ID` or from `-C <artifactDir>`): links under
    `scratch/skills/` (hidden from the artifact UI watcher and auto-allowed for
    `view_file` reads) and writes `.agents/skills.json` +
    `.agents/skills.json.metadata.json` (`userFacing: false`). The harness loads
    newly added skills into `<skills>` on the next turn; to use one in the
    current turn, read `<artifactDir>/scratch/skills/<skill>/SKILL.md` directly.
- **User Scope**: `skill --scope user ...` links into `~/.claude/skills` and
  `~/.agents/skills` for every session of the user, leaving Claude's own
  `~/.claude/skills/synced/` alone. It is meant to stay empty on a long-lived
  machine; in an ephemeral per-project environment, where the user is the
  project, `skill --scope user add --defaults` seeds it (never implicit).
- **Defaults Scope**: `skill --scope defaults add|remove NAME...` manages the
  default skills, a directory no agent reads
  (`${XDG_STATE_HOME:-~/.local/state}/skill/defaults`). `skill add --defaults`
  links each default into a workspace, session or user scope *through* that
  directory, so removing a default breaks its links everywhere and the next
  `skill add --defaults` clears them. A skill added by name links straight at
  its source and survives that. The defaults are set by `etc/skill/defaults.sh`
  in the dotfiles and each overlay, which `install.sh` runs.
- **Unmanaged Directories**: Works in plain directories without VCS, symlinking
  skills under local destination folders. `skill add --defaults` leaves such a
  directory alone unless it already has a skill folder
  (`mkdir -p .agents/skills` opts in), so launching an agent from an arbitrary
  directory writes nothing there.
- **Plugins**: Additional workspace types can be registered by dropping a Python
  file into `~/.config/skill/plugins/` that defines `register(api)` and calls
  `api.register_workspace(cls)` with a subclass of `api.Workspace` (see also
  `api.FileStateMixin`) implementing a `detect()` classmethod. Plugin detectors
  run before the built-in ones, in sorted filename order.

### Global Options

- **`-C, --directory DIR`**: Run as if started in `DIR` instead of the current
  working directory.
- **`--scope SCOPE`**: Where to install: `user`, `workspace` *(default)*,
  `session` or `defaults` (see above). Only `add`, `remove`, `list`, `doctor`
  and `clean` take a scope other than `workspace`.

### Commands

- **`add SPEC...`**: Link a skill (a catalog entry from `skill catalog`, as
  `NAME` or `NAMESPACE:NAME`) straight to its source, replacing a default's link
  of the same name.
- **`add --defaults`**: Link every default through the defaults directory,
  keeping any existing link, and remove broken links to defaults; then fail if
  `doctor` would report an error. A broken link to a skill added by name is kept
  with a warning, since its source may only be unreachable for now (an unmounted
  network path, a pruned cache). Concurrent runs in one scope take turns.
  `-q`/`--quiet` reports only errors and warnings.
- **`remove NAME...`** (alias: **`rm`**): Remove a skill's links.
- **`list [--json]`**: List the linked skills, each `default` or `added`.
- **`bundle [SPEC...]`**: Package skills into an archive (`.zip`, `.tar.gz`) or
  directory without installing them (`-w`/`--workspace` for the skills linked in
  the workspace).
- **`update SPEC...`**: Re-fetch a plugin-provided catalog entry (`--all` for
  all, `--catalog` for the catalog index).
- **`clean`**: Remove all skill links in the scope and clear tracking records.
- **`doctor [--json]`**: Check the scope's links (broken links, unmanaged files,
  exclude records) and the catalog (read-only).
- **`catalog [--json]`**: List all plugin-provided skills and their sources.
  `--json` emits one object per skill with its description and structural
  profile — the discovery primitive described in
  [Choosing Skills (Workspace vs. Session)](#choosing-skills-workspace-vs-session).
- **`resolve NAME`**: Print the source path a skill name would resolve to.

### Choosing Skills (Workspace vs. Session)

Choosing skills is the calling agent's job. `skill` enumerates what exists and
installs what it is told; the agent decides what belongs in the workspace or
session based on project files, tech stack, and user goals. The tool itself is
fully deterministic and requires no API keys.

1. **Survey the catalog:** Run `skill catalog --json` to inspect all available
   skills in a single call (JSON Lines). Each record includes frontmatter
   (`name`, `description`), origin (`source`, `namespace`, `plugin`), and
   structural metrics:
   - `scripts`: Count of executable CLI tools (pre-approved for local agents by
     `permission apply`).
   - `references`: Count of reference guides, schemas, or architectural docs.
   - `tests`: Count of test suites verifying tool behavior.
   - `status`: `local` (on disk), `cached` (downloaded remote), `remote` (known
     from cached frontmatter; structure is `null`), or `missing`.
1. **Apply confirmed choices:** Explain recommendations to the user and install
   confirmed selections according to the desired scope:
   - **Workspace-scoped (persistent across sessions):**
     ```bash
     skill add <names>
     ```
   - **Per-session (ephemeral / temporary / session-scoped / scratch):** When a
     skill is only needed for the active conversation, add it to the session
     scope so `.envrc` and repository exclusions remain untouched:
     ```bash
     skill --scope session add <names>
     ```

`skill catalog` represents the local and plugin-registered inventory. If
external or enterprise discovery systems exist in the environment, query those
as well before making recommendations. Listing the catalog never downloads a
repository, so it works unchanged under `AGENT_OFFLINE=1`.

### Environment

Variable names follow a two-tier rule: `AGENT_*` variables are **policy** a
human sets (what agents should do in this workspace); `SKILL_*` variables are
**plumbing** for this tool (how it finds and links things, rarely touched).

- `AGENT_PREFLIGHT_SKIP`: When set, the `claude`, `codex` and `agy` wrappers
  launch without seeding the defaults or checking skill health — e.g.
  `AGENT_PREFLIGHT_SKIP=1 claude`. (The legacy spelling `_agent_preflight_skip`
  is still honored.)
- `SKILL_DEFAULTS_DIR`: The defaults scope's directory (default:
  `${XDG_STATE_HOME:-$HOME/.local/state}/skill/defaults`).
- `SKILL_SOURCE_DIRS`: Optional colon-separated environment variable override
  searched for skills by name (by default, local skills are discovered
  automatically from standard workspace and configuration directories via the
  `05_local.py` plugin).
- `SKILL_DEST_DIRS`: Colon-separated link destinations relative to the workspace
  root (default: `.claude/skills:.agents/skills`).
- `SKILL_CACHE_DIR`: This tool's cache directory for remote skills and catalog
  metadata (default: `${XDG_CACHE_HOME:-$HOME/.cache}/skill`).
- `AGENT_OFFLINE`: Set to `1` to serve remote skills from that cache instead of
  fetching them — what a CI job or a network-denied agent sandbox needs, so an
  agent launch does not depend on GitHub being reachable. A skill that has never
  been fetched is a clear error rather than a silent omission. See local
  workspace caching guidelines.

For the underlying model — the scopes, how a link records where it came from,
and who seeds the defaults — see [The agent-config model](references/model.md).

______________________________________________________________________

## Managing Workspace Permissions (`permission`)

The `permission` tool (symlinked in `bin/`) manages agent tool permissions.
Rules are written as clean command patterns (e.g. `"git show"`); each agent
backend translates them to its native syntax and scope:

- **`claude`** (Claude Code): `Bash(pattern:*)` rules in the workspace's
  `.claude/settings.local.json` (workspace-local personal settings; the tool
  ensures the file is git-ignored). Claude Code picks these up without a
  restart.
- **`agy` / `jetski` / `jetski-web`** (Antigravity, Jetski CLI, Jetski Web):
  `command(...)` rules and native resource grants (e.g. `read_file(*)`) in
  `~/.gemini/antigravity-cli/settings.json` (`agy`),
  `~/.gemini/jetski/cli/settings.json` (`jetski` CLI), and
  `~/.gemini/config/config.json` (`jetski-web` under
  `userSettings.globalPermissionGrants`; synced automatically alongside `jetski`
  when `~/.gemini/config` exists). Evaluated globally across workspaces.
- **`codex`** (Codex CLI): `prefix_rule(...)` entries in the dedicated
  `.codex/rules/permission.rules` file (workspace-local configuration). Clean
  `allow`/`ask`/`deny` modes map to Codex's `allow`/`prompt`/`forbidden`
  decisions. The dedicated file lets `clean` avoid touching hand-authored or
  organization-managed rules in neighboring `.rules` files. Codex loads project
  rules only after the workspace is trusted.

By default every command operates on all detected agents; use `--agent NAME` to
scope to one.

```bash
permission <command> [arguments] [options]
```

### Commands & Namespaces

- **`cmd add PATTERN...`**: Add rule patterns to the allowlist (`--deny` for the
  denylist, `--ask` for the always-prompt list). `cmd add -` reads one pattern
  per line from stdin.
- **`cmd remove PATTERN...`** (alias: **`rm`**): Remove command patterns from
  all lists.
- **`cmd list`** (alias: **`ls`**): List command rules per agent.
- **`path add PATH...`**: Grant directory access (`--ro` for read-only; default
  read and write; `--workspace` for workspace-local or `--global` for
  user-wide).
- **`path remove PATH...`** (alias: **`rm`**): Revoke directory access grants.
- **`path list`** (alias: **`ls`**): List granted paths per agent.
- **`list`** (alias: **`ls`**): List all permission rules (both commands and
  paths).
- **`apply`**: Pre-approve the safe commands and paths declared by this
  workspace's installed skills (idempotent; see below).
- **`clean [cmd|path]`**: Clear permission rules for detected agents (default:
  all).
- **`doctor`**: Report missing rules or drifted settings across commands and
  paths (read-only; exits non-zero on problems).

### Safe-Command Declarations (`permissions/unsafe`)

`permission apply` walks the workspace's installed skills (via
`skill list --json`) and pre-approves **every executable in each skill's
`scripts/` directory**, except entries listed in that skill's optional
`permissions/unsafe` file (one pattern per line, `#` comments):

- A **bare script name** (e.g. `adb-settings-theme`) is never pre-approved; the
  command prompts normally.
- A **`script subcommand` line** (e.g. `packagename uninstall`) keeps the
  blanket allow for the script but guards that subcommand with an `ask` rule.

New scripts added to a skill are therefore pre-approved by default; only the
exceptions need maintaining. The `permission` tool's own mutating subcommands
(`cmd add`, `cmd remove`, `path add`, `path remove`, `clean`) are declared
unsafe so an agent can never edit its own allowlist unprompted.

### Codex permission behavior

Codex rules are written to the untracked workspace file
`.codex/rules/permission.rules`. In Codex, an `allow` decision runs the matching
command **outside the sandbox without prompting**; this is stronger than the
corresponding Claude Code and Antigravity allow rules. Review each skill's
`permissions/unsafe` declarations before applying its rules. Rules match token
prefixes, so shell operators and redirections are not covered, and a bare
command pattern does not match an invocation written with an absolute path.

### Plugins

Extra workspace-root markers (beyond `.git`, `.hg`, `.svn`) can be registered by
dropping a Python file into `~/.config/permission/plugins/` that defines
`register(api)` and calls `api.register_root_marker(".marker")`.

See the [Command Index](references/command-index.md) for full help details.

______________________________________________________________________

## Managing MCP Servers (`mcp`)

The `mcp` tool (symlinked in `bin/`) gives one view of the MCP servers that
Claude Code (`claude`), Codex (`codex`) and OpenCode (`opencode`) are configured
with, and adds or removes a server across all of them at once. By default every
command operates on each installed agent; use `--agent NAME` to scope to one.

```bash
mcp <command> [options] [arguments]
```

- **`list`** (alias: **`ls`**): One row per agent, scope and server, with the
  transport and the command or URL. `--json` for scripts. Environment variables
  and headers are listed by name only.
- **`add NAME URL`** / **`add NAME -- COMMAND [ARG...]`**: Add a remote
  (streamable HTTP) or local (stdio) server, with `--env KEY=VALUE` (stdio) or
  `--header 'NAME: VALUE'` (remote), both repeatable. An agent that already has
  the server in the scope is skipped. The values are written as given, so pass
  secrets the way the agent expects them (for example OpenCode's `{env:NAME}`),
  not as literals, if the config should not hold them.
- **`remove NAME...`** (alias: **`rm`**): Remove servers from every agent that
  has them in the scope.
- **`doctor`**: Check that each config file parses, each stdio command resolves,
  each URL is an absolute http(s) URL, and each agent's CLI is on `PATH`
  (read-only; exits non-zero on problems).

Scopes (`--scope`; `add` and `remove` default to `user`, `list` and `doctor`
read both):

- **`user`**: `mcpServers` in `~/.claude.json`, `~/.codex/config.toml`, and
  `~/.config/opencode/opencode.json(c)`.
- **`workspace`**: Claude Code's local scope (the repository's entry in
  `~/.claude.json`, where `add` writes) and its shared `.mcp.json`; OpenCode's
  `opencode.json(c)` or `.opencode/opencode.json(c)` at the repository root.
  Codex has no workspace scope: `codex mcp` writes only to
  `~/.codex/config.toml`.

`add` and `remove` run each agent's own CLI (`claude mcp`, `codex mcp`,
`opencode mcp add`), so the agents' own validation and file handling apply.
OpenCode has no remove command, so `mcp remove` edits its config file and keeps
the file's comments. `add` does not log in to servers that use OAuth; finish
with the agent's own login (`/mcp` in Claude Code, `codex mcp login NAME`,
`opencode mcp auth NAME`). `add` and `remove` are declared in
`permissions/unsafe`, since they change which tools an agent has.

See the [Command Index](references/command-index.md) for full help details.

______________________________________________________________________

## Agent Plugins (`andon`)

`plugins/` holds harness plugins, one directory per plugin with one subdirectory
per agent harness. `plugins/.claude-plugin/marketplace.json` makes it a Claude
Code marketplace.

### andon

The Andon cord lets an agent report defects in its own instructions, skills,
rules and tools (a contradiction, a stale flag or path, a misbehaving tool) as
it works. The Claude Code plugin adds an always-on rule, a pre-approved
`mcp__andon__pull` tool, a status-line count, and a `/andon` board. Every
session writes to one store, `${XDG_STATE_HOME:-~/.local/state}/andon`, through
the `andon` CLI (`scripts/andon`, symlinked in `bin/`). See
[plugins/andon/README.md](plugins/andon/README.md) for the design.

**Claude Code:** install it once, from a terminal, at user scope. It then loads
in terminal and desktop Code tab sessions alike. The desktop app's + → Plugins
menu manages plugins, but adding this local-folder marketplace needs the
terminal:

```bash
claude plugin install andon --marketplace ~/.dotfiles/skills/agent-config/plugins
```

The plugin is read from this folder, so `/reload-plugins` picks up edits. In a
session, start a message with "andon level 5" or run `/andon level 5` to set the
trigger level for that conversation. `/andon level 4 --save` changes the default
for every session.

**OpenCode V2:** install from this checkout without editing JSON by linking it
into the auto-discovered global plugins directory:

```bash
mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/opencode/plugins"
ln -sn "$HOME/.dotfiles/skills/agent-config/plugins/andon/opencode" \
  "${XDG_CONFIG_HOME:-$HOME/.config}/opencode/plugins/andon"
```

If the destination already exists, inspect it first rather than replacing it.
Restart OpenCode if it does not pick up the link automatically. OpenCode's
`plugin add` command installs npm/Git packages, not local directories; the link
keeps this adapter beside its shared CLI. See
[OpenCode installation and usage](plugins/andon/opencode/README.md) for JSON
configuration alternatives and remote connections. Both harnesses share the
alert store and saved default level.

**MCP clients:** run `andon mcp --stdio` to expose reporting, inspection and
triage tools over stdin/stdout. MCP and CLI calls use the same operations and
store. This API does not install a harness adapter or inject the Andon rule. See
[Andon MCP](references/andon-mcp.md) for client configuration, tools and
attribution boundaries.

Triage with the CLI:

```bash
# Open alerts from every session, newest first, with recurrence counts
andon list

# A Markdown fix prompt that ends with the command that resolves the alert
andon prompt e790 | claude -p

# Close every alert that shares the fingerprint
andon resolve e790 --all-matching --note "Fixed the script path in SKILL.md"
```

______________________________________________________________________

## Usage Examples

### Setting Up a Workspace (Recommended for new workspaces)

Install the required hooks (`hook`, from the `workspace-tools` skill), the
default skills, and the pre-approvals for their safe commands, as a fresh
`git clone` does:

```bash
hook apply
skill add --defaults
permission apply
```

### Targeted Discovery

Inspect the catalog to identify skills relevant to a specific task or tech
stack:

```bash
skill catalog --json
skill info adb  # inspect full details and structure of a specific skill
```

### Bundling Skills for Portability

Package skills into a self-contained zip file or directory without installing:

```bash
skill bundle coding-standards personal-network -o skills.zip
skill bundle --workspace -o /tmp/project-skills/
```

### Adding Workspace Skills (Persistent)

Add a skill to the current repository workspace from the catalog or a local
path:

```bash
skill add coding-standards
skill add /path/to/custom-skill
```

The link persists across sessions until `skill remove`, and survives the skill
being dropped from the defaults. For single-session or temporary requests, see
[Adding Per-Session Skills](#adding-per-session-skills-ephemeral--temporary--scratch).
To make a skill a default for every workspace and session, add it to the
defaults (and to `etc/skill/defaults.sh`, so other machines get it too):

```bash
skill --scope defaults add coding-standards
```

### Adding Per-Session Skills (Ephemeral / Temporary / Scratch)

Install a skill temporarily for the active conversation session (also referred
to as *per-session*, *ephemeral*, *session-scoped*, *temporary*, or *scratch*
skills):

```bash
skill --scope session add coding-standards
taskgo skills <project> | skill --scope session add -   # a project's whole list
```

A session add skips, and reports as `already active`, a skill the current
directory's workspace already links to the same source, so a list can be piped
in whole without working out which skills are new.

Under Claude, the skill is linked under `$AGENT_SESSION_DIR/.claude/skills/` and
can be used in the same turn. Under Antigravity (`<artifactDir>` is the
session's `Artifact Directory Path`, e.g.
`~/.gemini/antigravity-cli/brain/<id>`), it is linked under
`<artifactDir>/scratch/skills/` and registered in
`<artifactDir>/.agents/skills.json`; read
`<artifactDir>/scratch/skills/<skill>/SKILL.md` directly to use it in the
current turn, as the harness injects it into `<skills>` only on subsequent turns
(the command says so after adding). Either way the repository's `.envrc` and
`.git/info/exclude` are left untouched.

If `skill --scope session` fails naming `AGENT_SESSION_DIR`, this agent has no
session directory of its own: Claude was not started through the `claude`
wrapper (for example, a `claude remote-control` server), was resumed with
`--continue` or the `--resume` picker, or the caller is a nested agent; Codex
has no session scope at all. Under Antigravity, pass `-C <artifactDir>`.
Otherwise fall back to the workspace scope, or ask the user. Which launchers
support session skills, and what a new launcher needs to, is in
[Launchers and per-session skills](references/model.md#launchers-and-per-session-skills).

### Managing Permissions by Hand

```bash
permission cmd add "git show" "git log"   # allow commands on every detected agent
permission cmd add --deny "rm -rf"        # block command outright
permission cmd add --ask "adb-tile-add" --agent claude
permission path add ~/.dotfiles ~/.corp   # grant directory access
permission list                           # list commands and paths
```

### Health Checks

```bash
skill doctor          # broken links and exclude drift (read-only)
permission doctor     # missing pre-approvals (read-only)
mcp doctor            # unparsable configs, missing commands, bad URLs
skill add --defaults  # link the defaults and remove broken default links
```

A `.envrc` that still has a `skills` block from before the defaults scope is
migrated by `envrc migrate skills` (in the `workspace-tools` skill).

### Cleaning Up

Remove all installed skills and permission rules, restoring the workspace to its
original state:

```bash
skill clean
permission clean
```

## Reference Material

- **[Command Index](references/command-index.md)** — Detailed synopsis, options,
  and examples for `skill`, `permission`, `mcp` and `andon`.
- **[Andon plugin design](plugins/andon/README.md)** — How the Claude Code and
  OpenCode adapters share the `andon` store.
- **[The agent-config model](references/model.md)** — Scopes, link provenance,
  who seeds the defaults, and what `doctor` checks.

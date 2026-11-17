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
  across agents; installing the Andon plugin for Claude Code, OpenCode or Codex;
  or triaging Andon alerts.
compatibility: >-
  Requires git and python3. Optional: uv, claude, codex, agy, or opencode.
---

# Agent Config

This skill sets up and governs the coding agents that work in a workspace: what
they see, what they may do, and what they are told. It consists of:

1. **`skill`**: The skill manager. Installs baseline defaults as symlinks in the
   user scope (`--scope user`) and workspace/session skills as real directory
   copies stamped with `metadata.source` in `SKILL.md` frontmatter, adapting to
   each environment (Git, Perforce, session artifact directories, or unmanaged
   directories; more via plugins). It is fully deterministic and
   dependency-free: it also enumerates what is installable (`skill catalog`) and
   manages remote plugin caching, but never calls a model to decide what a
   workspace needs — see
   [Choosing Skills (Workspace vs. Session)](#choosing-skills-workspace-vs-session).
1. **`permission`**: The permission manager. Maintains allow/deny/ask rules for
   every detected local agent (workspace-local for Claude Code and Codex,
   user-wide for Antigravity), including pre-approving the safe commands
   declared by installed skills.
1. **`mcp`**: The MCP server manager. Lists, adds, removes and checks the MCP
   servers each installed agent (Claude Code, Codex, OpenCode) is configured
   with, user-wide or for the workspace, through each agent's own CLI, and reads
   the request logs of this repository's own MCP servers (`mcp logs`).
1. **`andon`**: The Andon cord. Records and triages defects agents report in
   their own instructions, skills, rules and tools, through harness plugins for
   Claude Code, OpenCode and local Codex (`plugins/andon`).

______________________________________________________________________

## Managing Skills (`skill`)

The `skill` tool (symlinked in `bin/`) manages agent skills across user,
workspace, and session scopes, automatically adapting to each harness's
directory conventions.

```bash
skill <command> [arguments]
```

### Supported Environments & Scopes

- **User Scope (Baseline Defaults — Symlinks)**: `skill --scope user ...` links
  symlinks into `~/.claude/skills`, `~/.agents/skills`, and
  `~/.gemini/config/skills` for every session of the user, leaving Claude's own
  `~/.claude/skills/synced/` alone. Baseline default skills are declared in
  `etc/skill/defaults` across `~/.dotfiles` and active overlays (plus optional
  `${XDG_CONFIG_HOME:-~/.config}/skill/defaults`) and declaratively reconciled
  by `install.sh`. Because `~/.gemini/config/skills` is a global discovery
  directory, symlinks to `~/.dotfiles` and overlays load natively in Antigravity
  and Jetski without workspace symlink confinement or `skills.json` files.
- **Session Scope (Per-Session / Ephemeral / Temporary / Scratch — Copies)**:
  `skill --scope session add|remove|prune|list|doctor|clean|update` installs
  real directory copies stamped with `metadata.source` in `SKILL.md` frontmatter
  into the calling agent's own conversation directory, without touching the
  repository or user scope:
  - **Claude Code** (started through the `claude` fish wrapper): copies under
    `$AGENT_SESSION_DIR/.claude/skills`. The wrapper passes that directory to
    `claude --add-dir` and binds it to the session ID, so a nested agent
    (`claude -p`, `codex exec`) cannot write into it. Claude loads a newly added
    skill within the same turn.
  - **Antigravity & Jetski** (the session's `brain/<id>` directory, e.g.
    `~/.gemini/antigravity-cli/brain/<id>`, found from
    `ANTIGRAVITY_CONVERSATION_ID` or from `-C <artifactDir>`): copies the skill
    directory under `<artifactDir>/.agents/skills/<name>/` with
    `metadata.source` in `SKILL.md` frontmatter. Being real regular files inside
    `brain/<id>`, every skill loads with 1-hop trajectory fidelity and passes
    non-global symlink confinement without a `skills.json` manifest. The harness
    loads newly added skills into `<skills>` on the next turn; to use one in the
    current turn, read `<artifactDir>/.agents/skills/<name>/SKILL.md` printed by
    `add`.
- **Git Repositories (Workspace-Scoped / Persistent — Copies)**: Copies skills
  under `.agents/skills/` and `.claude/skills/` with `metadata.source` in
  `SKILL.md` frontmatter so non-global symlink confinement never drops external
  skills in Antigravity or Jetski. A marker block in `.git/info/exclude` is
  dynamically generated to keep `git status` clean without dirtying the shared
  `.gitignore`. If another tool rewrites the exclude file, `skill doctor`
  detects the drift, and `skill prune`, `skill add`, or `skill remove` rewrites
  the block.
- **Unmanaged Directories**: Works in plain directories without VCS, copying
  skills under local destination folders with `metadata.source` in `SKILL.md`.
- **Plugins**: Additional workspace types can be registered by dropping a Python
  file into `~/.config/skill/plugins/` that defines `register(api)` and calls
  `api.register_workspace(cls)` with a subclass of `api.Workspace` (see also
  `api.FileStateMixin`) implementing a `detect()` classmethod. Plugin detectors
  run before the built-in ones, in sorted filename order.

### Global Options

- **`-C, --directory DIR`**: Run as if started in `DIR` instead of the current
  working directory.
- **`--scope SCOPE`**: Where to install: `user`, `workspace` *(default)*, or
  `session` (see above). Only `add`, `remove`, `prune`, `list`, `doctor`,
  `clean`, and `update` take a scope other than `workspace`.
- **`--offline`**: Never fetch remote skills or metadata over the network (same
  as `AGENT_OFFLINE=1`).

### Commands

- **`add [-q] [-p|--prune] SPEC...`**: Install a skill (a catalog entry from
  `skill catalog`, as `NAME` or `NAMESPACE:NAME`, or a local skill directory
  path) into the chosen scope (`-` reads skill names from `stdin`;
  `-q`/`--quiet` suppresses informational output; `-p`/`--prune` removes
  unlisted managed entries in the scope).
- **`remove [-q] NAME...`** (alias: **`rm`**): Remove a skill's entries and
  exclude records.
- **`prune [-q]`**: Retire legacy indirect `.../skill/defaults` links, re-sync
  exclude records, and fail if `doctor` would report an error. A broken link or
  missing-source copy is kept with a warning, since its source may only be
  unreachable for now.
- **`list [--json]`**: List installed skills in the scope.
- **`bundle [SPEC...]`**: Package skills into an archive (`.zip`, `.tar.gz`) or
  directory without installing them (`-w`/`--workspace` for the skills installed
  in the workspace).
- **`update SPEC...`**: Refresh workspace/session copies from their
  `metadata.source` and re-fetch plugin-provided catalog entries (`--all` for
  all, `--catalog` for the catalog index).
- **`clean`**: Remove all managed skill entries in the scope and clear tracking
  records.
- **`doctor [--json]`**: Check the scope's links and copies (broken links,
  missing copy sources, drifted copies, unmanaged files, exclude records) and
  the catalog (read-only).
- **`catalog [--json]`**: List all plugin-provided skills and their sources.
  `--json` outputs NDJSON (one JSON object per line) with each skill's
  description and structural profile — the discovery primitive described in
  [Choosing Skills (Workspace vs. Session)](#choosing-skills-workspace-vs-session).
- **`resolve SPEC`**: Print the source path a skill name or path would resolve
  to.
- **`info SPEC`** (alias: **`show`**): Display a skill's resolved path,
  frontmatter description, total size, and per-directory file breakdown.
- **`mcp [SCOPE]`**: Serve skills over MCP to agents that cannot read them from
  disk (claude.ai, the mobile apps, cloud sessions). A TOML file
  (`SKILL_MCP_CONFIG`) maps each scope to skill names; nothing under `~/.corp`
  is served. Over stdio it serves one scope; with `--http`, every scope at
  `/mcp/SCOPE` and an unauthenticated `GET /up` for a proxy's health check.
  Without `--access-team` and `--access-aud` the HTTP server binds loopback
  only, for a local client or an authenticating proxy to front. With both (or
  `SKILL_MCP_ACCESS_TEAM` and `SKILL_MCP_ACCESS_AUD`), it may bind another
  address and requires a `Cf-Access-Jwt-Assertion` header on every other
  request, checked against the team's certificates. Its tools (`load_skill`,
  `read_file`, `search`, `edit_file`, which commits each edit) work with any
  client, and it implements the MCP Skills Extension (SEP-2640). Connect it only
  where the same skills are not installed locally, so each skill is not offered
  twice. Every request is a record in a JSON request log (`SKILL_MCP_LOG`, else
  `$XDG_STATE_HOME/skill/mcp.jsonl`) naming the method, tool, skill or URI,
  outcome and an edit's commit, never file text or edits; `mcp logs` reads it.
  The server is `scripts/skill-mcp`, which `permission apply` does not
  pre-approve; a copy or hardlink outside the skill tree must set
  `SKILL_MCP_SKILL_DIR` to the skill root. See `skill mcp --help`.

### Git-backed MCP edits

With `--push`, edits target the checked-out branch's configured remote upstream.
The normal path is commit then push, with no fetch. A rejected branch update
triggers fetch, merge and retry; each recovery cycle allows at most three push
attempts. Merges preserve the original edit commits; the reply's blob describes
the final merged file.

Unfinished Git operations and uncommitted repository changes are refused. Writes
hold a cross-process repository lock, and any earlier unpublished commits must
be pushed or reconciled before another edit is accepted. Authentication,
transport and hook failures do not trigger a merge. Failed pushes return an MCP
tool error, record `push=failed`, and preserve local commits. A conflicting
recovery merge is aborted; the caller must resolve the divergence before
retrying. No rebase, reset or force push is used.

### Choosing Skills (Workspace vs. Session)

Choosing skills is the calling agent's job. `skill` enumerates what exists and
installs what it is told; the agent decides what belongs in the workspace or
session based on project files, tech stack, and user goals. The tool itself is
fully deterministic and requires no API keys.

1. **Survey the catalog:** Run `skill --offline catalog --json` (or
   `skill catalog --json` when refreshing uncached remote frontmatter) to
   inspect all available skills in a single call. Output is NDJSON (one JSON
   object per line). Each record includes frontmatter (`name`, `description`),
   origin (`source`, `namespace`, `plugin`), and structural metrics:
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
     scope so repository exclusions remain untouched:
     ```bash
     skill --scope session add <names>
     ```

`skill catalog` represents the local and plugin-registered inventory. If
external or enterprise discovery systems exist in the environment, query those
as well before making recommendations. Listing the catalog never clones a remote
repository; without `--offline` (or `AGENT_OFFLINE=1`), it fetches missing or
expired remote `SKILL.md` frontmatter stubs over HTTPS.

### Environment

Variable names follow a two-tier rule: `AGENT_*` variables are **policy** a
human sets (what agents should do in this workspace); `SKILL_*` variables are
**plumbing** for this tool (how it finds and installs things, rarely touched).

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
- **`logs [PATH...]`**: Print the request records of this repository's MCP
  servers (`taskgo mcp`, `skill mcp`, `pinboard mcp`, `andon mcp`), merged
  oldest first from every `$XDG_STATE_HOME/*/mcp.jsonl` (with rotated files), or
  from the files and directories named. `-n/--tail N|all` (default 10),
  `--since 1h|2d|TIME`, `--server NAME` (repeatable), `-f/--follow` (survives
  rotation) and `--json` (one record per line, with `server` added). `--summary`
  prints statistics instead: outcomes; requests, failures and p50/p95 latency
  per server, client and tool; and the commonest two- and three-call sequences
  in each caller's chains (`--gap SECS`, default 120; `--json` for JSON).
  `--serve` (which must come first) serves one live page of the latest records
  and the summary, filterable by server, on port 8792: loopback only, or behind
  Cloudflare Access with `--access-team` and `--access-aud` (or
  `MCP_LOGS_ACCESS_TEAM` and `MCP_LOGS_ACCESS_AUD`), with an open `GET /up`. It
  runs `scripts/mcp-logs`; the record format is in
  [MCP request logs](references/mcp-logs.md).

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
`permissions/unsafe`, since they change which tools an agent has, and so is
`logs --serve`, which opens a port; reading logs stays pre-approved.

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

The plugin is read from this folder, so `/reload-plugins` picks up edits. Each
session locks in the configured trigger level (`$ANDON_LEVEL` > `config.json` >
`3`); run `/andon level 5` (or `andon level 5`) to change the shared default
level for new sessions, or `/andon level reset` to reset it to 3.

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

**ChatGPT desktop and Codex:** the
[local Andon plugin](plugins/andon/chatgpt/README.md) adds a live conversation
panel and global sidebar board over that MCP interface. Install it from the
included desktop marketplace after installing the shared CLI. In local Codex,
review and trust its hooks to activate the always-on reporting rule, passive
failure reminders, session-locked trigger levels and host-supplied report
attribution. The rule refreshes on each user turn and after compaction. The
panel shows alerts across harnesses. Other MCP clients retain the board and
tools without the Codex hooks.

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

Install the required git hooks (`hook`, from the `workspace-tools` skill) and
pre-approve the safe commands of user-scope and workspace skills:

```bash
hook apply
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
skill add adb
skill add /path/to/custom-skill
```

The copy persists across sessions until `skill remove` (refresh after upstream
edits with `skill update adb`). For single-session or temporary requests, see
[Adding Per-Session Skills](#adding-per-session-skills-ephemeral--temporary--scratch).
To make a skill a baseline default for every workspace and session, add it to
the user scope (and to `etc/skill/defaults` or `~/.config/skill/defaults`, so
`install.sh` preserves it):

```bash
skill --scope user add workspace-tools
```

### Adding Per-Session Skills (Ephemeral / Temporary / Scratch)

With a supported launcher (Claude wrapper or Antigravity/Jetski), install a
skill temporarily for the active conversation session (also referred to as
*per-session*, *ephemeral*, *session-scoped*, *temporary*, or *scratch* skills):

```bash
skill --scope session add jetpack
taskgo skills <project> | skill --scope session add -   # a project's whole list
```

A session add skips, and reports as `already active`, a skill that the user
scope or the current directory's workspace already provides from the same
source, so a list can be piped in whole without working out which skills are
new.

Under Claude, the skill is copied under `$AGENT_SESSION_DIR/.claude/skills/` and
can be used in the same turn. Under Antigravity/Jetski (`<artifactDir>` is the
session's `Artifact Directory Path`, e.g.
`~/.gemini/antigravity-cli/brain/<id>`), the skill directory is copied under
`<artifactDir>/.agents/skills/<skill>/` with `metadata.source` in `SKILL.md`
frontmatter; read `<artifactDir>/.agents/skills/<skill>/SKILL.md` printed by
`add` to use it in the current turn, as the harness injects it into `<skills>`
from the next turn onward. Either way the repository's `.git/info/exclude` is
left untouched; to edit the upstream skill itself, follow `metadata.source` in
`SKILL.md` (or run `skill resolve <skill>`).

OpenCode and Codex do not support this CLI's session scope. Reuse skills already
provided by the harness and use its skill loader for missing ones. For a local
skill outside that loader's inventory, run `skill resolve NAME` and read the
resolved directory's `SKILL.md` directly. Harness-provided skills need not exist
in the CLI catalog. Do not create workspace/user links merely to work around
missing session support.

If `skill --scope session` fails naming `AGENT_SESSION_DIR`, this agent has no
session directory of its own: Claude was not started through the `claude`
wrapper (for example, a `claude remote-control` server), was resumed with
`--continue` or the `--resume` picker, or the caller is a nested agent; Codex
has no session scope at all. Under Antigravity, pass `-C <artifactDir>`.
Otherwise read the resolved `SKILL.md` directly, or ask the user. Which
launchers support session skills, and what a new launcher needs to, is in
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
skill prune           # retire legacy default links and re-sync records
```

A `.envrc` that still has a legacy `skills` block is migrated by
`envrc migrate skills` (in the `workspace-tools` skill).

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
- **[MCP request logs](references/mcp-logs.md)** — The record format every MCP
  server writes and `mcp logs` reads.

---
name: workspace-config
description: Discover and select relevant agent skills, and manage workspace tool execution permissions. Use this to determine which skills apply to a workspace, to install or remove skills, and to manage allow/deny/ask rules for local agent tool execution across agents (Claude Code, Antigravity).
---

# Workspace Configuration

This skill configures a workspace for agent-assisted development without version
control ever seeing the configuration. It consists of two tools:

1. **`skill`**: The workspace manager. Installs and tracks skills as untracked
   symlinks, automatically adapting to the environment (Git, Perforce, or
   unmanaged directories; more via plugins). Also provides advisory LLM-based
   skill recommendations (`skill suggest`) and manages remote plugin caching.
1. **`permission`**: The permission manager. Maintains per-workspace
   allow/deny/ask rules for every detected local agent, including pre-approving
   the safe commands declared by installed skills.

`git-setup` ties these together for git repositories: it installs hooks, runs
`skill apply`, then `permission apply` (and `git-setup doctor` aggregates all
three doctors). It runs automatically on `git clone` via the global template's
post-checkout hook.

______________________________________________________________________

## 1. Managing Skills (`skill`)

The `skill` tool (symlinked in `bin/`) manages agent skills as untracked
symlinks in your workspace. It automatically detects your environment and
applies the correct tracking and ignoring mechanism.

```bash
skill <command> [arguments]
```

### Supported Environments

- **Git Repositories**: Links skills under `.agents/skills/` and
  `.claude/skills/`. A marker block in `.git/info/exclude` is dynamically
  generated to keep `git status` clean without dirtying the shared `.gitignore`.
  If another tool rewrites the exclude file, `skill doctor` detects the drift,
  and running `skill apply` resolves it.
- **Unmanaged Directories**: Works in plain directories without VCS, symlinking
  skills under local destination folders.
- **Plugins**: Additional workspace types can be registered by dropping a Python
  file into `~/.config/skill/plugins/` that defines `register(api)` and calls
  `api.register_workspace(cls)` with a subclass of `api.Workspace` (see also
  `api.FileStateMixin`) implementing a `detect()` classmethod. Plugin detectors
  run before the built-in ones, in sorted filename order.

### Commands

- **`apply`**: Synchronize workspace symlinks to match `AGENT_REQUIRED_SKILLS`
  (local-only, fast, and deterministic).
- **`suggest`**: Print recommendations without installing them (implements
  advisory LLM skill recommendations).
- **`add SPEC...`**: Add a skill (a local path or a plugin-provided catalog
  entry).
- **`remove NAME...`** (alias: **`rm`**): Remove a managed skill.
- **`list [--json]`**: List skills currently managed in this workspace.
- **`update SPEC...`**: Re-fetch a plugin-provided catalog entry (`--all` for
  all, `--catalog` for the catalog index).
- **`clean`**: Remove all managed skills and clear tracking records.
- **`doctor`**: Diagnose mismatch between desired and on-disk skills
  (read-only). Also warns when `AGENT_REQUIRED_SKILLS` looks stale relative to
  the workspace's `.envrc` skills declaration (fix: `direnv reload`).
- **`catalog`**: List all plugin-provided skills and their sources.
- **`resolve NAME`**: Print the source path a skill name would resolve to.

### Environment

Variable names follow a two-tier rule: `AGENT_*` variables are **policy** a
human sets (what agents should do in this workspace); `SKILL_*` variables are
**plumbing** for this tool (how it finds and links things, rarely touched).

- `AGENT_REQUIRED_SKILLS`: Space-separated skill names this workspace requires;
  prefix a name with `-` or `!` to exclude a globally required skill. Managed
  per-workspace via `envrc add skills` / `envrc remove skills` (`.envrc`).
- `AGENT_PREFLIGHT_SKIP`: When set, `skill preflight` passes without checking —
  bypass the agent launch gate once with `AGENT_PREFLIGHT_SKIP=1 claude`. (The
  legacy spelling `_agent_preflight_skip` is still honored.)
- `SKILL_SOURCE_DIRS`: Optional colon-separated environment variable override
  searched for skills by name (by default, local skills are discovered
  automatically from `~/.dotfiles/skills`, `~/.private/skills`,
  `~/.corp/skills`, and `~/.gemini/jetski/skills` via the `05_local.py` plugin).
- `SKILL_DEST_DIRS`: Colon-separated link destinations relative to the workspace
  root (default: `.claude/skills:.agents/skills`).

For the underlying model — what `apply` touches, the invariants `doctor` audits,
and the one place `doctor` and `preflight` deliberately differ — see
[The workspace-config model](references/model.md).

______________________________________________________________________

## 2. Managing Workspace Permissions (`permission`)

The `permission` tool (symlinked in `bin/`) manages workspace-specific agent
tool permissions. Rules are written as clean command patterns (e.g.
`"git show"`); each agent backend translates them to its native syntax:

- **`claude`** (Claude Code): `Bash(pattern:*)` rules in the workspace's
  `.claude/settings.local.json` (personal settings; the tool ensures the file is
  git-ignored). Claude Code picks these up without a restart.
- **`agy`** (Antigravity/jetski): `command(...)` rules in the per-project
  configuration under `~/.gemini`.

By default every command operates on all detected agents; use `--agent NAME` to
scope to one.

```bash
permission <command> [arguments] [options]
```

### Commands

- **`add PATTERN...`**: Add rule patterns to the allowlist (`--deny` for the
  denylist, `--ask` for Claude Code's always-prompt list). `add -` reads one
  pattern per line from stdin.
- **`remove PATTERN...`** (alias: **`rm`**): Remove patterns from all lists.
- **`list`** (alias: **`ls`**): List rules per agent, as clean patterns.
- **`apply`**: Pre-approve the safe commands declared by this workspace's
  installed skills (idempotent; see below).
- **`clean`**: Clear all permission rules for the workspace.
- **`doctor`**: Report rules that `apply` would add but that are missing
  (read-only; exits non-zero on problems).

### Safe-Command Declarations (`permissions/unsafe`)

`permission apply` walks the workspace's installed skills (via
`skill list --json`) and pre-approves **every executable in each skill's
`scripts/` directory**, except entries listed in that skill's optional
`permissions/unsafe` file (one pattern per line, `#` comments):

- A **bare script name** (e.g. `adb-settings-theme`) is never pre-approved; the
  command prompts normally.
- A **`script subcommand` line** (e.g. `packagename uninstall`) keeps the
  blanket allow for the script but guards that subcommand: an `ask` rule on
  Claude Code, a `deny` rule on agy.

New scripts added to a skill are therefore pre-approved by default; only the
exceptions need maintaining. The `permission` tool's own mutating subcommands
(`add`, `remove`, `clean`) are declared unsafe so an agent can never edit its
own allowlist unprompted.

### Plugins

Extra workspace-root markers (beyond `.git`, `.hg`, `.svn`) can be registered by
dropping a Python file into `~/.config/permission/plugins/` that defines
`register(api)` and calls `api.register_root_marker(".marker")`.

See the [Command Index](references/command-index.md) for full help details.

______________________________________________________________________

## 3. Managing `.envrc` (`envrc`)

The `envrc` tool (symlinked in `bin/`) is the single write path for `.envrc`
files: it manages marker-delimited configuration blocks so multiple
configurations co-exist safely and other tools never edit `.envrc` directly.

- **`create <type> [args...]`** / **`delete <type>`** / **`show <type>`**:
  Create, delete, or print a typed block (`node`, `ruby`, `uv`, `firebase`,
  `appengine`, `git-identity-beebo`, `skills`, or a raw `block NAME` whose
  content is read from stdin).
- **`add skills NAME...`** / **`remove skills NAME...`** / **`list [skills]`**:
  Edit the workspace's required-skills declaration item-by-item (see section 1).
- **`set VAR VALUE`** / **`unset VAR`** / **`get VAR`**: Manage individual
  environment variables in a managed `env` block. Values are written
  single-quoted, so they are always literal data — shell syntax is never
  evaluated when direnv loads the file — and `get` reads the file statically
  without executing any shell.

Because `envrc create block` writes arbitrary stdin content that direnv later
executes, it is declared unsafe (see `permissions/unsafe`) and always prompts.

See the [Command Index](references/command-index.md) for full help details.

______________________________________________________________________

## Usage Examples

### Default Discovery & Apply (Recommended for new workspaces)

Analyze the current directory, install the recommended skills, and pre-approve
their safe commands:

```bash
skill apply
permission apply
```

(Or just run `git-setup`, which also installs hooks.)

### Targeted Discovery (With Context)

If you have a specific task or hit a roadblock, ask for recommendations based on
your situation:

```bash
skill suggest --context "Goal: Implement a Wear OS tile in Kotlin. Emulator keeps crashing with OAuth errors."
```

### Manually Adding a Skill

Add a specific skill from the catalog or a local path:

```bash
skill add coding-standards
skill add /path/to/custom-skill
```

An ad-hoc `skill add` is pruned by the next `skill apply` unless the skill is
also declared in `AGENT_REQUIRED_SKILLS`. To persist it, record it in the
workspace's `.envrc` (the `envrc` command manages the declaration):

```bash
envrc add skills coding-standards
```

### Managing Permissions by Hand

```bash
permission add "git show" "git log"   # allow on every detected agent
permission add --deny "rm -rf"        # block outright
permission add --ask "adb-tile-add" --agent claude
permission list
```

### Health Checks

```bash
skill doctor       # symlink/exclude drift (read-only)
permission doctor  # missing pre-approvals (read-only)
skill apply        # synchronize and repair the workspace configuration
```

### Cleaning Up

Remove all installed skills and permission rules, restoring the workspace to its
original state:

```bash
skill clean
permission clean
```

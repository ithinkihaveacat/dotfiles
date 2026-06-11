---
name: workspace-config
description: Discover and select relevant agent skills, and manage workspace tool execution permissions. Use this to determine which skills apply to a workspace, to install or remove skills, and to manage allow/deny/ask rules for local agent tool execution across agents (Claude Code, Antigravity).
---

# Workspace Configuration

This skill configures a workspace for agent-assisted development without version
control ever seeing the configuration. It consists of three tools:

1. **`skill`**: The workspace manager. Installs and tracks skills as untracked
   symlinks, automatically adapting to the environment (Git, Perforce, or
   unmanaged directories; more via plugins).
1. **`skill-select`**: The discovery engine. Analyzes a workspace to suggest
   sensible default skills, or uses LLM-based selection when task context is
   provided. Also owns the plugins, network, and cache machinery.
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
  `.claude/skills/`. The authoritative managed list lives in `.git/info/skills`
  (inside the git dir, so it can never be tracked), and a marker block in
  `.git/info/exclude` is regenerated from it to keep `git status` clean without
  dirtying the shared `.gitignore`. If another tool rewrites the exclude file,
  `skill doctor` detects it and `skill repair` regenerates the block.
- **Perforce Workspaces**: Links skills under `.agents/skills/` and
  `.claude/skills/` and tracks them in `.p4-skills-managed` at the client root
  (untracked files are invisible to Perforce unless reconciled).
- **Unmanaged Directories**: Works in plain directories without VCS. Tracks
  skills in a local `.skills-managed` file.
- **Plugins**: Additional workspace types can be registered by dropping a Python
  file into `~/.config/skill/plugins/` that defines `register(api)` and calls
  `api.register_workspace(cls)` with a subclass of `api.Workspace` (see also
  `api.FileStateMixin`) implementing a `detect()` classmethod. Plugin detectors
  run before the built-in ones, in sorted filename order.

### Commands

- **`apply`**: Provision recommended skills for this workspace via
  `skill-select` (idempotent). Consults an LLM, so it needs network access.
- **`suggest`**: Print recommendations without installing them.
- **`add SPEC...`**: Add a skill (a local path or a plugin-provided catalog entry).
- **`remove NAME...`** (alias: **`rm`**): Remove a managed skill.
- **`list [--json]`**: List skills currently managed in this workspace.
- **`update SPEC...`**: Re-fetch a plugin-provided catalog entry (`--all` for all,
  `--catalog` for the catalog index).
- **`clean`**: Remove all managed skills and clear tracking records.
- **`doctor`**: Diagnose drift between desired and on-disk skills (read-only).
- **`repair`**: Re-link managed skills and regenerate tracking records.
- **`catalog`**: List all plugin-provided skills and their sources.
- **`resolve NAME`**: Print the source path a skill name would resolve to.

### Environment

- `SKILL_SOURCE_DIRS`: Colon-separated directories searched for skills by name
  (default: `~/.dotfiles/skills:~/.private/skills:~/.corp/skills` plus the
  catalog cache).
- `SKILL_DEST_DIRS`: Colon-separated link destinations relative to the workspace
  root (default: `.claude/skills:.agents/skills`).

______________________________________________________________________

## 2. Discovering Skills (`skill-select`)

Invoke the selection tool via `skill-select` (symlinked in `bin/`):

```bash
skill-select <command> [arguments]
```

### Commands

- **`suggest [DIR]`**: Recommend skills for a directory (default: current
  directory) via the Gemini API.
- **`catalog`**: List every available skill and its source.
- **`resolve NAME`**: Print the source path for a skill.
- **`update NAME...`**: Re-fetch plugin-provided catalog entries;
  `update catalog` refreshes the whole metadata index.
- **`doctor`** / **`repair`**: Diagnose / heal the catalog index.

### Options

- `--context TEXT` (`suggest`): A comprehensive, self-contained explanation of
  your task to guide LLM-based selection.
- `--search-dirs PATHS` (`suggest`, `catalog`, `resolve`): Colon-separated
  extra paths to search for skills, overriding `SKILL_SOURCE_DIRS`.
- `--json` (`suggest`, `catalog`): Emit structured JSON output instead of
  formatted text.

______________________________________________________________________

## 3. Managing Workspace Permissions (`permission`)

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

### Managing Permissions by Hand

```bash
permission add "git show" "git log"   # allow on every detected agent
permission add --deny "rm -rf"        # block outright
permission add --ask "adb-tile-add" --agent claude
permission list
```

### Health Checks

```bash
skill doctor       # symlink/state/exclude drift (read-only)
permission doctor  # missing pre-approvals (read-only)
skill repair       # re-link and regenerate tracking records
```

### Cleaning Up

Remove all installed skills and permission rules, restoring the workspace to its
original state:

```bash
skill clean
permission clean
```

# The agent-config model

<!-- markdownlint-disable MD013 -->

Maintainer reference for the `skill` tool: what it touches and why the pieces
fit together. User-facing usage lives in `../SKILL.md`.

## One provenance model on disk

`skill` keeps no separate state file of its own. The entries on disk are the
whole state:

- **`--scope user`** installs **symlinks** whose targets record the canonical
  skill directory directly.
- **`--scope workspace`** and **`--scope session`** install **real directory
  copies** whose `SKILL.md` YAML frontmatter records `metadata.source` pointing
  to the canonical skill directory.

## Scopes

`--scope` picks the directories a command acts on (`get_workspace()`):

| Scope       | Mechanism | Directories                                                                                                        | Class                                         |
| ----------- | --------- | ------------------------------------------------------------------------------------------------------------------ | --------------------------------------------- |
| `user`      | Symlinks  | `~/.claude/skills`, `~/.agents/skills`, and `~/.gemini/config/skills` (leaving Claude's `synced/` alone)           | `UserWorkspace`                               |
| `workspace` | Copies    | `.claude/skills` and `.agents/skills` at the repository's skill anchor (overridable with `SKILL_DEST_DIRS`)        | `GitWorkspace`, plugins, `DefaultWorkspace`   |
| `session`   | Copies    | `$AGENT_SESSION_DIR/.claude/skills` (Claude), or `brain/<id>/.agents/skills` in Antigravity / Jetski conversations | `ClaudeSessionWorkspace`, `AgyBrainWorkspace` |

The workspace scope refuses to run in the home directory itself, whose skill
folders are the user scope.

### User scope holds the baseline defaults

`etc/skill/defaults` in this repository and each active overlay (`~/.private`,
`~/.corp`), plus optional `${XDG_CONFIG_HOME:-~/.config}/skill/defaults` for
per-machine overrides, declare the curated baseline default skills (`-name`
excludes an earlier entry). `install.sh` feeds the combined list to
`skill --scope user add --prune --quiet -` and runs `skill --scope user doctor`:

1. Every harness (Claude Code, Codex, OpenCode, Antigravity, Jetski CLI and Web)
   reads its own standard global skill directory natively from Turn 0, where
   global customization discovery permits symlinks without confinement.
1. Removing a name from `etc/skill/defaults` automatically prunes its user-scope
   symlinks on the next `install.sh` run, leaving Claude's `synced/` and foreign
   non-symlink directories intact, and warning rather than deleting broken
   symlinks whose external source mount is temporarily unreachable.
1. Keeping `--scope user` focused on core non-overlapping substrate skills lets
   specialized or overlapping skills stay absent by default for clean
   per-project and per-session evaluation.

### Copies with `metadata.source` in workspace and session scopes

Antigravity and Jetski confine non-global customization roots (`<workspace>` and
`brain/<id>`), dropping symlinks whose targets live outside the workspace or
immutable depot snapshot roots. Installing real directory copies in both
`--scope workspace` and `--scope session` gives one uniform behavior across
every agent:

1. **No symlink confinement drops or 2-hop pointer stubs**: Every file in the
   copied skill (`SKILL.md`, `scripts/`, `references/`) sits directly inside
   `.agents/skills/<name>/` or `.claude/skills/<name>/` with 1-hop read
   fidelity. Internal symlinks in generated skills are dereferenced on copy, and
   transient caches (`.git`, `__pycache__`, `.ruff_cache`, `.pytest_cache`,
   `.DS_Store`) are excluded.
1. **Standard YAML provenance (`metadata.source`)**: `copy_skill_dir` merges
   `source: "<canonical-path>"` under `metadata:` in `SKILL.md` frontmatter
   using stdlib Python without duplicate YAML keys, conforming to the Agent
   Skills `metadata: map[string, string]` schema.
1. **Safe coexistence with tracked and hand-authored skills**: Every command
   checks `ws.is_tracked()` before `read_copy_source()`, so committed repository
   skills and hand-authored untracked skills without a local `metadata.source`
   are never overwritten or deleted.
1. **Missing-source visibility and refresh**: `skill doctor` flags copies whose
   `metadata.source` is missing, and `skill update` refreshes managed copies in
   place.

A Claude session directory (`$AGENT_SESSION_DIR/.claude/skills`) is honored only
while `AGENT_SESSION_ID` matches `CLAUDE_CODE_SESSION_ID` and no foreign session
variable (`CODEX_SESSION_ID`) is set, preventing nested agents from mutating
their parent's session. Antigravity is checked first, because `agy` started from
Claude inherits a matching Claude binding.

## Launch wrappers and commit hooks

Agent launch wrappers avoid Python/skill preflight overhead on CLI startup:

- **`claude.fish`** allocates a session-bound `TMPDIR` (`AGENT_SESSION_DIR`) and
  passes `--add-dir` + `--session-id` to `claude`.
- **`codex.fish`** configures local writable directories (`TMPDIR`,
  `~/.cache/uv`) and runs the pure-Bash `hook apply --quiet` when launched
  inside a Git repository other than `~`.
- **`opencode.fish`** resolves `~/.opencode/bin/opencode` or `PATH`.
- **PreToolUse commit-hook safety net**: `etc/agents/hooks/ensure-commit-hooks`
  lazily applies `AGENT_REQUIRED_HOOKS` (`hook apply --quiet`) right before any
  `git commit` tool call in Claude Code, Antigravity, Jetski, and OpenCode,
  covering IDE, web, and CLI sessions alike.

## Launchers and per-session skills

Skills for one session only (`--scope session`) are supported when the launcher
provides a session-owned directory, a non-inheritable way for `skill` to locate
it, and dynamic skill pickup:

| Launcher                                                 | Session skills | Why                                                                                                                                                                     |
| -------------------------------------------------------- | -------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `claude` fish wrapper                                    | Yes            | Copies in a fresh directory per launch, passed with `--add-dir` and bound to `--session-id`. Same turn.                                                                 |
| `claude --continue`, or the `--resume` picker            | No             | The wrapper cannot know the session ID, so the directory stays unbound.                                                                                                 |
| `claude remote-control` (a server for remote use)        | No             | It rejects `--add-dir`, and one server hosts many sessions.                                                                                                             |
| Antigravity / Jetski (`brain/<id>`)                      | Yes            | Copies in `brain/<id>/.agents/skills/<name>/`, found from `ANTIGRAVITY_CONVERSATION_ID` or `-C`. Next turn.                                                             |
| Antigravity Remote Control daemon (`agy remote-control`) | Expected yes   | Runs ordinary `agy` conversations on the daemon's machine, so `brain/<id>` and `ANTIGRAVITY_CONVERSATION_ID` apply as for the app; unverified from a dashboard session. |
| Codex                                                    | No             | No known per-session skill directory discoverable from `CODEX_SESSION_ID`.                                                                                              |
| OpenCode                                                 | No             | Reads the shared `.agents/skills` workspace directory, with no per-session skill directory.                                                                             |
| A nested agent (e.g. `codex exec` inside Claude)         | No             | Inherits its parent's binding, which `skill` refuses so the child cannot write into the parent's session.                                                               |

## Records and `doctor`

- **`GitWorkspace`** keeps a marker block (`# >>> skills >>>` …
  `# <<< skills <<<`) in `.git/info/exclude` listing every managed workspace
  entry, broken ones included, so `git status` stays clean without touching
  `.gitignore`. Every `add`, `remove`, and `clean` rewrites the block from disk
  (`sync_records()`).
- **`doctor`** is strictly read-only: it reports broken symlinks, copies whose
  `metadata.source` is missing, unmanaged files in skill folders (only a warning
  in the user scope, whose folders other installers share), and exclude records
  that do not match the entries on disk.

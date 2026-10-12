# The workspace-tools model

<!-- markdownlint-disable MD013 -->

Maintainer reference for the `skill` tool: what it touches and why the pieces
fit together. User-facing usage lives in `../SKILL.md`.

## An installer, not a reconciler

`skill` links skills where it is told to and keeps no expected set. There is no
declared list to compare against, nothing records what has already run, and
there is no "apply" step. The links on disk are the whole state, and each link's
target says where it came from.

## Scopes

`--scope` picks the directories a command acts on (`get_workspace()`):

| Scope       | Directories                                                                                                 | Class                                         |
| ----------- | ----------------------------------------------------------------------------------------------------------- | --------------------------------------------- |
| `workspace` | `.claude/skills` and `.agents/skills` at the repository's skill anchor (overridable with `SKILL_DEST_DIRS`) | `GitWorkspace`, plugins, `DefaultWorkspace`   |
| `session`   | `$AGENT_SESSION_DIR/.claude/skills` (Claude), or `scratch/skills` in an Antigravity `brain/<id>`            | `ClaudeSessionWorkspace`, `AgyBrainWorkspace` |
| `user`      | `~/.claude/skills` and `~/.agents/skills`, leaving Claude's `synced/` alone                                 | `UserWorkspace`                               |
| `defaults`  | `${SKILL_DEFAULTS_DIR:-${XDG_STATE_HOME:-~/.local/state}/skill/defaults}`, which no agent reads             | `DefaultsWorkspace`                           |

The workspace scope refuses to run in the home directory itself, whose skill
folders are the user scope. The user scope is meant to stay empty: every project
would see every skill.

A Claude session directory is honored only while `AGENT_SESSION_ID` matches the
caller's `CLAUDE_CODE_SESSION_ID` and no other agent's session variable
(`CODEX_SESSION_ID`) is set, so a nested agent cannot write into its parent's
session. The one caller with no `CLAUDE_CODE_SESSION_ID` is the `claude` wrapper
seeding the directory before Claude starts. Antigravity is checked first,
because agy started from Claude inherits a matching Claude binding.

## Link provenance

```text
<repo>/.claude/skills/jetpack -> ~/.local/state/skill/defaults/jetpack -> ~/.dotfiles/skills/jetpack
<repo>/.claude/skills/adb     -> ~/.dotfiles/skills/adb
```

- **Default** (indirect): created by `skill add --defaults`, which links every
  entry of the defaults directory through it. `list` shows `default`.
- **Added** (direct): created by `skill add NAME`, which links straight at the
  source and replaces an indirect link of the same name. `list` shows `added`.

Removing a default (`skill --scope defaults remove NAME`) deletes its one link
in the defaults directory, so every link to it breaks at once. Agents ignore a
broken link, and the next `add --defaults` removes it. A skill added by hand
points straight at its source, so it survives the demotion. Renaming a default
is a remove plus an add.

Every operation is safe to repeat: adding a default is idempotent, removing one
touches only the defaults directory, and seeding never replaces an existing
link.

## Who seeds what

- **Defaults** are set by `etc/skill/defaults.sh` in this repo and each overlay
  (`~/.private`, `~/.corp`), run by `install.sh`, so private skill names stay
  out of this repo and the launch path never edits the defaults.
- **Workspaces**: the clone hook (`post-checkout`) and the `codex`/`agy`
  wrappers run `skill add --defaults`.
- **Claude sessions**: the `claude` wrapper creates a fresh session directory
  and runs `skill --scope session add --defaults`, so a wrapped Claude always
  sees the current defaults and the workspace is left alone.

Each `skill` run costs about half a second, so each launch makes one call:
`add --defaults` ends with the error checks of `doctor` and fails if any remain
(`AGENT_PREFLIGHT_SKIP=1` launches anyway).

## Records

- **`GitWorkspace`** keeps a marker block (`# >>> skills >>>` …
  `# <<< skills <<<`) in `.git/info/exclude` listing every link, broken ones
  included, so `git status` stays clean without touching `.gitignore`.
- **`AgyBrainWorkspace`** writes `.agents/skills.json` (`include_only`, live
  links only) and `.agents/skills.json.metadata.json` (`userFacing: false`), so
  the harness loads `scratch/skills/` on the next turn without surfacing the
  files in the artifact UI.

Every `add`, `remove` and `clean` rewrites the records from disk
(`sync_records()`).

## Pruning

Broken-link cleanup is the only pruning, and only `add --defaults` does it.
Links tracked by version control are never removed. `doctor` is read-only: it
reports broken links, unmanaged files in the skill folders and records that do
not match the links, and never checks for expected skills. `doctor` fails on
warnings too; the check at the end of `add --defaults` fails only on errors.

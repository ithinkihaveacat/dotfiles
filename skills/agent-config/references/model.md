# The agent-config model

<!-- markdownlint-disable MD013 -->

Maintainer reference for the `skill` tool: what it touches and why the pieces
fit together. User-facing usage lives in `../SKILL.md`.

## An installer, not a reconciler

`skill` installs skills where it is told to and keeps no expected set. The
entries on disk are the whole state, and each symlink target or pointer stub
records its canonical source directory directly.

## Scopes

`--scope` picks the directories a command acts on (`get_workspace()`):

| Scope       | Directories                                                                                                    | Class                                         |
| ----------- | -------------------------------------------------------------------------------------------------------------- | --------------------------------------------- |
| `user`      | `~/.claude/skills`, `~/.agents/skills`, and `~/.gemini/config/skills` (leaving Claude's `synced/` alone)       | `UserWorkspace`                               |
| `workspace` | `.claude/skills` and `.agents/skills` at the repository's skill anchor (overridable with `SKILL_DEST_DIRS`)    | `GitWorkspace`, plugins, `DefaultWorkspace`   |
| `session`   | `$AGENT_SESSION_DIR/.claude/skills` (Claude), or `.agents/skills` pointer stubs in an Antigravity `brain/<id>` | `ClaudeSessionWorkspace`, `AgyBrainWorkspace` |

The workspace scope refuses to run in the home directory itself, whose skill
folders are the user scope.

### User scope holds the baseline defaults

`etc/skill/defaults.sh` in this repository and each overlay (`~/.private`,
`~/.corp`), run by `install.sh`, links the curated baseline default skills
straight into the user scope (`skill --scope user add --quiet ...`). Every
harness (Claude Code, Codex, OpenCode, Antigravity, Jetski CLI and Web) reads
its own standard global skill directory natively from Turn 0, with no
per-workspace symlink farms, `.git/info/exclude` churn, or `skills.json`
manifests.

To retire a default skill, replace its `add` entry in `etc/skill/defaults.sh`
with `skill --scope user remove --quiet NAME` so machines that already linked it
drop it on their next `install.sh` run.

### Session pointer stubs in `brain/<id>`

Antigravity and Jetski confine non-global customization paths (`<workspace>` and
`brain/<id>`), dropping symlinks whose resolved targets point outside those
roots. Instead of symlinking or copying whole skill directories into
`brain/<id>`, `AgyBrainWorkspace` writes a regular `SKILL.md` pointer stub at
`brain/<id>/.agents/skills/<name>/SKILL.md` carrying the skill's YAML `name` and
`description` plus a `<!-- skill-stub: <source> -->` marker and instructions
pointing straight at the canonical `<source>` directory:

1. **No confinement or `skills.json` dependency**: It is a plain regular file at
   the standard `.agents/skills/<name>/SKILL.md` path.
1. **Live in-session editing**: When the agent activates the skill, it reads
   `<source>/SKILL.md`, runs `<source>/scripts/`, and edits `<source>/`
   directly, so fixes made mid-session land in the canonical repository rather
   than a throwaway session copy.

A Claude session directory (`$AGENT_SESSION_DIR/.claude/skills`) has no symlink
confinement, so `ClaudeSessionWorkspace` uses direct symlinks. It is honored
only while `AGENT_SESSION_ID` matches `CLAUDE_CODE_SESSION_ID` and no foreign
session variable (`CODEX_SESSION_ID`) is set, preventing nested agents from
mutating their parent's session. Antigravity is checked first, because `agy`
started from Claude inherits a matching Claude binding.

## Launch wrappers and preflight

The `claude`, `codex`, `opencode`, and `agy` fish wrappers call
`_agent_preflight`, which runs `skill prune --quiet` and (inside a Git
repository other than `~`) `hook apply --quiet`:

- `skill prune --quiet` retires any leftover legacy `.../skill/defaults` links
  from older installations, re-syncs `.git/info/exclude` if needed, and fails
  only on `ERROR`-level `doctor` findings (`AGENT_PREFLIGHT_SKIP=1` launches
  anyway). Clean repositories without workspace skills are untouched.
- Inside a Git repository, `hook apply --quiet` ensures `AGENT_REQUIRED_HOOKS`
  are active before the session starts. As a safety net for sessions not started
  by a wrapper, `etc/agents/hooks/ensure-commit-hooks` runs `hook apply --quiet`
  before `git commit` tool calls.

## Launchers and per-session skills

Skills for one session only (`--scope session`) are supported when the launcher
provides a session-owned directory, a non-inheritable way for `skill` to locate
it, and dynamic skill pickup:

| Launcher                                          | Session skills | Why                                                                                                                     |
| ------------------------------------------------- | -------------- | ----------------------------------------------------------------------------------------------------------------------- |
| `claude` fish wrapper                             | Yes            | A fresh directory per launch, passed with `--add-dir` and bound to `--session-id`. Picked up the same turn.             |
| `claude --continue`, or the `--resume` picker     | No             | The wrapper cannot know the session ID, so the directory stays unbound.                                                 |
| `claude remote-control` (a server for remote use) | No             | It rejects `--add-dir`, and one server hosts many sessions.                                                             |
| Antigravity / Jetski (`brain/<id>`)               | Yes            | `brain/<id>/.agents/skills/<name>/SKILL.md` pointer stubs, found from `ANTIGRAVITY_CONVERSATION_ID` or `-C`. Next turn. |
| Codex                                             | No             | No known per-session skill directory discoverable from `CODEX_SESSION_ID`.                                              |
| OpenCode                                          | No             | Reads the shared `.agents/skills` workspace directory, with no per-session skill directory.                             |
| A nested agent (e.g. `codex exec` inside Claude)  | No             | Inherits its parent's binding, which `skill` refuses so the child cannot write into the parent's session.               |

## Records and `doctor`

- **`GitWorkspace`** keeps a marker block (`# >>> skills >>>` …
  `# <<< skills <<<`) in `.git/info/exclude` listing every workspace link,
  broken ones included, so `git status` stays clean without touching
  `.gitignore`. Every `add`, `remove`, `prune`, and `clean` rewrites the block
  from disk (`sync_records()`).
- **`doctor`** is strictly read-only: it reports broken links or broken stubs,
  unmanaged files in skill folders (only a warning in the user scope, whose
  folders other installers share), and exclude records that do not match the
  links on disk.

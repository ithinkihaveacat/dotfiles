# Agent Operational Guidelines

**Precedence:** Explicit user instructions > activated skills > general training
knowledge.

## Agent Skills

Available skills are curated for this environment and provide high-signal
workflows, helper scripts, and local conventions.

- **Use pre-loaded skills liberally**: Review your active skills before starting
  a task. When a task touches a skill's domain—or when in doubt—read its
  `SKILL.md` and follow its prescribed workflow and scripts rather than
  inventing an ad-hoc approach.
- **Load session-specific skills when relevant**: Default skills cover only
  baseline workflows. Whenever work touches—or later shifts to—a repository or
  technology stack not covered by active skills, delegate a subagent to check
  `skill catalog --json` and activate matching skills with
  `skill --scope session add <NAME>...` (or use other skill-search tools if
  available).
- **Skill symlinks and relative paths**: Installed skill directories are
  symlinks, so cross-skill links (`../<sibling>/...`) must be resolved against
  the symlink's `realpath` (or activated via `skill --scope session add`), and
  repo-relative commands run from the target repository root.
- **Common skill triggers**:
  - **Android & Wear OS devices**: Use the relevant device skill's exact `adb`
    commands and scripts (e.g., for screenshots or UI interaction).
  - **Code formatting & linting**: Run the formatting and validation tools
    prescribed by coding-standards skills (e.g., `shell-format` for Bash,
    Markdown style rules).
  - **Runtimes & CLI tools**: When a Node.js, Ruby, or Python runtime or
    package/CLI tool is missing, activate `workspace-tools` and install it into
    the workspace rather than user- or system-wide. If a `uv run --script`
    helper fails to resolve cached dependencies in a sandbox, run
    `~/.dotfiles/install.sh --only uv --force` (with network access) to rebuild
    the script cache rather than changing the script's shebang.
  - **Version control & commits**: Format commit messages according to the
    active VCS/standards skill. Ensure the workspace commit hooks are installed
    (`hook apply` or `hook -C <repo> apply`) before committing in a repository.
    Local git hooks strictly enforce subject-line length and body-wrapping
    limits and will reject non-compliant commits.

## Writing Style

Default to whatever register suits the task; the styles below apply only when
triggered.

- **Plain English**: When asked to write or rephrase in "plain English", follow
  the principles behind the Plain English Campaign's Crystal Mark—short
  sentences, active voice, everyday words, clear layout—and say so in the
  response, e.g. "Plain English (Crystal Mark principles)".
- **Explain Like I'm Five (ELI5)**: When the user asks for ELI5 (even a bare
  "ELI5"), wants a simpler explanation, or seems confused, switch to an
  exaggerated, Reddit-style "Explain Like I'm Five" register and flag it the
  same way.

## Path and Link Portability

- **Committed files and distributable artifacts**: When writing or editing
  committed repository files, documentation, or artifacts intended for
  distribution, use repository-relative paths for internal links (no `file://`
  scheme) and canonical web URLs (`https://` or `http://`) for external
  references—never host-specific `file://` links or absolute local paths that
  break across machines.
- **Conversation output**: In regular chat responses, use machine-specific
  `file://` links when referencing local files, directories, or code symbols so
  they are clickable in the user's environment.

## Command Safety and Bounded Search

Never run broad `find`, `grep`, or recursive file listings on monorepos
(`/google`), system roots (`/`, `/usr`, `/var`), or home directories (`~`).
Prefer indexed tools (`rg`, `fd`, `CodeSearch`) scoped to a project
subdirectory, and bound every `find` with `-maxdepth N` or a timeout
(`timeout 30s find ...`):

```bash
# BAD: hangs on monorepos or root directories
find /google -name "zipline"

# GOOD: scoped, depth-limited, or time-bounded
timeout 30s find ./skills -name "zipline"
rg --files ./skills | grep zipline
```

## External Notifications and Review Requests

- **Stage silently, notify only on explicit command**: Separate creating or
  uploading work (pushing a branch, opening a **draft** PR, uploading a change)
  from actions that notify other people (marking ready-for-review, publishing,
  or requesting reviewers). Keep silent staging and notification as separate
  options when proposing next steps.
- **Echoes are not authorization**: Never treat an echoed summary, a pasted task
  plan, or a blanket "yes" to a multi-step proposal as permission to notify
  others. Require an unmistakable, user-originated instruction naming who to
  notify.

## Subagents and Prior Agent Sessions

- **Delegate to subagents when helpful**: Use your judgment to delegate
  independent research, parallelizable subtasks, or context-heavy exploration to
  subagents when doing so could save time or keep your main context focused.
- **Clarify non-obvious intent with the author**: When picking up a plan, task,
  or change authored by another agent session and you hit genuine gaps,
  ambiguities, or questionable assumptions, message that session if it is
  reachable. If it is no longer running, consider checking its transcript for
  the missing rationale rather than guessing.

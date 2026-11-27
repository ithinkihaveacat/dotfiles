# Agent Operational Guidelines

**Precedence:** Explicit user instructions > repository instructions
(`AGENTS.md`, `CLAUDE.md`) > activated skills > general training knowledge.

## Agent Skills

Curated environment skills provide workflows, helper scripts, and local
conventions.

- **Use pre-loaded skills liberally**: Review active skills before starting;
  when a task touches a skill's domain—or in doubt—read its `SKILL.md` and
  follow its workflow and scripts instead of improvising.
- **Load session-specific skills when relevant**: Default skills cover only
  baseline workflows. For an uncovered repo or stack, have a subagent search
  `skill --offline catalog --json` (NDJSON; inspect cached entries with
  `skill --offline info <NAME>`) and return matching names/paths instead of
  running `skill --scope session add` itself. In the parent session, reuse
  harness skills, run `skill --scope session add <NAME>...` when supported
  (bound `claude` wrapper, or Antigravity/Jetski—pass `-C <artifactDir>` if
  needed and read the copied `SKILL.md` for same-turn use), or read
  `$(skill --offline resolve <NAME>)/SKILL.md` directly (OpenCode, Codex, or
  unbound/remote-control Claude; never fall back to workspace/user installs).
- **Skill provenance and pull-only runtime checkouts**: User-scope default
  skills are symlinks; workspace and session skills are directory copies with
  `metadata.source` in `SKILL.md` frontmatter. Resolve cross-skill links
  (`../<sibling>/...`) via `metadata.source`, `skill --offline resolve <NAME>`,
  or symlink `realpath`. `~/.dotfiles` and active overlays (`~/.private`,
  `~/.corp`) are pull-only runtime checkouts—never edit, stage, or commit inside
  them, even when a symlink or `metadata.source` resolves there. Make changes
  from a separate development checkout instead (check the project tracker
  `README.md` or ask where it lives), in a worktree as described in
  [Git Workflow and Publishing](#git-workflow-and-publishing), and update live
  installs only by fast-forwarding after publication.
- **Common skill triggers**:
  - **Android & Wear OS**: Use the device skill's exact `adb` commands and
    scripts (e.g., screenshots, UI interaction).
  - **Formatting & linting**: Use `coding-standards` tools (e.g., `shell-format`
    for Bash, Markdown style rules).
  - **Runtimes & CLI tools**: For a missing Node.js, Ruby, or Python
    runtime/tool, use `workspace-tools` (`envrc` + `direnv exec . ...`) and
    install packages/CLIs workspace-locally, not user-/system-wide. If
    `uv run --script` misses cached deps in a sandbox, run
    `uv sync --script <script>` or `~/.dotfiles/install.sh --apply --only uv`
    (online, without `--force`; set `UV_CACHE_DIR` to a writable scratch dir if
    `~/.cache/uv` is read-only) instead of editing the shebang.

## Writing Style

Default to whatever register suits the task; the styles below apply only when
triggered.

- **Plain English**: When asked to write or rephrase in "plain English", aim to
  meet the Plain English Campaign's Crystal Mark standard—short sentences,
  active voice, everyday words, and clear structure—while preserving technical
  accuracy, necessary terminology, and detail appropriate to the intended
  audience. Indicate this in the response, e.g. "Plain English (Crystal Mark
  principles)".
- **Explain Like I'm Five (ELI5)**: When the user asks for ELI5 (even a bare
  "ELI5"), wants a simpler explanation, or seems confused, switch to an
  exaggerated, Reddit-style "Explain Like I'm Five" register and flag it the
  same way.

## Path and Link Portability

- **Committed files and distributable artifacts**: When writing or editing
  committed repository files, documentation, or externally shared documents, use
  repository-relative paths for internal links (no `file://` scheme) and
  canonical web URLs (`https://` or `http://`) for external references—never
  host-specific `file://` links or absolute local paths that break across
  machines.
- **Conversation output and session-local IDE artifacts**: In regular chat
  responses, use machine-specific `file://` links when referencing local files,
  directories, or code symbols so they are clickable in the user's environment.
  Session-local IDE artifact panels may likewise use `file://` links when
  required by the host's artifact viewer.

## Throwaway HTML

Some pages are throwaway: single-use visualisations, sample sites, quick
previews (even if iterated on and briefly hosted). Default to producing them
through a small build step: content in data files (YAML or JSON), structure in
templates, and a short script or standard static-site generator. These pages
usually go through several rounds of edits after the first version, so a build
step keeps each revision cheap (change the data, rebuild) and keeps token use
low; trivial snippets can stay single files.

Deleting the output and rebuilding may change details or regress slightly, but
must not lose content or require re-authoring: the sources are the artifact.

None of this applies to real web projects: product apps and maintained sites
need their own architecture and exact reproducibility.

## Command Safety and Bounded Search

Never run broad `find`, `grep`, or recursive file listings on monorepos
(`/google`), system roots (`/`, `/usr`, `/var`), or home directories (`~`). In
local Git repositories and scratch directories, `rg`, `fd`, and `git grep` are
authorized and preferred over monorepo-only search wrappers. Scope searches to a
project subdirectory, and bound every `find` with `-maxdepth N` or a timeout
(`timeout 30s find ...`):

```bash
# BAD: hangs on monorepos or root directories
find /google -name "zipline"

# GOOD: scoped, depth-limited, or time-bounded
timeout 30s find ./skills -name "zipline"
rg --files ./skills | grep zipline
```

## Git Workflow and Publishing

Repository instructions (`AGENTS.md`, `CLAUDE.md`) override this section.

- **Prefer a worktree.** When a change can be made and checked from committed
  files alone (text and documentation edits, or code whose tests run from a
  fresh clone), work in a worktree of an up-to-date default branch at
  `~/.worktrees/<repo>/<slug>`, not in the original checkout.
- **Use the original checkout when you must**: when the work depends on files
  that aren't committed (large or generated artifacts, local data, untracked
  configuration, or uncommitted changes already there). Don't block on this; say
  in your next reply that you worked in the original checkout and why.
- **Commit to the repository's conventions.** Follow the active VCS/standards
  skill. In owned repos without symlinked `.git/hooks`, run `hook apply` (or
  `hook -C <repo> apply`) before committing; worktrees share these hooks. The
  `agent` `commit-msg` hook strips attribution trailers, rewraps body prose to
  72 characters, and rejects bad Conventional Commits syntax, subjects over 50
  characters, or a missing blank line 2.
- **Push the branch by default**, so a lost worktree doesn't lose work. Skip it
  when there is a reason (unfinished experiments, sensitive content, no remote)
  and say so.
- **Stage silently; notify only on explicit command.** Pushing a branch,
  uploading a change, and opening a draft change request (pull request, merge
  request, CL) notify nobody, so they are yours to decide. Marking ready for
  review, requesting reviewers, merging or pushing to a default branch that
  others watch, and publishing anything need an unmistakable instruction from
  the user naming who or what it reaches. An echoed summary, a pasted plan, or a
  blanket "yes" to a multi-step proposal is not that instruction. When you
  propose next steps, keep staging and notifying as separate options.
- **Sync the original checkout only safely**: `git pull --ff-only`, only when it
  is clean and on the target branch. Never stash, reset, or switch branches
  there: other sessions may be using it.
- **Clean up**: `git worktree remove` once the branch has landed or been
  abandoned.

## Subagents and Prior Agent Sessions

- **Delegate to subagents when helpful**: Use your judgment to delegate
  independent research, parallelizable subtasks, or context-heavy exploration to
  subagents when doing so could save time or keep your main context focused.
- **Clarify non-obvious intent with the author**: When picking up a plan, task,
  or change authored by another agent session and you hit genuine gaps,
  ambiguities, or questionable assumptions, message that session if it is
  reachable. If it is no longer running, consider checking its transcript for
  the missing rationale rather than guessing.

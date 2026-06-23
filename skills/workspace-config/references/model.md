# The workspace-config model

<!-- markdownlint-disable MD013 -->

Maintainer reference for the `skill` tool: what it touches, the invariants it
maintains, and the one deliberate exception. User-facing usage lives in
`../SKILL.md`; this document explains *why the pieces fit together*.

## The picture

```text
        AGENT_REQUIRED_SKILLS (env)              SKILL_SOURCE_DIRS (env)
                  │                                       │
                  │ "expected" skill names                │ search path
                  ▼                                       ▼
           ┌────────────┐    resolve_skill_spec    ┌──────────────┐
           │  expected  │ ───────────────────────▶ │ source skill │
           │   skills   │                          │ directories  │
           └────────────┘                          └──────────────┘
                  │                                       │
                  │              skill apply              │ symlink target
                  ▼                                       ▼
   dest dirs ─▶ .claude/skills/<name> ─┐
  (per agent)   .agents/skills/<name> ─┴──▶ untracked symlinks on disk
                  │                                       │
                  │ GitWorkspace only                     │
                  ▼                                       │
       .git/info/exclude  ◀──── marker block keeps ───────┘
       (# >>> skills >>>)        git status clean
```

## The four flows ("what touches what")

1. **Desired state** comes from `AGENT_REQUIRED_SKILLS` (or, for stateful plugin
   workspaces, a saved state file via `FileStateMixin`). This is the set of
   skill *names* the workspace wants — `Workspace.get_expected_skills()`.
1. **Sources** are resolved by name against `SKILL_SOURCE_DIRS`
   (`resolve_skill_spec`): the on-disk skill directory a name points to.
1. **Destinations** are the per-agent link directories
   (`Workspace.get_dest_dirs()`): `.claude/skills` and/or `.agents/skills`,
   overridable with `SKILL_DEST_DIRS`. `skill apply` makes each expected skill a
   symlink `dest/<name> -> source` and prunes symlinks that are no longer
   expected.
1. **VCS invisibility** (git only): `GitWorkspace` maintains a marker block
   (`# >>> skills >>>` … `# <<< skills <<<`) in `.git/info/exclude` listing the
   symlink paths, so `git status` stays clean without touching the tracked
   `.gitignore`.

## Invariants

These are what `skill doctor` audits (read-only) and `skill apply` repairs:

- **I1 — Alignment.** For every expected skill there is exactly one symlink in
  each destination, resolving to the expected source. No missing links, no extra
  or stale links, no links that resolve elsewhere. (doctor: *Required Skills*;
  severity ERROR.)
- **I2 — Live links.** Every managed symlink resolves to an existing target;
  none dangle. (doctor: *Symlink Health*; ERROR.)
- **I3 — Clean folders.** Destination folders contain only managed symlinks — no
  real files or stray directories. (doctor: *Directory Cleanliness*; ERROR.)
- **I4 — Quiet VCS.** The exclude marker block exactly matches the managed
  symlinks; no drift. (doctor: *Workspace Exclusions*; ERROR — git only.)

Health is the conjunction of these (plus the agent, plugin-path, and catalog
checks). `apply` is the idempotent fixpoint: running it makes a workspace
healthy, and running it again changes nothing.

## The one exception: doctor vs. preflight severity

`doctor` and `preflight` run the *same* checks but answer different questions,
so they weigh findings differently:

- **`skill doctor`** is a full audit. *Any* non-OK finding — ERROR or WARNING —
  makes it exit non-zero. It is the place warnings surface.
- **`skill preflight LABEL`** is the gate run just before an agent launches (it
  calls `cmd_doctor(errors_only=True)`). Only **ERROR**-severity findings block
  launch; WARNING findings are suppressed from its output and do not stop the
  agent.

This is the single, deliberate asymmetry in the model. It exists because two
checks are advisory rather than blocking:

- **Orphaned Directories** (WARNING): a `.claude/skills` or `.agents/skills`
  folder exists locally, but the matching agent's global config (`~/.claude`,
  `~/.codex`, or `~/.gemini/antigravity-cli`) does not. This state is reachable
  legitimately: `get_dest_dirs()` treats an existing local skills directory as a
  managed destination even when no global agent is detected (the "local-dir
  fallback"). So a workspace can be fully synchronized *and* carry an orphaned
  folder at once. Blocking launch on it would let `skill apply` configure a
  workspace that `skill preflight` then refuses — so preflight only warns, via
  `doctor`.
- **Catalog Cache** staleness (WARNING): a cached remote catalog stub is older
  than its source. Advisory only, and never consulted at launch — `preflight`
  runs with `check_catalog=False`.

Everything else a `doctor` reports is an ERROR and blocks launch: a missing
skill, a dangling symlink, unmanaged junk, exclude drift, a missing plugin local
path, no detected agent (with no local skill dirs to fall back on), or a catalog
stub missing from the index.

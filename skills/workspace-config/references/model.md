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
- **I3 — Clean folders.** Destination folders contain only managed symlinks or
  VCS-managed (tracked) files/directories — no untracked real files or stray
  directories. (doctor: *Directory Cleanliness*; ERROR.)
- **I4 — Quiet VCS.** The exclude marker block exactly matches the managed
  symlinks; no drift. (doctor: *Workspace Exclusions*; ERROR — git only.)

Health is the conjunction of these (plus the agent, plugin-path, and catalog
checks). `apply` is the idempotent fixpoint: running it makes a workspace
healthy, and running it again changes nothing.

## The shared reconciliation planner (`build_reconcile_plan`)

To guarantee that `skill doctor` and `skill apply` never drift in their
definition of convergence, both commands derive desired-vs-actual state from a
single shared planner function, `build_reconcile_plan(ws) -> ReconcilePlan`:

- **`skill doctor`** renders the `ReconcilePlan` read-only to report workspace
  health.
- **`skill apply`** executes permitted actions derived from the exact same plan
  (creating missing links, re-linking target mismatches, pruning stray dangling
  or extra symlinks), then recomputes the plan to verify convergence
  (`has_fixable_findings()`).

Because both commands consume a unified `ReconcilePlan`:

- **Unresolvable declared specs** (`ResolvedSkill.error`) are kept distinct from
  missing skills (reported under *Unresolvable skills*) and set
  `destructive_blocked = True`, preventing `apply` from misclassifying and
  deleting live symlinks for unresolvable specs.
- **Tracked dangling links** (`DiskEntry.tracked`) are separated from stray
  dangling links so `apply` prunes only untracked broken links, avoiding loops
  where `doctor` recommends `skill apply` for checked-in symlinks it cannot
  remove.
- **Target mismatches** (`overwritten_by_add`) are recognized as re-link targets
  rather than extra links to delete.

## The freshness check (advisory)

`AGENT_REQUIRED_SKILLS` is the source of truth `skill` acts on — but in a direnv
workspace it is a *cache*: the `.envrc` managed skills block (written by
`envrc`, evaluated via the `skills` function in `~/.direnvrc`) records changes
that only reach the environment at the next prompt. Between an `.envrc` edit and
the next direnv reload, the cache is stale.

`check_env_freshness()` detects this by statically parsing the managed block
(never executing shell) and asserting that every name the block adds appears in
the parsed environment, and every name it negates does not. Detection is
deliberately **one-directional**: a name present in the environment but absent
from the block is unjudgeable, because the base layer (global defaults from the
shell config) cannot be observed separately. That asymmetry is safe — the
detectable direction (block declares, env lacks) is the one where acting on the
stale cache would *destroy* state, while the undetectable direction merely
delays convergence by one reload.

The result is strictly advisory: it may cause `skill` to **say more or do less,
never to do something different**:

- **`doctor`** renders it as the *Environment Freshness* check (WARNING) with a
  `direnv reload` resolution step.
- **`apply`** declines to run its pruning phase while stale (additions still
  proceed; they are harmless), telling the user to reload and re-run.
- Nothing ever merges block contents into the expected-skills set. If that ever
  seems desirable, the correct design is to recompute the environment via
  `direnv export` — not a partial merge here.

A block whose content the parser does not recognize yields *no* freshness data
(the check disappears entirely): an advisory signal must not guess.

## The one exception: doctor vs. preflight severity

`doctor` and `preflight` run the *same* checks but answer different questions,
so they weigh findings differently:

- **`skill doctor`** is a full audit. *Any* non-OK finding — ERROR or WARNING —
  makes it exit non-zero. It is the place warnings surface.
- **`skill preflight LABEL`** is the gate run just before an agent launches (it
  calls `cmd_doctor(errors_only=True)`). Only **ERROR**-severity findings block
  launch; WARNING findings are suppressed from its output and do not stop the
  agent. Setting `AGENT_PREFLIGHT_SKIP` (legacy spelling:
  `_agent_preflight_skip`) bypasses the gate entirely; the failure message
  advertises this escape hatch so it never has to be remembered.

This is the single, deliberate asymmetry in the model. It exists because three
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
- **Environment Freshness** (WARNING): the `.envrc` managed skills block
  declares changes that `AGENT_REQUIRED_SKILLS` does not reflect yet (see "The
  freshness check" above). The skills an agent actually loads come from the
  on-disk symlinks, which may well match the declared intent — only the
  environment copy is behind — so blocking launch on it would be wrong.

Everything else a `doctor` reports is an ERROR and blocks launch: a missing
skill, a dangling symlink, unmanaged junk, exclude drift, a missing plugin local
path, no detected agent (with no local skill dirs to fall back on), or a catalog
stub missing from the index.

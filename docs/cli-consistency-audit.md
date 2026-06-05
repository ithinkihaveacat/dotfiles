# CLI Consistency Audit & Plan: `skills/*/scripts/` and `bin/`

Status: proposal / not yet implemented.
Scope: the multi-subcommand ("Manager"-pattern) scripts in this repo, plus the
single-action utilities and the `adb` tile workflow. `bin/` entries are symlinks
to the canonical sources under `skills/*/scripts/` (or, for `git-skill`, a
standalone file in `bin/`), so all changes target the canonical sources.

The audit measures the scripts against the project's own standard in
`skills/coding-standards/references/cli-tools.md` and `…/shell.md`.

---

## 1. Scripts in scope

Four tools use the multi-subcommand Manager pattern (`tool <verb> [instance]`),
where consistency matters most:

| Script | Location | Subcommands |
| --- | --- | --- |
| `git skill` | `bin/git-skill` | `apply` `suggest` `add` `remove`/`rm` `list` `update` `clean` `doctor` `catalog` `resolve` |
| `emumanager` | `skills/emumanager/scripts/emumanager` | `bootstrap` `doctor` `list` `info` `create` `start` `stop` `delete` `download` `images` `outdated` `update` |
| `jetpack` | `skills/jetpack/scripts/jetpack` | `version` `versions` `resolve` `search` `source` `inspect` `dependencies` `resolve-exceptions` |
| `socrates` | `skills/agent-tools/scripts/socrates` | `generate` `answer` `score` `status` `delete` `questions` `report` |

`packagename` (`skills/adb/scripts/packagename`) is also a Manager tool (~20
info/lifecycle subcommands) but does not exercise the local-vs-available or
doctor patterns, so it is out of scope for the changes below.

Single-action utilities (no subcommands): `context`, `oracle`, `popper`,
`gh-markdown`, `gemini-api-status`, and most `adb-*` scripts.

The **`adb` tile workflow** is a set of separate utilities that together form
one add/remove/list flow and is directly relevant:
`adb-tiles`, `adb-tile-add`, `adb-tile-remove`, `adb-tile-show`.

---

## 2. Finding A — "list local state" vs. "list everything available"

A recurring shape across these tools: there is a set of *available* things, an
`add`/`rm` pair that installs them locally, and a `list` that shows what is
installed. The repo currently expresses the two kinds of listing three
different ways, and overloads the word "available."

### 2.1 Reference implementation: `git skill`

`git skill` is the most mature example and gets this right:

| Command | Help text | Meaning |
| --- | --- | --- |
| `list` | "List skills this tool is managing in the current repo" | **local / on-disk state** |
| `catalog` | "List registered skills and their sources" | **everything available (obtainable)** |
| `add SPEC…` | Add a skill (local path or catalog entry) | add local |
| `remove NAME…` (alias `rm`) | Remove a skill this tool added | remove local |

`list` is unambiguous: it describes *managed* (local) skills and never says
"available." The obtainable set is a separate command named `catalog`.

### 2.2 The inconsistency across tools

| Script | list LOCAL | list AVAILABLE |
| --- | --- | --- |
| `git skill` | `list` | `catalog` |
| `emumanager` | `list` *(help wrongly says "available")* | `images`, `outdated` |
| `jetpack` | — | `versions`, `search` |
| `adb-tiles` | (single list, `C` column marks added) | (same single list) |

Two distinct problems:

1. **Three vocabularies for "available":** `catalog`, `images`, `versions`.
2. **"available" is overloaded.** `emumanager list` is documented as
   *"List all available AVDs"* (`emumanager:256`) but actually lists locally
   created AVDs, while `emumanager images` is *"List all available system
   images"* (`emumanager:274`) and genuinely means remote/obtainable. The same
   word means "locally present" in one place and "obtainable" in another.

### 2.3 A second valid model: one list + a state column (`adb-tiles`)

`adb-tiles` folds both concepts into a single command: it lists **all available**
tile/widget services and marks the ones currently **added to the carousel** with
a `C` flag (`S`/`T`/`W`/`C` columns); `--carousel-only` filters to just the added
set. This is a legitimate alternative to having two separate commands and is the
right call when "available" and "added" are views of one underlying list.

### 2.4 Recommendation A

Adopt **`git skill`'s vocabulary as the standard**:

- **`list`** = current local / on-disk / added state. Verb-led; works under the
  Manager pattern.
- **`catalog`** = everything obtainable. (`catalog` is preferred over
  "available" because it is also a valid transitive verb — see §4 — and does not
  collide with the local meaning.) Where `catalog` doesn't fit a domain, use
  `list <noun> --available`.
- **Forbid using the word "available" to describe locally-present items.**
- When "available" and "added" are views of one list, the **single-list +
  state-column** pattern (`adb-tiles`) is acceptable and encouraged.

---

## 3. Finding B — health-check / status / doctor naming

Two genuinely different operations are in play and must not be merged:

- **(a) Diagnostics / health / drift** — "is my environment set up, can I reach
  the service, does on-disk match desired."
- **(b) Resource state / progress** — "what is the current state of this one
  named resource" (like `git status`).

### 3.1 What exists today

| Script | Command / name | Kind |
| --- | --- | --- |
| `git skill` | `doctor` (dispatch also accepts `status` as a hidden alias) | (a) diagnostics — "Diagnose drift between desired and on-disk skills (read-only)" |
| `emumanager` | `doctor` | (a) diagnostics — "Run diagnostics to check for common issues" |
| `gemini-api-status` | whole script, named `…-status` | (a) diagnostics — pings models to validate API key / reachability |
| `socrates` | `status <db>` | (b) resource progress — "Show progress status" |

`git skill` is again the reference: it uses **`doctor`** as the canonical name
and wires `status` as a silent alias in dispatch
(`elif cmd in ("doctor", "status")`), while only advertising `doctor`.

The only true inconsistency is that `gemini-api-status` performs an operation of
kind (a) — exactly what the others call `doctor` — but is named `…-status`.

### 3.2 Recommendation B

- **Standardize on `doctor`** for kind-(a) diagnostics across the repo.
- Where a `status` name already exists for a kind-(a) operation, **keep `status`
  as a hidden alias** rather than breaking callers, using `git skill`'s
  `cmd in ("doctor", "status")` technique.
- **Reserve `status <resource>` for kind-(b)** read-only resource state/progress.
- Avoid `check` / `verify` / `validate` as command names for either — ambiguous.
- `doctor` should exit non-zero when it finds problems.
- **Decide on `socrates status`:** if it reports DB *health/completeness* it
  should become `doctor`; if it reports *progress of a run* it stays `status`.
  (Lean: it is progress → keep `status`, but make the call deliberately.)

---

## 4. Finding C — verb-noun structure (mostly a non-issue)

Under the Manager pattern (Type 1 in `cli-tools.md`), the **tool name is the
noun** and the **first argument is the verb**, with `[Instance]` optional. So
`git skill doctor` parses correctly as *"(on the domain of) skill(s), doctor
[them]"* — verb `doctor`, instance elided. By this reading, essentially all the
bare commands (`list`, `doctor`, `apply`, `create`, `start`, `delete`, …) are
**already compliant**. No standard change is needed to bless them.

The only genuine deviation is the handful of commands whose first token is a
**noun or adjective**, leaving no verb for the pattern to bind to:

| Command | First token | Part of speech | Verb-first fix |
| --- | --- | --- | --- |
| `emumanager images` | `images` | noun | `list images` / `catalog` |
| `emumanager outdated` | `outdated` | adjective | `list outdated` |
| `jetpack versions` | `versions` | noun | `list versions` |
| `jetpack dependencies` | `dependencies` | noun | `list dependencies` |

`git skill catalog` is a deliberate borderline case that *passes*: `catalog` is
a noun **and** a valid transitive verb, so it reads as *"skill(s), catalog
[them]"*. This is the reason to prefer `catalog` as the canonical "available"
command (§2.4) — it is the one available-list name that also satisfies the verb
slot.

### 4.1 Recommendation C

- Treat the four noun/adjective-first commands above as **optional polish**, not
  violations: rename to verb-first (`list <noun>`) for consistency with the
  `list` verb those same tools already have.
- Add one clarifying sentence to `cli-tools.md` Type 1 so future authors don't
  reach for noun-first commands: *"The first argument must be a verb; the
  `[Instance]` may be omitted, as in `git skill doctor`."*

---

## 5. Finding D — add / remove verb pairs (ungoverned)

The "install locally / uninstall locally" verbs diverge with no standard:

| Script | add | remove | bulk / other |
| --- | --- | --- | --- |
| `git skill` | `add` | `remove` (alias `rm`) | `clean` (all), `update` (refresh) |
| `emumanager` | `create` | `delete` | `download` (fetch only) |
| `adb` tiles | `adb-tile-add` | `adb-tile-remove` | — |
| `packagename` | (install via adb) | `uninstall` | — |

### 5.1 Recommendation D

Document canonical pairs by domain in `cli-tools.md`, and pick by what the verb
acts on:

- `create` / `delete` — for resources the tool **authors** (e.g. AVDs).
- `add` / `remove` — for **membership in a set** (e.g. tiles in a carousel,
  skills in a repo). Bless **`rm` as the accepted alias** for `remove`.
- `install` / `uninstall` — for **packages**.
- `set` — for **single-value replacement** of an active/current selection (e.g.
  the active watch face, the current theme). `set` replaces; it is not a
  set-membership add. Use this instead of `add` when there is exactly one slot.

Apply consistently within each tool; do not mix (e.g. don't pair `add` with
`delete`, and don't name a single-slot replacement `add`).

---

## 6. Finding E — the `adb-tile-*` / `adb-watchface-*` series

These are flat `adb-*` utilities (one executable per action), not a Manager
tool. They form the canonical "available set + add/remove + list" workflow:

| Script | Action | Notes |
| --- | --- | --- |
| `adb-tiles` | "Lists all available tile and widget services" with `S`/`T`/`W`/`C` columns; `C` marks carousel members; `--carousel-only` filters to those | list |
| `adb-tile-add COMPONENT` | "Adds a tile … to the carousel" | add (membership) |
| `adb-tile-remove COMPONENT` | "Removes all tile instances on the carousel associated with COMPONENT" | remove (membership) |
| `adb-tile-show TILE_INDEX` | "Activates a tile at the specified index … useful for switching between already added tiles" | switch active slot |
| `adb-watchface-add COMPONENT` | "Sets the current watch face" | single-slot replacement |

### 6.1 Should these be consolidated into a Manager tool?

A `adb-tile <verb>` Manager tool (`adb-tile list`/`add`/`remove`/`switch`) would
match `git skill` / `emumanager`. **Recommendation: do not consolidate.** The
repo's house style for this domain is flat `adb-*` utilities (30+ scripts:
`adb-activities`, `adb-packages`, `adb-screenshot`, …); a lone `adb-tile`
Manager would be the odd one out, would fragment the `adb-*` namespace, and would
break existing agent invocations and completions for marginal benefit. Keep the
flat utilities and fix vocabulary instead.

### 6.2 What is already correct

- **`adb-tiles`** is the reference implementation of the **single-list +
  state-column** model blessed in §2.3: it lists the available set and marks the
  added (carousel) members with `C`, with `--carousel-only` as the
  "list-added-only" view. No list/catalog rename is needed — it merges both
  views cleanly. (Its one help-text quirk: it says "available," which is correct
  here because it genuinely lists the obtainable set, not local-only items —
  consistent with §2.4.)
- **`adb-tile-add` / `adb-tile-remove`** are a correct `add`/`remove`
  set-membership pair (§5.1). Keep as-is.
- **Singular vs. plural** (`adb-tiles` to list many, `adb-tile-*` to act on one)
  is intentional and acceptable — it mirrors `adb-packages` (list) vs.
  `packagename` (act). No change.

### 6.3 What should change

1. **`adb-tile-show` → `adb-tile-switch`** (keep `adb-tile-show` as a symlink
   alias). The verb "show" misleads: it does not display or list anything — it
   *switches* the active carousel slot to a given index. "show" also collides
   conceptually with the listing verb (`adb-tiles`). `switch` (or `activate`)
   states the intent. Update the cross-reference in `adb-tile-add`'s help ("no
   separate call to adb-tile-show is needed") and the companion-script example
   in `skills/coding-standards/references/shell.md`, which currently cites
   `adb-tile-add`/`adb-tile-show` as a paired workflow.

2. **`adb-watchface-add` → `adb-watchface-set`** (keep `adb-watchface-add` as a
   symlink alias). Its help already says *"Sets the current watch face"* — there
   is exactly one active watch face, so this is single-slot replacement, not
   set-membership. Per the new `set` verb in §5.1, `add` is the wrong verb;
   `set` matches the behavior and avoids implying a carousel-like collection.

### 6.4 Recommendation E (summary)

Keep the flat utilities and the `adb-tiles` single-list model; keep
`add`/`remove`; rename `adb-tile-show` → `adb-tile-switch` and
`adb-watchface-add` → `adb-watchface-set`, preserving the old names as aliases.

---

## 7. Standard vs. practice — contradictions and gaps

Measured against `cli-tools.md` / `shell.md`:

**Already consistent (no change):** `--help`/`help`/bare-command behavior, the
`-h` prohibition, stdout-vs-stderr split, exit codes, `require()` dependency
checks, and the `jq`/`ARG_MAX` guidance all match what the scripts do.

**Contradiction (practice vs. doc):** `emumanager list`'s help text uses
"available" to describe local AVDs, contradicting the clarity the standard
intends (and conflicting with its own `images` command). Fix the help text.

**Gaps the standard does not yet cover (and should):**

1. **Local vs. available listing** (§2) — no guidance exists. Add a section
   codifying `list` (local) + `catalog`/`--available` (obtainable), and forbid
   "available" for local items. Cite `git skill` as the reference.
2. **Diagnostics vs. status** (§3) — no guidance exists. Add a section:
   `doctor` for diagnostics (canonical), `status <resource>` for resource state,
   `status`→`doctor` aliasing technique, non-zero exit on problems. Cite
   `git skill`.
3. **add/remove verb pairs** (§5) — no guidance exists. Add the by-domain table,
   the `rm` alias rule, and the `set` verb for single-slot replacement.
4. **Type 1 verb-slot clarification** (§4.1) — one sentence so noun-first
   commands aren't seen as acceptable.

No contradictions were found that require changing the *rules* already in the
standard — the gaps are additions, and the one practice-level contradiction is a
help-text fix.

---

## 8. Plan of action

Ordered by risk; doc additions first because they anchor every code change.

### Phase 1 — Standard (doc-only, low risk)

1. `cli-tools.md`: add **§ Listing: local vs. available** (Rec A), citing
   `git skill list` / `catalog`.
2. `cli-tools.md`: add **§ Diagnostics: `doctor` vs. `status`** (Rec B), citing
   `git skill`.
3. `cli-tools.md`: add **§ add/remove verb pairs** (Rec D).
4. `cli-tools.md`: add the one-sentence Type 1 verb-slot clarification (Rec C).

### Phase 2 — Low-risk code fixes

5. `emumanager`: fix `list` help text to say "locally created AVDs" (drop
   "available").
6. `gemini-api-status` → rename canonical to `gemini-api-doctor`; keep
   `gemini-api-status` as a symlink/alias. Update `bin/`, completions, tests,
   SKILL.md, command-index.
7. Where a `status` subcommand means diagnostics, add `doctor` as the canonical
   name with `status` aliased (none required today beyond the rename above;
   `git skill` already does this).

### Phase 3 — Renames with back-compat aliases (medium risk, agent-facing)

8. `emumanager images` → `catalog` (or `list images`); keep `images` as an
   alias. Update completions, SKILL.md, command-index, tests.
9. `emumanager outdated` → `list outdated` (keep `outdated` alias), optional.
10. `jetpack versions` → `list versions`; `jetpack dependencies` →
    `list dependencies`; keep old names as aliases. Optional polish.
11. `adb-tile-show` → `adb-tile-switch`; `adb-watchface-add` →
    `adb-watchface-set` (Rec E). Keep old names as symlink aliases. Add new
    `bin/` symlinks; rename/duplicate `fish/completions/*.fish`; update the
    cross-references in `adb-tile-add` help, `skills/adb/SKILL.md`,
    `skills/adb/references/command-index.md`,
    `skills/adb/references/troubleshooting.md`, and the companion-script example
    in `skills/coding-standards/references/shell.md`.

### Phase 4 — Deliberate decision

12. Decide `socrates status` → `doctor` (if health) or keep (if progress), per
    §3.2.

### Cross-cutting requirements (from `CLAUDE.md`)

For every code change: run `shellcheck` + `shfmt -w -i 2 -ci` on bash scripts;
`fish_indent -w` on any edited completion; update the matching
`fish/completions/<script>.fish`; update `skills/*/references/command-index.md`
and `SKILL.md`; review/adjust any `tests/<script>/` TAP tests; preserve all old
command names as aliases so existing agent invocations keep working.

---

## 9. Summary table

| # | Recommendation | Reference | Risk |
| --- | --- | --- | --- |
| A | `list` = local, `catalog`/`--available` = obtainable; ban "available" for local | `git skill` | low (doc) / med (renames) |
| B | `doctor` canonical for diagnostics; `status` = resource state; alias `status`→`doctor` | `git skill` | low |
| C | Noun-first commands → verb-first `list <noun>`; clarify Type 1 verb slot | — | low, optional |
| D | Canonical add/remove/`set` pairs by domain; bless `rm` alias | `git skill` | low (doc) |
| E | Keep flat `adb-*` utilities + `adb-tiles` single-list model; rename `adb-tile-show`→`adb-tile-switch`, `adb-watchface-add`→`adb-watchface-set` (aliases kept) | `adb-tiles` | low |
| — | Fix `emumanager list` help text | — | trivial |
| — | `gemini-api-status` → `gemini-api-doctor` (alias kept) | `git skill` | low |
| — | Decide `socrates status` vs `doctor` | — | decision |

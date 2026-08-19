# Proposal: Path-Scoped Access for Caxton

## Status

Proposed, revised. This document supersedes an earlier draft that kept
`--output`, an inferred workspace root, and a `target`/`reference` vocabulary.

## Summary

Caxton currently accepts one source directory. It discovers the eligible files
under that directory, optionally inlines all of their text into the initial
model context, and grants tools access to the same directory. Read-only mode
withholds mutation tools; `-i`/`--in-place` and `-o`/`--output` make the whole
eligible tree writable.

This proposal replaces the single directory with three independent per-path
properties, and removes everything that made those properties hard to reason
about:

- **Visible** — the model may discover the path and read its contents.
- **Writable** — the model may modify, delete, or create at the path.
- **Inlined** — the path's contents appear in the initial prompt.

Two flags set the first two, one flag narrows the third:

```console
$ caxton "Update the parser but keep the documented behavior" \
    --edit src/parser.py tests/test_parser.py \
    --read docs/architecture.md
```

Three constraints make the rest fall out:

1. **Caxton runs only inside a git worktree.** The repository top level is the
   path namespace; git alone decides what is ignored; git alone provides undo.
1. **Caxton never copies anything.** `--output` is removed. Every run reads and
   writes the worktree in place.
1. **The root bounds; it never grants.** All authority comes from `--read` and
   `--edit`. The repository root is a namespace and a containment backstop, not
   a source of access.

## Motivation

### Selection must be an enforceable boundary, not a description

Today `read_file` and `list_files` enforce only that a path resolves inside the
sandbox root (`resolve_sandboxed_path`). They do not consult the credential
filter, and `list_files` receives an empty pattern list whenever the git listing
succeeded — which is the normal case inside a repository. So in read-only and
in-place modes the model can enumerate and read `.env`, `id_rsa`, `.npmrc`, and
every gitignored build artifact under the root: exactly the paths the initial
context withholds, the `-o` copy omits, and `--dry-run` prints under "Excluded
(credential patterns, never sent)".

That banner is true of the initial prompt only. The `-o` copy is the sole mode
where exclusion is real, and only because the excluded files are physically
absent from the copy.

One capability policy consulted by prompt construction and by every tool closes
this. It is a bug fix before it is a feature.

### Accept files and directories, not just a directory

Many useful tasks concern a handful of files:

```console
$ caxton "Update these guides to use the new command name" \
    --edit docs/install.md docs/configuration.md
```

Requiring a directory grants the model access to unrelated files and makes the
initial context larger than the task needs.

### Initial context and ongoing access are different questions

"May the model read this file?" and "should its contents be in the initial
prompt?" are conflated by today's global `--inline`/`--no-inline`. Inlining is a
loading strategy, not an access level: a lazily loaded file is still readable,
and an inlined file must stay readable so the model can observe its state after
an edit.

### One directory was doing four jobs

The earlier draft kept a workspace root that was simultaneously the sandbox
boundary, the path namespace, the ignore base, and the tree copied by
`--output`. The first three all describe the model's world and want to be one
object. The fourth is an artifact-composition decision, and letting it set the
boundary for the other three is what made root inference safety-critical — which
in turn required a `--root` flag, a containment rule for supporting paths, and a
compatibility rule that silently changed the root when a flag was added.

Removing `--output` removes the fourth job, and with it every one of those
rules.

### Git already solves the hard parts

Caxton carries a hand-rolled `.gitignore` matcher used only outside a
repository, plus an `IGNORED_DIRS`/`IGNORED_FILES` list applied on top of git's
answer. The latter means a repository that deliberately tracks `dist/` or
`build/` has those files hidden from the model even though git tracks them:
caxton disagreeing with git is a defect, and the only reason the list exists is
to cope with directories git does not manage.

Requiring a repository lets both go, and makes undo a property of the design
rather than a caveat.

## Goals

- Accept any mixture of regular files and directories as selections.
- Give a path's access one meaning, enforced by initial context, file listing,
  reads, writes, deletion, and creation alike.
- Allow supporting material to be readable without being writable.
- Allow readable material to be inlined or loaded on demand.
- Support both small argument lists and unbounded input from tools such as
  `find` and `git ls-files`.
- Treat explicitly named paths as intentional overrides of ordinary ignore
  rules, while retaining hard safety exclusions.
- Guarantee that anything the model may write, git can restore.
- Make the granted authority legible in `--dry-run` output.

## Non-goals

- Add a glob or pathspec language to caxton. Shell expansion, `find`, `fd`,
  `rg --files`, and `git ls-files` already do this, and their output can be
  piped in.
- Reproduce rsync's ordered include/exclude rules.
- Operate outside a git worktree.
- Produce a transformed copy of a tree. `git worktree add` and `git diff` do
  this better than `--output` did.
- Follow symlinks, or admit sockets, FIFOs, devices, or other non-regular
  entries.
- Backward compatibility with the current command line.

## Conceptual Model

### The repository is the world

Every run resolves the repository top level with
`git rev-parse --show-toplevel`. That path is:

- the namespace for every path shown to and accepted from the model;
- the containment backstop for tool path resolution;
- the authority for what is ignored, via
  `git ls-files --cached --others --exclude-standard`;
- the thing `git checkout -- .` and `git clean -fd` restore.

It is deliberately **not** the default selection. Running caxton from a
subdirectory of a monorepo must not inline the whole monorepo, so the default
selection is the current directory. Root and selection are separate concepts;
conflating them is what the earlier draft got wrong.

Paths shown to the model are relative to the repository top level, which means
they are the same paths that appear in `git status` and can be pasted into git
commands unchanged.

### Access levels

Two flags, each taking one or more paths:

| Flag     | Visible | Writable |
| -------- | ------- | -------- |
| `--read` | yes     | no       |
| `--edit` | yes     | yes      |

Anything not covered by either is invisible: absent from the directory tree,
absent from `list_files`, and rejected by `read_file`.

`--edit DIR` permits creating and deleting files anywhere beneath `DIR`, as well
as modifying the ones already there. `--edit FILE` permits modifying or deleting
that file only; it does not authorize creating siblings.

A run is a **mutation run** if any `--edit` is given. Mutation runs expose the
mutation tools and require a clean worktree. A run with no `--edit` is
read-only: the mutation tools are not offered at all.

### Precedence

Selections are resolved per path by **specificity**, not by flag order and not
by which flag was used:

1. The most specific selection covering a path wins, where an exactly-named path
   is more specific than a directory that contains it, and a deeper directory is
   more specific than a shallower one.
1. When two selections are equally specific, the more restrictive one wins
   (`--read` beats `--edit`).

This makes the natural spelling of a carve-out work:

```console
$ caxton "Refresh the docs" --edit docs/ --read docs/architecture.md
```

`docs/` is writable, `docs/architecture.md` is not. The earlier draft's
role-precedence rule made that file writable, defeating the intent.

### Inlining

Inlining narrows the visible set; it can never widen it.

| Invocation       | Inlined                                        |
| ---------------- | ---------------------------------------------- |
| *(default)*      | Every visible text file                        |
| `--inline PATH…` | Only the listed paths (and text files therein) |
| `--no-inline`    | Nothing                                        |

Because "everything visible" is the default, a bare `--inline` would be a no-op
and is therefore not accepted — `--inline` always takes paths. This also removes
an argument-parsing ambiguity: an optional-valued `--inline` would swallow the
prompt.

Every `--inline` path must already be visible and must be a text file; otherwise
caxton exits with an error naming the path. Inlining is not a security boundary
— a visible file can always be fetched with `read_file` — it controls initial
exposure and token use.

Paths passed to `--inline` are ordinary paths. Any pattern matching is the
shell's or `git ls-files`'s job:

```console
$ caxton "Normalize headings" --edit . --inline $(git ls-files '*.md')
```

### Writable implies restorable

Caxton's only undo is git's. The invariant that keeps that honest is:

> **A path is writable only if git can restore it.**

A mutation run requires `git status --porcelain` to be empty, so at the moment
the run starts every existing non-ignored path is tracked and unmodified.
Therefore:

- Modifying an existing tracked path is undone by `git checkout -- .`.
- Creating a non-ignored path is undone by `git clean -fd`.
- An **ignored** path is undone by neither. Caxton refuses to make ignored paths
  writable, and refuses tool calls that would create one.

`--force` waives the clean-worktree requirement and the ignored-path restriction
together, with a warning that the end-of-run change report is then the only
inventory caxton provides.

Explicitly naming an ignored path with `--read` is always fine: reading it is
not destructive.

## Ignore and Safety Rules

### Soft: whatever git says

The visible set is seeded from
`git ls-files -z --cached --others --exclude-standard`. Negation, nested
`.gitignore` files, anchored rules, `.git/info/exclude`, and `core.excludesFile`
all behave exactly as git defines them, because caxton does not reimplement
them. `IGNORED_DIRS`, `IGNORED_FILES`, and the fallback `.gitignore` matcher are
deleted.

### Explicit selection overrides soft ignores

Following
[ripgrep's rule for explicit path arguments](https://github.com/BurntSushi/ripgrep/discussions/1589),
a path the user typed is stronger evidence of intent than a general ignore rule:

- A path typed on the command line is **explicit**: it overrides git's ignore
  rules, and a hard exclusion on it is a fatal error rather than a silent skip.
- A path read from `--read-from`/`--edit-from`, and any path discovered by
  walking a selected directory, is **implicit**: ordinary ignore rules apply,
  and hard exclusions are skipped and counted.

The distinction matters because bulk producers do not know about ignore rules.
`find . -name '*.md' -print0` happily emits `node_modules` and `.env`; treating
those as explicit would inline thousands of vendored files and abort the run on
the first credential path.

An explicitly named ignored **directory** is walked, and every non-hard-excluded
regular file beneath it is admitted. Git considers the whole subtree ignored, so
there are no nested rules left to honor within it.

### Hard: never yields

These are safety boundaries, not conveniences, and apply to explicit paths too:

- Credential paths and credential-like files (`.ssh/`, `.aws/`, `.npmrc`,
  `.netrc`, `*.pem`, `id_rsa*`, and the rest of the existing lists).
- Symlinks.
- Sockets, FIFOs, devices, and other non-regular entries.
- Submodule boundaries. A path inside a submodule is governed by a different
  repository's index and restorability; caxton reports it and directs the user
  to run inside that repository.
- Anything resolving outside the repository top level.

An explicit request for a hard-excluded path fails with a specific error.
Silently dropping it would make the declared selection differ from the actual
authority without telling anyone.

Hard exclusions apply to creation as well as to reading, with one deliberate
narrowing: the credential *patterns* block reading and sending, while creation
is blocked only for credential directories and non-regular replacements. This
avoids refusing an ordinary request to add `.env.example`.

## Command-Line Interface

```text
Usage: caxton "PROMPT" [OPTIONS]

Arguments:
  PROMPT              Instruction, question, or goal for the agent. Must come
                      before any path option.

Options:
  --read PATH...      Make paths visible to the model. (default: '.')
  --edit PATH...      Make paths visible and writable. Any --edit makes this a
                      mutation run and requires a clean git worktree.
  --read-from FILE    Read additional --read paths from FILE, '-' for stdin.
  --edit-from FILE    Read additional --edit paths from FILE, '-' for stdin.
  -0, --null          Path list files are NUL-delimited, not one path per line.
  --inline PATH...    Inline only these paths. (default: everything visible)
  --no-inline         Inline nothing.
  -n, --dry-run       Print the resolved policy and payload, then exit.
  --force             Bypass safety checks.
  ...                 (--model, --thinking, --search, --code, --max-steps,
                       --timeout, --help unchanged)
```

`PROMPT` is the only positional argument, and it must precede the list-valued
options: `--read a.md "Check this"` parses `"Check this"` as a third path.
Caxton detects the resulting missing prompt and says so explicitly rather than
proceeding.

### Defaults and empty selections

- No selection options at all means `--read .`, preserving today's default of
  auditing the current directory read-only.
- Positional-style values and path-list files are combined.
- A path list that yields zero entries is an **explicit empty selection**, not
  an omission: it does not fall back to `.`. If everything resolves to an empty
  selection, caxton reports it and exits 0 without calling the API. This keeps
  an empty `git ls-files` result from silently expanding a narrow operation into
  a whole-directory one.

### Removed

`-i`/`--in-place` and `-o`/`--output` are both gone. Mutation is now selected by
naming what may be modified, which is more explicit than a mode flag and cannot
be true of paths the user did not name.

Losing `--output` costs the ability to transform a copy. The replacement is
better: `git worktree add ../scratch` for isolation, and `git diff` for review.
The copy `-o` produced was never faithful anyway — it dropped symlinks, ignored
files, and credential paths.

The `--output`/`-o` contract in
`skills/coding-standards/references/cli-tools.md` binds scripts that "produce a
new file or directory as output". After this change caxton produces neither: it
edits the worktree and writes a report to stdout. The name `-o` is retired
rather than reused.

## Tool Behavior

Every model-facing operation consults the same policy:

| Operation                   | Requires                                       |
| --------------------------- | ---------------------------------------------- |
| Initial prompt construction | inlined                                        |
| `list_files`                | visible                                        |
| `read_file`                 | visible                                        |
| `search_and_replace`        | writable, path exists                          |
| `write_file` (overwrite)    | writable, path exists                          |
| `write_file` (create)       | creatable parent, path absent, not git-ignored |
| `delete_file`               | writable, path exists                          |

Mutation tools are withheld entirely from a read-only run. In a mutation run,
being offered a tool does not imply it may operate on every path; each call
passes a path-level check.

A path the model creates becomes visible and writable for the remainder of the
run — otherwise it could not re-read what it just wrote.

The initial prompt states which paths are writable, which directories accept new
files, and that everything else is invisible, so the model does not spend steps
discovering the boundary.

## Dry Run

`--dry-run` is how the granted authority gets audited. It reports the
repository, the mode, the resolved per-path capabilities, the creation roots,
explicit overrides of ignore rules, hard exclusions, inlined size, and the tool
surface:

```text
Resolved Files:
  [RWI]  docs/guide.md (1.2 KB)
  [R-I]  docs/architecture.md (4.0 KB)
  [R--]  docs/logo.png (12.0 KB)
  (R = visible, W = writable, I = inlined)
```

## Implementation Sketch

1. Resolve the repository top level; fail with a specific error when caxton is
   not inside a worktree, and exit 127 when git is missing.
1. Parse the prompt, selection lists, inline narrowing, and execution options.
1. Read path-list files, recording whether the caller supplied an explicit empty
   set.
1. Normalize every selector against the repository root, classify it with
   `lstat` without following symlinks, and retain whether it was typed or
   listed.
1. Inventory eligible paths once from the git listing, separating soft ignores
   from hard exclusions.
1. Expand directory selectors and compile per-path visibility and writability
   plus the writable directory prefixes that permit creation.
1. Resolve the inline set as a subset of the visible set, erroring on any path
   that is not visible or not text.
1. Query the policy — `visible`, `writable`, `can_create`, `inlined` — from
   every tool, from prompt construction, and from the dry-run report, so no code
   path performs its own discovery.

Secure file opening and the refusal to follow symlinks stay in place after
policy resolution: the capability check authorizes, and the final `O_NOFOLLOW`
open plus `fstat` defends against a path being replaced between discovery and
use.

## Review Criteria

- **Predictability** — access follows from `--read`/`--edit`, specificity, and
  the inline narrowing, with no hidden mode interactions.
- **Least authority** — naming a subset never grants access to anything else.
- **Consistency** — initial context and every tool consult one policy.
- **Restorability** — everything writable is restorable by git.
- **Composability** — large selections arrive safely from standard Unix path
  producers.
- **Failure safety** — empty selections, hard exclusions, and unrestorable
  writes fail without broadening the operation.
- **Explainability** — `--dry-run` describes the model's authority accurately.

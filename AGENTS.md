# Development Guidelines

This is a public collection of dotfiles, agent skills, and focused command-line
tools. These rules apply to all changes, including code, configuration,
documentation, tests, commit messages, and other repository metadata.

## Engineering Approach

Favor stable, predictable, and understandable tools over novelty or peak
performance. Keep scripts focused, but handle real boundaries—arguments, files,
subprocesses, cleanup, signals, and network failures—carefully. Prefer clear,
established solutions and sequential control flow; add dependencies,
abstractions, concurrency, or optimizations only for a concrete need. Preserve
deterministic interfaces and test in proportion to the risk of the change.

Before adding a capability, search for an existing canonical implementation.
Avoid competing tools, while preferring small local helpers over premature
shared abstractions.

## Standards and Sources of Truth

This file contains repository-specific priorities. The detailed implementation
rules remain in the applicable guides under
`skills/coding-standards/references/`, including `shell.md`, `python.md`,
`cli-tools.md`, and `caching.md`. Read them before substantive changes and use
the formatting scripts in `skills/coding-standards/scripts/` rather than their
underlying tools directly. Where this file is more opinionated, follow it.

## Privacy and Information Control

This repository is strictly public. You must enforce rigid data segregation
across all code, documentation, commit messages, and metadata to protect
personal privacy and proprietary information.

### Companion Repositories

This public repository works in tandem with two private companion repositories:

1. **`private`** (at `~/.private`): For personal secrets and private
   configurations.
1. **`corp`** (at `~/.corp`): For employer-specific work and internal tools.

When operating in either of these companion workspaces, you MUST locate and
adhere to their respective `AGENTS.md` files. The companion `AGENTS.md` files
provide domain-specific privacy constraints that supersede the rules here, while
all general coding standards and script requirements from this document still
apply.

- **Public Safety:** All commits must be strictly safe for public consumption.
  Never include unreleased features, internal API endpoints, private
  credentials, or proprietary algorithms.
- **Employer Anonymity:** Never leak internal, proprietary, or employer-specific
  information. It must remain impossible to identify the user's current or past
  employers from any data, context, or code structure in this repository.
  - *Action:* Route all employer-specific work, architecture, configurations,
    and documentation exclusively to the `corp` repository.
- **Biographical & Location Security:** Never leak granular, real-time, or
  sensitive personal telemetry. While broad, static associations (such as
  general relevance to London or Melbourne) are acceptable, you must never
  expose exact locations, specific addresses, real-time travel plans, or holiday
  schedules.
  - *Action:* Route all sensitive, personal, or autobiographical data
    exclusively to the `private` repository.
- **Pre-Commit Sanitization:** Before finalizing any commit, verify that no
  protected data (corporate or personal) has been inadvertently included in code
  comments, test fixtures, or documentation.

## Script Quality and Development

This section provides guidelines for script entrypoints in `bin/`, canonical
script sources in `skills/*/scripts/`, as well as the `./install.sh` script.

### General Script Requirements

#### Dependency Checking

Shell scripts must check non-trivial command-line dependencies before doing
substantive work, using the `require()` helper and exit status `127`. The
implementation and usage rules are defined in
`skills/coding-standards/references/shell.md` ("Dependency Checking"). Python
scripts must declare third-party packages in their PEP 723 metadata as described
in `skills/coding-standards/references/python.md`.

#### Safe-Command Declarations

`permission apply` pre-approves every executable in a skill's `scripts/`
directory for local agents by default. When adding or modifying a script (or
subcommand) with destructive, irreversible, or otherwise prompt-worthy behavior,
list it in that skill's `permissions/unsafe` file. The file format and semantics
are documented in `skills/agent-config/SKILL.md` ("Safe-Command Declarations").

#### File Output

If a script produces a new file or directory as output, it must support the
`--output`/`-o` switch defined in
`skills/coding-standards/references/cli-tools.md` ("The `--output`/`-o`
Contract") so callers can redirect output, e.g. to a temporary directory.

#### Compatibility

Compatibility requirements — the supported macOS/Debian utilities, the default
Bash 3.2 target, and when Bash 4.x features are acceptable (with the required
version guard) — are defined in `skills/coding-standards/references/shell.md`
("Compatibility and Bash Versions").

#### Handling APK Archives

APK tools that operate on a base APK must accept both a standalone `.apk` and a
`.zip` containing a `*-base-split.apk`. Preserve the established extraction,
validation, and temporary-directory cleanup behavior in `skills/apk/scripts/`;
adapt it to the script's structure rather than maintaining a separately copied
"standard" block in this document.

### CLI Design and Documentation

Scripts must follow [clig.dev](https://clig.dev/) plus this repo's local delta
on top of it, and comprehensive documentation guidelines.

@skills/coding-standards/references/cli-tools.md
@skills/coding-standards/references/shell.md

### Fish Shell Completions

Scripts may have a Fish shell completion file. When updating a script, you must
also update its completion file if one exists.

#### Where Completion Files Live

A completion file is named `<script-name>.fish` and lives beside what it
completes, so it travels with the script:

- **Skill scripts:** `skills/<skill>/completions/<script-name>.fish`, for the
  script `skills/<skill>/scripts/<script-name>`. `fish/config.fish` (and
  `_load_overlay` for `~/.private` and `~/.corp`) adds every
  `skills/*/completions/` directory to `fish_complete_path`, so nothing is
  copied or installed.
- **Other `bin/` scripts and fish functions:** `fish/completions/`.

Helpers shared by several completion files (such as `__fish_android_devices`)
live in `fish/functions/`.

#### Completion Requirements

- When adding, removing, or modifying command-line options in a script, update
  the corresponding completion file
- When adding a new script that accepts command-line options, consider creating
  a completion file
- Completion files should provide completions for all documented options and
  subcommands

`tests/test-fish-completions` (run in CI) enforces the layout above and checks
each completion file against its script's `--help`: every option `--help`
defines must be completed and, for a script without subcommands, every completed
option must be defined by `--help`. A script's `--help` is the source of truth;
fix the completion file, not the test.

```bash
prove tests/test-fish-completions
```

### Example

If you modify `skills/jetpack/scripts/jetpack` to add a new subcommand or
option, you must also update `skills/jetpack/completions/jetpack.fish` to
include completions for the new functionality.

### Generated Command Index Blocks

Some Markdown files (most `references/command-index.md` files) contain blocks
generated from a script's `--help` output, delimited by marker comments:

```markdown
<!-- generated: ../scripts/my-script --help -->
(generated fenced block)
<!-- /generated -->
```

Never edit the content between these markers by hand: it is overwritten by
`bin/command-index-format`. The script's `usage()`/help text is the single
source of truth.

After changing any script's interface or help text, refresh the generated
blocks:

```bash
bin/command-index-format --all
```

CI runs `command-index-format --check --all` to verify that generated blocks are
up to date. The command named in a marker is executed with its working directory
set to the directory containing the Markdown file (hence the `../scripts/`
prefix).

### Tests

Some scripts have associated tests (TAP format, run with `prove`). Test layout,
running instructions (including offline and isolated environments), and
authoring guidelines are documented in `tests/README.md`. Scripts with tests
carry a `# Tests:` comment pointing at their test file.

When modifying a script with tests, review whether the tests need updating.

### Examples from This Repository

See these canonical sources for reference implementations:

- `skills/jetpack/scripts/jetpack` - a large Bash CLI with caching, offline
  behavior, temporary-resource cleanup, and targeted tests
- `skills/agent-config/scripts/skill` - a substantial standalone Python CLI with
  filesystem and network boundaries
- `skills/apk/scripts/apk-unzip` - a small utility with an optional `--output`
- `bin/macos-finder-reveal` - a focused, macOS-specific utility

The `bin/` entries for skill scripts are convenience symlinks; edit the
canonical source under `skills/*/scripts/`. Examples illustrate useful patterns,
not a requirement to copy every implementation choice into a simpler command.

### Skill Design and Capability Ownership

When creating or modifying agent skills under `skills/`, keep user-facing
capabilities centralized and avoid overlapping tools.

- **Prefer General Capabilities**: Do not package generic scripts (e.g., for
  capturing screenshots, recording video, managing Wear OS Tiles, or setting
  system themes) inside specialized skills. If another skill (like the **`adb`**
  skill) already contains dedicated, pre-approved scripts for these tasks, the
  new skill must remain **reference-only (no scripts/ directory)**.
- **Instruct via References**: Within the skill's reference guides, describe the
  *general capability* (e.g., "To dynamically add a Tile on the watch...") and
  explicitly direct the reader/agent to search other active skills (like `adb`)
  for the automation scripts that implement it.
- **Distinguish overlap from local code**: This rule prevents duplicate tools,
  not every repeated implementation detail. A short local helper can be clearer
  and more stable than coupling unrelated scripts through a shared library.
- **Centralize Development Guidelines**: Do not write meta-guidelines (such as
  "do not duplicate scripts") inside a skill's main `SKILL.md`. Keep the
  `SKILL.md` focused entirely on user-facing and agent-facing usage. Place all
  skill development, styling, and coding guidelines here in `AGENTS.md` or under
  the `coding-standards` skill.

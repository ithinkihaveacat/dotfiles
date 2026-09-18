# Development Guidelines

This is a public collection of dotfiles, agent skills, and focused command-line
tools. These rules apply to all changes, including code, configuration,
documentation, tests, commit messages, and other repository metadata.

## Engineering Approach

Optimize for dependable tools that remain understandable and useful over time.
In this repository, stability and predictability are more important than novelty
or peak performance.

- **Prefer established, boring solutions.** Use platform facilities and mature
  dependencies with well-understood behavior. Do not adopt a new framework,
  dependency, language feature, or optimization without a concrete benefit.
- **Keep focused tools focused.** A script may be thorough without becoming a
  framework. Extend an existing command when the new behavior belongs to its
  domain; otherwise create a small, cohesive tool with a clear interface.
- **Be robust at real boundaries.** Treat arguments, files, subprocesses,
  signals, temporary resources, network failures, and machine-readable output
  deliberately. Handle plausible failure modes and preserve useful diagnostics,
  but do not add complexity for purely hypothetical cases.
- **Choose clarity over cleverness.** Prefer explicit control flow, standard
  library features, and small local helpers. Optimize only after identifying a
  meaningful bottleneck; avoid concurrency or intricate job control when a
  sequential implementation is sufficiently reliable.
- **Preserve compatibility and behavior.** Existing scripts are personal tools
  as well as agent interfaces. Keep output, exit status, ordering, and side
  effects deterministic. Treat interface changes as compatibility changes and
  update documentation, completions, generated indexes, and tests together.
- **Test in proportion to risk.** Add targeted regression coverage for parsing,
  destructive operations, cleanup, process lifecycle, and previously observed
  failures. Prefer hermetic tests and fixtures over live services, timing
  assumptions, or host-specific state.

Before adding a capability, search `bin/`, `skills/*/scripts/`, and existing
references. There should normally be one canonical implementation of a user
capability. Small, transparent duplication can be preferable to a premature
shared abstraction, but do not create competing commands that solve the same
problem.

## Standards and Sources of Truth

This file states repository-specific priorities and workflow requirements. The
guides in `skills/coding-standards/references/` define the detailed,
language-specific rules and are the source of truth for implementation style:

- `shell.md` for shell compatibility, error handling, dependencies, and help
- `python.md` for standalone Python scripts, typing, and process handling
- `cli-tools.md` for command shape, output streams, exit codes, and help text
- `caching.md` for network access, caches, and offline behavior
- `markdown.md` and `git.md` for documentation and commit conventions

Read the applicable guides before making a substantive change. Use the
formatting scripts in `skills/coding-standards/scripts/` rather than invoking
their underlying formatters directly. When this file is more opinionated than a
general coding guide, follow this file; do not copy general guidance here merely
to make it more visible.

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
are documented in `skills/workspace-tools/SKILL.md` ("Safe-Command
Declarations").

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

Scripts in `bin/` may have corresponding Fish shell completion files in
`fish/completions/`. When updating a script, you must also update its completion
file if one exists.

#### Completion Requirements

- Completion files are named `<script-name>.fish` in `fish/completions/`
- When adding, removing, or modifying command-line options in a script, update
  the corresponding completion file
- When adding a new script that accepts command-line options, consider creating
  a completion file
- Completion files should provide completions for all documented options and
  subcommands

#### Finding Completion Files

Check if a completion file exists for a script:

```bash
# For a script named bin/my-script
ls fish/completions/my-script.fish
```

### Example

If you modify `bin/emumanager` to add a new subcommand or option, you must also
update `fish/completions/emumanager.fish` to include completions for the new
functionality.

### Generated Command Index Blocks

Some Markdown files (most `references/command-index.md` files, plus the
reference implementations in `cli-tools.md`) contain blocks generated from a
script's `--help` output, delimited by marker comments:

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
- `skills/emumanager/scripts/emumanager` - a stateful Bash manager with explicit
  compatibility and process handling
- `skills/workspace-tools/scripts/skill` - a substantial standalone Python CLI
  with filesystem and network boundaries
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

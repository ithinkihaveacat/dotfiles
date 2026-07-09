# Development Guidelines

This document provides development guidelines for this repository, covering
privacy, information control, and script quality. These rules apply to all
commits, including code, configurations, and documentation.

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

All scripts must declare their command-line dependencies using the `require()`
helper, which exits `127` when a command is missing. The implementation and
usage rules are defined in `skills/coding-standards/references/shell.md`
("Dependency Checking").

#### Safe-Command Declarations

`permission apply` pre-approves every executable in a skill's `scripts/`
directory for local agents by default. When adding or modifying a script (or
subcommand) with destructive, irreversible, or otherwise prompt-worthy behavior,
list it in that skill's `permissions/unsafe` file. The file format and semantics
are documented in `skills/workspace-config/SKILL.md` ("Safe-Command
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

Many scripts in this repository need to operate on a base APK. This base APK may
be provided as a standalone `.apk` file or may be contained within a `.zip`
archive as a `*-base-split.apk` file.

To ensure consistency and robustness, all scripts that need to perform this
extraction must use the following exact code block. This logic correctly handles
both cases and ensures that temporary files are cleaned up properly.

**Standard Code for Base APK Extraction:**

```bash
if [[ $1 == *.zip ]]; then
  TMPDIR=$(mktemp -d)
  trap 'rm -rf -- "$TMPDIR"' EXIT
  unzip -q -j "$1" '*-base-split.apk' -d "$TMPDIR"
  BASEAPKS=("$TMPDIR"/*-base-split.apk)
  BASEAPK="${BASEAPKS[0]}"
  if [ ! -f "$BASEAPK" ]; then
    echo "$(basename "$0"): *-base-split.apk not found in zip, aborting" >&2
    exit 1
  fi
else
  BASEAPK="$1"
fi
```

This block assumes that the input file path is in `$1`. If your script uses a
different variable for the input path, you must adapt the code accordingly.

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
`bin/command-index-sync`. The script's `usage()`/help text is the single source
of truth.

After changing any script's interface or help text, refresh the generated
blocks:

```bash
bin/command-index-sync --all
```

`./install.sh` runs `command-index-sync --check --all` and warns when blocks
have drifted. The command named in a marker is executed with its working
directory set to the directory containing the Markdown file (hence the
`../scripts/` prefix).

### Tests

Some scripts have associated tests (TAP format, run with `prove`). Test layout,
running instructions (including offline and isolated environments), and
authoring guidelines are documented in `tests/README.md`. Scripts with tests
carry a `# Tests:` comment pointing at their test file.

When modifying a script with tests, review whether the tests need updating.

### Examples from This Repository

See these scripts for reference implementations:

- `bin/jetpack` - Multiple arguments, optional version and repo URL
- `bin/apk-unzip` - Single argument with an optional `--output`, simple and
  clean
- `bin/packagename` - Subcommand-style manager, Android-specific
- `bin/macos-finder-reveal` - Multiple files, macOS-specific

Each demonstrates proper GNU coreutils style documentation.

### Skill Development and Zero-Duplication

When creating or modifying agent skills under `skills/`, adhere to a strict
**zero-duplication policy** for helper scripts and CLI tools.

- **Prefer General Capabilities**: Do not package generic scripts (e.g., for
  capturing screenshots, recording video, managing Wear OS Tiles, or setting
  system themes) inside specialized skills. If another skill (like the **`adb`**
  skill) already contains dedicated, pre-approved scripts for these tasks, the
  new skill must remain **reference-only (no scripts/ directory)**.
- **Instruct via References**: Within the skill's reference guides, describe the
  *general capability* (e.g., "To dynamically add a Tile on the watch...") and
  explicitly direct the reader/agent to search other active skills (like `adb`)
  for the automation scripts that implement it.
- **Centralize Development Guidelines**: Do not write meta-guidelines (such as
  "do not duplicate scripts") inside a skill's main `SKILL.md`. Keep the
  `SKILL.md` focused entirely on user-facing and agent-facing usage. Place all
  skill development, styling, and coding guidelines here in `AGENTS.md` or under
  the `coding-standards` skill.

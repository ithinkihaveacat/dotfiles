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
function. This function checks for the existence of the specified commands and
exits with an error if any are missing.

```bash
# Good
require adb
require apkanalyzer
```

#### Safe-Command Declarations

`permission apply` pre-approves every executable in a skill's `scripts/`
directory for local agents by default. If a script (or one of its subcommands)
is destructive, irreversible, or otherwise should always prompt, it must be
listed in that skill's `permissions/unsafe` file (one pattern per line; a bare
script name suppresses pre-approval entirely, a `script subcommand` line guards
just that subcommand). When adding or modifying a script with destructive
behavior, update this file. See `skills/workspace-config/SKILL.md` for details.

#### File Output

If a script produces a new file or directory as output, it must support an
optional `--output` switch to allow callers to specify the output path. This is
crucial for allowing scripts to work with temporary directories.

The `--output` path can be a file or a directory, depending on the tool's
purpose.

- If the specified path does not exist, the tool should create it.
- If the output is a directory, the tool must not delete it on successful
  completion. The calling process is responsible for any cleanup. The tool
  should only delete a temporary directory if the tool itself fails.

```bash
# Good: Output to a file
my-script --output /tmp/my-output.txt

# Good: Output to a directory
another-script --output /tmp/my-output-dir
```

#### Compatibility

Scripts must be compatible with standard utilities (e.g., `grep`, `awk`, `tr`)
found in any macOS or Debian stable release that was current within the last two
years.

Scripts should target Bash version 3.2.57(1)-release (the default on recent
macOS versions as of Nov 2025) for maximum compatibility. This is especially
important for short scripts and general-purpose utilities.

For longer, more complex scripts where modern Bash features significantly
improve reliability and robustness, Bash 4.x features are acceptable. However,
scripts using Bash 4.x features must include a version guard at the top to fail
gracefully on older systems:

```bash
#!/usr/bin/env bash

if ((BASH_VERSINFO[0] < 4)); then
  echo "$(basename "$0"): requires bash 4.0 or higher (found ${BASH_VERSION})" >&2
  exit 1
fi
```

Guidelines for using Bash 4.x features:

- Use only when it provides clear benefits to reliability, robustness, or
  maintainability
- Prefer simple, well-established features (e.g., associative arrays,
  `readarray`) over exotic ones
- Avoid features that are conceptually or syntactically "odd", even if
  technically superior
- Never use Bash 5.x-specific features

Examples of acceptable Bash 4.x features for complex scripts:

- Associative arrays (`declare -A`) for lookups and mappings
- `readarray`/`mapfile` for safer array population
- `${var,,}` and `${var^^}` for case conversion (sparingly)

Examples of features to avoid:

- Bash 5.x features (e.g., `${var@U}`, `${var@u}`)
- Obscure parameter expansions that harm readability
- Any feature that would confuse maintainers familiar with basic Bash

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

Scripts must follow the predictable standard for command-line interfaces and
comprehensive documentation guidelines.

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

Some `references/command-index.md` files contain blocks generated from a
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

Some scripts have associated tests in the `tests/` directory. Tests use the TAP
(Test Anything Protocol) format and can be run with `prove` or executed
directly.

#### Directory Structure

```text
tests/
└── <script-name>/
    ├── test-basic           # TAP test file (executable)
    └── fixtures/            # Test data (images, sample files, etc.)
```

#### Test Requirements

- Test files should be executable and output TAP format
- Tests must be safe to run in parallel (avoid shared temporary files or state)
- Tests can be run in parallel for speed (e.g., `prove -j 9 tests/*/test-*`)
- Scripts with tests include a `# Tests:` comment pointing to their test
  directory
- When modifying a script with tests, review whether the tests need updating
- Tests that call external APIs (e.g., Gemini) are expensive and slow; run them
  manually when making substantive changes to the tested script

#### Finding Tests

Check if a script has associated tests:

```bash
# Look for a Tests comment in the script
grep '# Tests:' bin/my-script

# Or check the tests directory
ls tests/my-script/
```

#### Isolated Environments & Dependency Caching

Some test suites in this repository (such as
`tests/workspace-config/test-skill`) run scripts in an isolated, hermetic
environment by overriding `HOME` or `XDG_CONFIG_HOME` (e.g., to
`/tmp/.../mock_home`).

This isolation is crucial for testing clean environments, but it prevents
package managers (like `uv` or `pip`) from accessing your corporate or personal
credentials (like `gpkg` or `gcloud` tokens stored in your real `HOME`
directory), resulting in `401 Unauthorized` errors when they attempt to download
dependencies.

To run these tests successfully:

1. **Warm the Cache**: Run a command that uses the dependency outside the
   isolated test environment first (or run the tool itself) to ensure the
   packages are downloaded and cached in your host's package manager cache
   (e.g., `~/.cache/uv`).
1. **Share the Cache**: Execute the test runner while passing/exporting your
   host's cache directory environment variable. The isolated package manager
   will then resolve dependencies offline from the local cache without hitting
   the network or requiring authentication.

For `uv`-based tests, you can execute the test suite by exporting
`UV_CACHE_DIR`:

```bash
UV_CACHE_DIR=~/.cache/uv ./skills/workspace-config/tests/test-skill
```

This is a robust and fast way to run hermetic tests that rely on external
packages.

### Examples from This Repository

See these scripts for reference implementations:

- `bin/jetpack` - Multiple arguments, optional version and repo URL
- `bin/apk-cat-file` - Two required arguments, simple and clean
- `bin/packagename` - Single argument, Android-specific
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

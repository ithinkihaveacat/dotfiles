# Script Quality Guidelines

This document provides guidelines for script entrypoints in `bin/`, canonical
script sources in `skills/*/scripts/`, as well as the `./update` script.

## General Script Requirements

### Dependency Checking

All scripts must declare their command-line dependencies using the `require()`
function. This function checks for the existence of the specified commands and
exits with an error if any are missing.

```bash
# Good
require adb
require apkanalyzer
```

### File Output

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

### Compatibility

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

### Handling APK Archives

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

## CLI Design and Documentation

Scripts must follow the predictable standard for command-line interfaces and
comprehensive documentation guidelines.

@context/cli-tools.md @context/shell.md

## Fish Shell Completions

Scripts in `bin/` may have corresponding Fish shell completion files in
`fish/completions/`. When updating a script, you must also update its completion
file if one exists.

### Completion Requirements

- Completion files are named `<script-name>.fish` in `fish/completions/`
- When adding, removing, or modifying command-line options in a script, update
  the corresponding completion file
- When adding a new script that accepts command-line options, consider creating
  a completion file
- Completion files should provide completions for all documented options and
  subcommands

### Finding Completion Files

Check if a completion file exists for a script:

```bash
# For a script named bin/my-script
ls fish/completions/my-script.fish
```

### Example

If you modify `bin/emumanager` to add a new subcommand or option, you must also
update `fish/completions/emumanager.fish` to include completions for the new
functionality.

## Tests

Some scripts have associated tests in the `tests/` directory. Tests use the TAP
(Test Anything Protocol) format and can be run with `prove` or executed
directly.

### Directory Structure

```text
tests/
└── <script-name>/
    ├── test-basic           # TAP test file (executable)
    └── fixtures/            # Test data (images, sample files, etc.)
```

### Test Requirements

- Test files should be executable and output TAP format
- Scripts with tests include a `# Tests:` comment pointing to their test
  directory
- When modifying a script with tests, review whether the tests need updating
- Tests that call external APIs (e.g., Gemini) are expensive and slow; run them
  manually when making substantive changes to the tested script

### Finding Tests

Check if a script has associated tests:

```bash
# Look for a Tests comment in the script
grep '# Tests:' bin/my-script

# Or check the tests directory
ls tests/my-script/
```

## Examples from This Repository

See these scripts for reference implementations:

- `bin/jetpack` - Multiple arguments, optional version and repo URL
- `bin/apk-cat-file` - Two required arguments, simple and clean
- `bin/packagename` - Single argument, Android-specific
- `bin/macos-finder-reveal` - Multiple files, macOS-specific

Each demonstrates proper GNU coreutils style documentation.

# Script Quality Guidelines

This document provides guidelines for all scripts in the `bin/` subdirectory.

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

All scripts must be compatible with Bash version 3.2.57(1)-release (the default
on recent macOS versions as of Nov 2025) and newer versions found on recent
Linux distributions. This means avoiding features exclusive to newer Bash
versions (e.g., associative arrays).

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

## Script Documentation Guidelines

All scripts in `bin/` should provide comprehensive help documentation following
GNU coreutils conventions.

### Basic Structure

Each script should include:

1. A `usage()` function that displays help text
2. Support for `-h` and `--help` flags
3. Clear error messages following GNU coreutils patterns
4. Practical examples demonstrating common use cases

### Implementation Pattern

```bash
#!/usr/bin/env bash

usage() {
  cat <<EOF
Usage: $(basename "$0") ARGUMENTS [OPTIONS]

Brief description of what the script does.

Arguments:
  ARG1        Description of first argument
  ARG2        Description of second argument (optional if optional)

Options:
  -h, --help  Display this help message and exit

Examples:
  $(basename "$0") example1
  $(basename "$0") example2 --option
  $(basename "$0") example3 with multiple arguments

Additional explanation of behavior, edge cases, or important details.
EOF
  exit 0
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  usage
fi

# Rest of script...
```

### Key Requirements

#### 1. Function Naming

Use `usage()` instead of `help()`:

- `help` is a bash builtin command
- Using `help()` would shadow the builtin
- `usage()` is the established convention in shell scripting

#### 2. Help Output Structure

Follow GNU coreutils style (see `ls --help`, `cp --help`, `grep --help` for
comprehensive examples):

- **Usage line**: Show command syntax with argument placeholders in CAPS
- **Description**: One-line summary of what the script does
- **Arguments section**: Document positional arguments (not "Options" for
  positional args)
- **Options section**: Document flags like `-h, --help`
- **Examples section**: Provide 2-3 practical examples
- **Additional notes**: Explain important behavior or caveats (optional)

#### 3. Error Messages

Follow GNU coreutils error message patterns:

```bash
# Good (GNU coreutils style):
echo "$(basename "$0"): missing file operand" >&2

# Avoid:
echo "usage: $(basename "$0") args"
```

Examples from coreutils:

```bash
$ cp
cp: missing file operand

$ rm
rm: missing operand

$ mv
mv: missing file operand
```

Key points:

- Format: `command: description of error`
- Write to stderr (`>&2`)
- Use "operand" terminology for missing arguments
- Do NOT include "Try 'command --help'" message (omit the second line)

#### 4. Exit Codes

- `exit 0` for successful help display (`--help`)
- `exit 1` for errors (missing arguments, invalid input)
- `exit 127` for missing required commands (convention for "command not found")

#### 5. Examples Section

Always include practical examples:

- Show 2-3 common use cases
- Where appropriate, include one or two less obvious or more advanced examples
  to inspire creative uses of the script.
- Use realistic file names or package names
- Demonstrate different argument patterns
- Use `$(basename "$0")` for portability

#### 6. What NOT to Include

- **Dependencies**: Don't list required commands in the help text (they'll fail
  early anyway)
- **Implementation details**: Focus on usage, not how it works internally
- **Version information**: Not needed for personal utility scripts
- **Excessive options**: Only document `-h, --help` unless the script has other
  flags

### Top-of-File Comments

Do not embed substantive help-like information in comments at the top of a
script. This information can become outdated and is not easily accessible to
users.

- **DO:** Move any descriptive comments about the script's purpose, usage, or
  behavior into the `usage()` function's heredoc.
- **DON'T:** Leave large comment blocks at the top of the file explaining what
  the script does.

"Inline" comments that explain specific lines of code are acceptable.
Commented-out code for debugging purposes is also fine.

### Reference Examples

Good examples of comprehensive help output from GNU coreutils:

```bash
ls --help      # Comprehensive, well-organized options
cp --help      # Clear argument documentation
grep --help    # Good examples section
tar --help     # Detailed but readable
```

Study these for formatting conventions, terminology, and structure.

### Checklist for New Scripts

- [ ] `usage()` function defined (not `help()`)
- [ ] Checks for `-h` and `--help` before other validation
- [ ] Usage line with argument syntax
- [ ] Brief description of script purpose
- [ ] Arguments section (for positional args)
- [ ] Options section (for flags)
- [ ] Examples section with 2-3 practical examples (including novel cases where
      appropriate)
- [ ] Error messages follow GNU coreutils pattern
- [ ] Error messages write to stderr
- [ ] Proper exit codes (0 for help, 1 for errors)
- [ ] No dependency lists in help text

## Linting with ShellCheck

All bash scripts in `bin/` must be linted with `shellcheck` to ensure they are
free of common errors.

### Requirements

- Before committing any changes to a script, run `shellcheck` on it.
- All reported lint errors must be fixed.
- If an error cannot be fixed, it can be ignored using a `shellcheck disable`
  comment. See the
  [ShellCheck wiki](https://github.com/koalaman/shellcheck/wiki/Ignore) for more
  information.

### Example

```bash
# Good
shellcheck my-script.sh

# Good (with ignored error)
# shellcheck disable=SC2086
echo $VAR
```

## Formatting Markdown with Prettier

All Markdown files (`.md`) in this repository must be formatted using
`prettier`.

### Requirements

- Before committing any changes to a Markdown file, run `prettier` on it.
- The formatting configuration is defined in the `.prettierrc` file in the root
  of the repository.

### Example

```bash
# Good
prettier --write README.md
```

## Examples from This Repository

See these scripts for reference implementations:

- `bin/context-jetpack` - Multiple arguments, optional repo URL
- `bin/apk-cat-file` - Two required arguments, simple and clean
- `bin/packagename-services-dumpsys` - Single argument, Android-specific
- `bin/select` - Multiple files, macOS-specific

Each demonstrates proper GNU coreutils style documentation.

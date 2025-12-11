# Script Quality Guidelines

In addition to the rules in this file, please follow the rules in
@etc/AGENTS.md. In case of conflict, the rules in this file override those in
@etc/AGENTS.md.

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

Scripts must be compatible with standard utilities (e.g., `grep`, `awk`, `tr`)
found in any macOS or Debian stable release that was current within the last
two years.

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

**For scripts with subcommands**, follow git-style error messages that include
the subcommand name:

```bash
# Good (git-style for subcommands):
echo "$(basename "$0") create: AVD name required" >&2

# Avoid (too generic):
echo "$(basename "$0"): missing operand" >&2
```

Examples from git:

```bash
$ git commit
fatal: no changes added to commit

$ git push origin
fatal: The current branch has no upstream branch

$ git checkout
fatal: you must specify path(s) to restore
```

Key points:

- Format: `command: description of error` (simple tools)
- Format: `command subcommand: description of error` (subcommand-based tools)
- Write to stderr (`>&2`)
- Use "operand" terminology for missing arguments (simple tools)
- Use descriptive messages for subcommands (e.g., "AVD name required")
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

## Fish Shell Completions

Scripts in `bin/` may have corresponding Fish shell completion files in
`fish/completions/`. When updating a script, you must also update its completion
file if one exists.

### Requirements

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

## Examples from This Repository

See these scripts for reference implementations:

- `bin/jetpack-source` - Multiple arguments, optional version and repo URL
- `bin/apk-cat-file` - Two required arguments, simple and clean
- `bin/packagename-services-dumpsys` - Single argument, Android-specific
- `bin/select` - Multiple files, macOS-specific

Each demonstrates proper GNU coreutils style documentation.

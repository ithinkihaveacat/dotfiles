# Shell Script Quality

All shell scripts, whether new or updated, should be passed through `shellcheck`
for linting and `shfmt` for formatting.

## Linting

Any errors or warnings from `shellcheck` should be eliminated, or explicitly
ignored if absolutely necessary.

Before committing any changes to a script, run `shellcheck` on it. All reported
lint errors must be fixed.

If an error cannot be fixed, it can be ignored using a `shellcheck disable`
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

## Formatting

All non-Fish shell scripts must be processed by `shfmt`.

Example command:

```bash
shfmt -w -i 2 -ci bin/emumanager
```

- `-w` edits files in-place.
- `-i 2` sets the indent to 2 spaces.
- `-ci` vertically aligns case statements.

## Fish Script Formatting

All Fish shell scripts, whether new or updated, _must_ be formatted by
`fish_indent -w`.

Example command:

```bash
fish_indent -w fish/completions/emumanager.fish
```

- `-w` edits files in-place.

## Script Documentation Guidelines

Scripts should provide comprehensive help documentation following GNU coreutils
conventions.

### Basic Structure

Each script should include:

1. A `usage()` function that displays help text
2. Support for `-h` and `--help` flags
3. Clear error messages following GNU coreutils patterns
4. Practical examples demonstrating common use cases

### Function Naming

Use `usage()` for the help display function, not `help()`:

- `help` is a bash builtin command
- Using `help()` would shadow the builtin
- `usage()` is the established convention in shell scripting

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
  --help      Display this help message and exit

Examples:
  $(basename "$0") example1
  $(basename "$0") example2 --option
  $(basename "$0") example3 with multiple arguments

Additional explanation of behavior, edge cases, or important details.
EOF
  exit 0
}

if [[ "$1" == "--help" ]]; then
  usage
fi

# Rest of script...
```

### Key Requirements

#### 1. Help Output Structure

Follow GNU coreutils style (see `ls --help`, `cp --help`, `grep --help` for
comprehensive examples):

- **Usage line**: Show command syntax with argument placeholders in CAPS
- **Description**: One-line summary of what the script does
- **Arguments section**: Document positional arguments (not "Options" for
  positional args)
- **Options section**: Document flags like `--help`
- **Examples section**: Provide 2-3 practical examples
- **Additional notes**: Explain important behavior or caveats (optional)

#### 2. Examples Section

Always include practical examples:

- Show 2-3 common use cases
- Where appropriate, include one or two less obvious or more advanced examples
  to inspire creative uses of the script.
- Use realistic file names or package names
- Demonstrate different argument patterns
- Use `$(basename "$0")` for portability

#### 3. What NOT to Include

- **Dependencies**: Don't list required commands in the help text (they'll fail
  early anyway)
- **Implementation details**: Focus on usage, not how it works internally
- **Version information**: Not needed for personal utility scripts
- **Excessive options**: Only document `--help` unless the script has other
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
- [ ] Checks for `--help` before other validation
- [ ] Usage line with argument syntax
- [ ] Brief description of script purpose
- [ ] Arguments section (for positional args)
- [ ] Options section (for flags)
- [ ] Examples section with 2-3 practical examples
- [ ] No dependency lists in help text

## Error Handling in Shell Scripts

All shell scripts must have reliable and robust error detection and reporting.
Scripts should gracefully handle invalid input, network errors, missing
dependencies, and failures from other scripts or commands.

### General Principles

Scripts should never crash or hang when encountering expected error conditions.
This includes:

- Invalid or missing command-line arguments
- Network failures or timeouts
- Missing commands or scripts in PATH
- Failures from called scripts or external commands
- Missing or inaccessible files

The only exceptions are errors that are genuinely difficult to detect or recover
from—those requiring many dependencies, lines of code, or complex logic. In such
cases, consider redesigning the script's goals to make error handling simpler
and more maintainable.

### Consistency Across Related Scripts

If a script has companion scripts that are commonly used together, their error
and argument handling must be consistent. For example, the `adb-tile-add` and
`adb-tile-show` scripts form a workflow, so they should handle errors in similar
ways.

It is acceptable—and often preferable—to duplicate error handling code across
related scripts rather than introducing complex abstractions. When duplicating
error handling:

- Keep it concise (approximately 10 lines of code)
- Prioritize readability and small size over clever constructions
- Maintain consistency in error message format and behavior

### Error Messages

Error messages should follow GNU coreutils conventions:

- Format: `program: description of error`
- Write to stderr (`>&2`)
- Be specific and actionable

```bash
# Good (GNU coreutils style)
echo "$(basename "$0"): missing file operand" >&2
echo "Try '$(basename "$0") --help' for more information." >&2

# Avoid
echo "Error: something went wrong"
```

For scripts with subcommands, follow git-style error messages that include the
subcommand name:

```bash
# Good (git-style for subcommands):
echo "$(basename "$0") create: AVD name required" >&2

# Avoid (too generic):
echo "$(basename "$0"): missing operand" >&2
```

It is acceptable (and often helpful) to expose internal implementation details
such as:

- Exact commands that failed
- URLs that were not found
- Missing dependencies or environment variables
- File paths that were accessed

This transparency improves clarity and enables users to diagnose and manually
work around issues.

```bash
# Good - Specific and actionable
if ! command -v jq >/dev/null 2>&1; then
  echo "$(basename "$0"): jq not found" >&2
  exit 1
fi

# Good - Exposes implementation details
if ! curl -sf "$API_URL" >/dev/null; then
  echo "$(basename "$0"): failed to fetch $API_URL" >&2
  exit 1
fi
```

### Exit Codes

Follow these conventions:

- `exit 0` for successful operations and help display (`--help`)
- `exit 1` for general errors (missing arguments, invalid input)
- `exit 127` for missing required commands (convention for "command not found")

### Dependency Checking

Scripts should check for non-trivial dependencies using a helper function.
This ensures consistent error reporting and exit codes. Do not include
instructions on how to install the dependency, as this varies by OS.

```bash
require() {
  command -v "$1" >/dev/null 2>&1 || {
    echo >&2 "$(basename "$0"): $1 not found"
    exit 127
  }
}

require jq
require curl
```

## Handling Large Inputs with jq

When using `jq` to process data, you must account for the system's `ARG_MAX`
limit (often around 256KB). Passing large strings (e.g., file contents, long
prompts) as command-line arguments (like `--arg val "$LARGE_VAR"`) will cause
scripts to crash with "Argument list too long."

### Guidelines

1.  **Avoid reading large inputs into shell variables.** Reading a whole file
    into a variable (e.g., `DATA=$(cat file.txt)`) and then passing it to a
    command is brittle.
2.  **Use `jq` features for input.** Use `--rawfile` for files and `-R` (raw
    input) for stdin.
3.  **Pipe stdin directly.** If processing stdin, pipe it directly into `jq`.

### Examples

**Scenario 1: Input is a file**

Do NOT read the file into a variable. Use `--rawfile`.

```bash
# BAD - Will crash on large files
XML_CONTENT=$(cat "$FILE_PATH")
jq -n --arg xml "$XML_CONTENT" '{ content: $xml }'

# GOOD - Reads file directly, no size limit
jq -n --rawfile xml "$FILE_PATH" '{ content: $xml }'
```

**Scenario 2: Input is from stdin**

Use `jq -Rs` (Raw input + Slurp) to read the entire stdin as a single string.
Inside the `jq` filter, refer to the input as `.`.

```bash
# BAD - Will crash on large inputs
INPUT=$(cat)
jq -n --arg input "$INPUT" '{ content: $input }'

# GOOD - Reads stdin directly
# The '.' represents the input string
jq -Rs '{ content: . }'
```

**Scenario 3: Input is a variable (that might be large)**

If you already have data in a variable, pipe it to `jq` instead of using `--arg`.

```bash
# BAD
jq -n --arg val "$LARGE_VAR" '{ content: $val }'

# GOOD
printf "%s" "$LARGE_VAR" | jq -Rs '{ content: . }'
```

**Why this works:** The `ARG_MAX` limit applies to the arguments passed to a new
process via the `exec()` system call.
1. `jq --arg ...` fails because the shell must pass the huge string to the `jq`
   process.
2. `printf ... | jq` works because `printf` is a shell builtin in Bash. The
   shell handles the data internally and writes it to the pipe without creating a
   new process for `printf`, bypassing the `exec()` limit. `jq` then reads the
   data from stdin, which has no size limit.

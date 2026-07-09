# Shell Script Quality

This is the bash/POSIX implementation guide for the CLI design standard in
`cli-tools.md`. Interface rules — command structure, help text content, error
message style, exit codes — are defined there; this file covers how to meet them
in shell, plus shell-specific quality requirements.

## Formatting and Linting

All shell scripts (POSIX/Bash), whether new or updated, _must_ be linted and
formatted. Use the `scripts/shell-format` script to apply both tools
automatically. You can also pass the `--check` option to verify formatting
without modifying files (e.g. for lint checks).

To format and lint a file in place:

```bash
scripts/shell-format bin/emumanager
```

All reported `shellcheck` errors and warnings must be eliminated before
committing. If an error genuinely cannot be fixed, ignore it explicitly with a
`shellcheck disable` comment (see the
[ShellCheck wiki](https://github.com/koalaman/shellcheck/wiki/Ignore)):

```bash
# shellcheck disable=SC2086
echo $VAR
```

### Implementation Details

Under the hood, `shell-format` runs `shfmt -w -i 2 -ci` (in-place, 2-space
indent, vertically aligned case statements) followed by `shellcheck`. If you
need to run the tools manually or configure editor integration, use those
invocations — but prefer `scripts/shell-format` so the same settings apply
across the repository.

## Fish Script Formatting

All Fish shell scripts, whether new or updated, _must_ be formatted by
`fish_indent -w`.

Example command:

```bash
fish_indent -w fish/completions/emumanager.fish
```

- `-w` edits files in-place.

## Compatibility and Bash Versions

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

## Script Documentation Guidelines

The content and layout of help text — the usage line, section order, examples
policy, and what to leave out — are defined in `cli-tools.md` ("Help Text House
Style"). This section covers implementing that layout in bash.

### Basic Structure

For any shell script intended to be used interactively, its interface must fully
comply with the rules defined in `cli-tools.md` (e.g., handling of help flags,
exit codes, output streams, help text content). The following patterns
demonstrate how to achieve this compliance in bash.

Each script should include:

1. A `usage()` function that displays help text
1. Support for both the `--help` and `-h` flags, checked before any other
   validation

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
  --help, -h  Display this help message and exit

Examples:
  $(basename "$0") example1
  $(basename "$0") example2 --option
  $(basename "$0") example3 with multiple arguments

Additional explanation of behavior, edge cases, or important details.
EOF
  exit 0
}

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
  usage
fi

# Rest of script...
```

In the heredoc, use `$(basename "$0")` rather than a hard-coded script name so
the usage line and examples stay correct if the script is renamed or invoked via
a symlink.

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

### Checklist for New Scripts

- [ ] `usage()` function defined (not `help()`)
- [ ] Checks for `--help` and `-h` before other validation
- [ ] Help text follows the house style in `cli-tools.md` (usage line,
  Arguments/Options/Examples sections, no dependency lists)
- [ ] Errors reported per the error message style in `cli-tools.md`
- [ ] Formatted and linted with `scripts/shell-format`

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
`adb-tile-switch` scripts form a workflow, so they should handle errors in
similar ways.

It is acceptable—and often preferable—to duplicate error handling code across
related scripts rather than introducing complex abstractions. When duplicating
error handling:

- Keep it concise (approximately 10 lines of code)
- Prioritize readability and small size over clever constructions
- Maintain consistency in error message format and behavior

### Error Messages

The message format — GNU coreutils `program: description` style written to
stderr, git-style subcommand prefixes, and transparency about internal details —
is defined in `cli-tools.md` ("Error Message Style"). In bash, prefix messages
with `$(basename "$0")` and write them to stderr:

```bash
# Simple tool — exposes the failing URL, per cli-tools.md
if ! curl -sf "$API_URL" >/dev/null; then
  echo "$(basename "$0"): failed to fetch $API_URL" >&2
  exit 1
fi

# Subcommand tool — includes the subcommand name
echo "$(basename "$0") create: AVD name required" >&2
```

### Exit Codes

Use the exit codes defined in `cli-tools.md` ("Exit Codes: Local Extensions").
In shell scripts that most often means `exit 1` for usage and general errors,
and `exit 127` — via `require()` below — for a missing dependency.

### Dependency Checking

Scripts should check for non-trivial dependencies using a helper function. This
ensures consistent error reporting and exit codes. Do not include instructions
on how to install the dependency, as this varies by OS.

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

1. **Avoid reading large inputs into shell variables.** Reading a whole file
   into a variable (e.g., `DATA=$(cat file.txt)`) and then passing it to a
   command is brittle.
1. **Use `jq` features for input.** Use `--rawfile` for files and `-R` (raw
   input) for stdin.
1. **Pipe stdin directly.** If processing stdin, pipe it directly into `jq`.

### Examples

#### Scenario 1: Input is a file

Do NOT read the file into a variable. Use `--rawfile`.

```bash
# BAD - Will crash on large files
XML_CONTENT=$(cat "$FILE_PATH")
jq -n --arg xml "$XML_CONTENT" '{ content: $xml }'

# GOOD - Reads file directly, no size limit
jq -n --rawfile xml "$FILE_PATH" '{ content: $xml }'
```

#### Scenario 2: Input is from stdin

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

#### Scenario 3: Input is a variable (that might be large)

If you already have data in a variable, pipe it to `jq` instead of using
`--arg`.

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
1. `printf ... | jq` works because `printf` is a shell builtin in Bash. The
   shell handles the data internally and writes it to the pipe without creating
   a new process for `printf`, bypassing the `exec()` limit. `jq` then reads the
   data from stdin, which has no size limit.

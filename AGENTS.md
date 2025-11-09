# Script Documentation Guidelines

This document provides guidelines for documenting scripts in the `bin/` subdirectory.

## Help Function Requirements

All scripts in `bin/` should provide comprehensive help documentation following GNU coreutils conventions.

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

Follow GNU coreutils style (see `ls --help`, `cp --help`, `grep --help` for comprehensive examples):

- **Usage line**: Show command syntax with argument placeholders in CAPS
- **Description**: One-line summary of what the script does
- **Arguments section**: Document positional arguments (not "Options" for positional args)
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
- Where appropriate, include one or two less obvious or more advanced examples to inspire creative uses of the script.
- Use realistic file names or package names
- Demonstrate different argument patterns
- Use `$(basename "$0")` for portability

#### 6. What NOT to Include

- **Dependencies**: Don't list required commands in the help text (they'll fail early anyway)
- **Implementation details**: Focus on usage, not how it works internally
- **Version information**: Not needed for personal utility scripts
- **Excessive options**: Only document `-h, --help` unless the script has other flags

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
- [ ] Examples section with 2-3 practical examples (including novel cases where appropriate)
- [ ] Error messages follow GNU coreutils pattern
- [ ] Error messages write to stderr
- [ ] Proper exit codes (0 for help, 1 for errors)
- [ ] No dependency lists in help text

## Examples from This Repository

See these scripts for reference implementations:
- `bin/context-jetpack` - Multiple arguments, optional repo URL
- `bin/apk-cat-file` - Two required arguments, simple and clean
- `bin/packagename-services-dumpsys` - Single argument, Android-specific
- `bin/select` - Multiple files, macOS-specific

Each demonstrates proper GNU coreutils style documentation.

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

### Error Message Quality

Error messages should be clear and actionable. It is acceptable (and often
helpful) to expose internal implementation details such as:

- Exact commands that failed
- URLs that were not found
- Missing dependencies or environment variables
- File paths that were accessed

This transparency improves clarity and enables users to diagnose and manually
work around issues.

### Example

```bash
# Good - Specific and actionable
if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq command not found. Install via: apt-get install jq" >&2
  exit 1
fi

# Good - Exposes implementation details
if ! curl -sf "$API_URL" >/dev/null; then
  echo "Error: Failed to fetch $API_URL" >&2
  echo "Check network connectivity or verify the URL is accessible" >&2
  exit 1
fi
```

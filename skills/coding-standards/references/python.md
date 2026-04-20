# Python Development

## Formatting and Linting

All Python files, whether new or updated, _must_ be linted and formatted using
`ruff`. This ensures consistency, catches common errors, and maintains a high
standard of code quality.

### Using Ruff

We use `ruff` for both linting and formatting. It's recommended to run it via
`uvx` to ensure you're using a consistent version without needing to manage it
manually in your environment.

To check for linting errors and automatically fix what's possible:

```bash
uvx ruff check --fix file.py
```

To format a file in place:

```bash
uvx ruff format file.py
```

To check both linting and formatting without making changes (useful for CI):

```bash
uvx ruff check file.py && uvx ruff format --check file.py
```

## Python Versions

Scripts should target Python 3.11 or higher unless there is a specific
compatibility requirement for an older version.

## Standalone Scripts

For single-file, self-contained executable scripts, prefer `uv` scripts rather
than depending directly on a `python` or `python3` executable in the shebang. In
other words, if the file is meant to be run as a standalone script, the runtime
dependency should normally be the `uv` executable.

Use this pattern:

```python
#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
```

This guidance applies to executable script entrypoints. It does not apply to
ordinary Python modules, packages, libraries, or non-executable Python source
files.

Rationale:

- It makes the script's execution model explicit and self-contained.
- It keeps the declared Python requirement with the script itself.
- It avoids coupling the script to whichever `python` executable happens to be
  first on `PATH`.
- It aligns with the existing standalone Python script pattern used elsewhere in
  this repository.

If `uv` has trouble running in a constrained environment because of sandbox,
cache, or network restrictions, treat that as an environment problem to solve
with permissions or configuration. Do not change the script to depend on a
specific Python executable merely to work around those constraints.

When creating standalone scripts using `uv`, specify the required version in the
script metadata:

```python
#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
```

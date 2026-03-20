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
compatibility requirement for an older version. When creating standalone scripts
using `uv`, specify the required version in the script metadata:

```python
# /// script
# requires-python = ">=3.11"
# ///
```

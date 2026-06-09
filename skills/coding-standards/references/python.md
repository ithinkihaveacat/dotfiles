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

## Handling Ctrl+C (KeyboardInterrupt)

To prevent Python scripts from dumping ugly tracebacks when interrupted by the
user, always wrap the entry point execution in a `try/except KeyboardInterrupt`
block in the `__main__` guard.

### The Standard Pattern

```python
import sys

def main():
    # Your main logic here
    ...

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        # Print a newline to stderr, guarded against broken pipes
        try:
            sys.stderr.write("\n")
        except Exception:
            pass
        # 130 is the standard POSIX exit code for a script terminated by Ctrl-C
        sys.exit(130)
```

### Rationale

- **No Traceback:** Prevents the default Python behavior of printing a noisy
  `Traceback (most recent call last): ... KeyboardInterrupt` to `stderr`, which
  looks like an application crash.
- **Clean Prompt & Pipeline Safety:** Writing the newline to `sys.stderr`
  ensures it does not pollute redirected `stdout` data (e.g. `tool > file.txt`).
  Guarding the write prevents `BrokenPipeError` crashes if the script is
  interrupted in a pipeline where the reader has already closed the pipe (e.g.
  `tool | head`).
- **Correct Exit Code:** Returning `130` allows calling scripts and shells to
  correctly identify that the process was terminated by `SIGINT`.

### Important Caveats

1. **Cleanup Handling:** `sys.exit(130)` raises `SystemExit`. This is preferred
   over `os._exit` because it allows `finally` blocks, context managers, and
   `atexit` handlers to run normally. Ensure you place critical teardown logic
   (closing files, restoring terminal states, resetting device configs) in these
   mechanisms so they run reliably on interrupt.
1. **Threading:** `KeyboardInterrupt` is only delivered to the *main thread*.
   The script will hang on exit if there are active, non-daemon threads.
   - **Note:** Spawned `daemon=True` threads are terminated abruptly at exit,
     and their `finally` blocks or `atexit` handlers **do not run**. If your
     background threads require clean teardown, do not use `daemon=True`;
     instead, use an explicit stop `Event` and `join()` them during main thread
     cleanup.
1. **Subprocesses:** If managing long-running child processes (e.g. via
   `subprocess.Popen`), ensure you explicitly terminate them
   (`proc.terminate()`) and **reap them** using `proc.wait(timeout=...)`
   (falling back to `proc.kill()` if necessary) in a `finally` or `atexit`
   block. This prevents leaving zombie or orphaned processes.
   - *Note:* In interactive terminal sessions, a `Ctrl+C` is delivered to the
     entire foreground process group, so child processes may already be
     terminating; explicit termination is a robust fallback.

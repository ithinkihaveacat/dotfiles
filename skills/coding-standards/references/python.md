# Python Development

## Formatting and Linting

All Python files, whether new or updated, _must_ be linted and formatted. Use
the `scripts/python-format` script to apply both tools automatically.

To format and check a file in place:

```bash
scripts/python-format file.py
```

To format from stdin to stdout:

```bash
cat file.py | scripts/python-format > formatted.py
```

To check for issues without making changes (useful for CI):

```bash
scripts/python-format --check file.py
```

### Implementation Details

Under the hood, `python-format` uses `ruff` (run via `uvx` for version
consistency) to perform both linting and formatting. If you need to run `ruff`
manually or configure editor integration, you can use:

```bash
uvx ruff check --fix file.py
uvx ruff format file.py
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

### Handling Ctrl+C, Signals, and Broken Pipes

To ensure a professional user experience, Python CLI tools in this repository
should exit cleanly without dumping raw interpreter tracebacks when interrupted
by the user or when their output pipe is closed by a downstream process (e.g.,
when piped to `head`).

We follow a **tiered approach** depending on the complexity of the script.

______________________________________________________________________

### Tier 1: The Baseline Pattern (For Simple Scripts)

For 90% of Python scripts—those that are synchronous, single-threaded, and do
not spawn subprocesses—you only need to catch `KeyboardInterrupt` at the top
level, write a guarded, flushed newline to `stderr`, and exit with `130`.

#### The Baseline Snippet

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
            sys.stderr.flush()
        except Exception:
            pass
        # 130 is the standard POSIX exit code for a script terminated by Ctrl-C
        sys.exit(130)
    except BrokenPipeError:
        # Python flushes standard streams on exit; redirect remaining output
        # to devnull to avoid another BrokenPipeError at shutdown
        import os
        devnull = os.open(os.devnull, os.O_WRONLY)
        os.dup2(devnull, sys.stdout.fileno())
        # 141 is the standard POSIX exit code for a script terminated by SIGPIPE
        sys.exit(141)
```

#### Rationale

- **No Traceback:** Suppresses noisy CPython tracebacks on `Ctrl+C` and broken
  pipes, keeping the CLI feeling like a native system utility.
- **Pipeline Safe:** Catching `BrokenPipeError` at the top level and redirecting
  standard output to `/dev/null` ensures the script exits cleanly and silently
  when its output is piped into another command that terminates early (e.g.,
  `tool | head`).
- **No Redirection Pollution:** Writing the cosmetic interrupt newline to
  `stderr` instead of `stdout` prevents polluting redirected output files (e.g.
  `tool > data.txt`).
- **Guaranteed Output:** Explicitly flushing standard streams ensures all output
  is written before the interpreter completes its shutdown sequence.

______________________________________________________________________

### Tier 2: The Advanced Pattern (Opt-in / "Only if...")

If your script is more sophisticated and meets **any** of the following
criteria, you must adopt the advanced pattern:

- It spawns **child processes** (e.g., via `subprocess.Popen`).
- It uses **background threads**.
- It is **asynchronous** (uses `asyncio`).
- It performs critical **device cleanup** or state restoration (like `popper`).
- It holds **external locks or transactional state** (e.g., file locks, database
  transactions, API leases) managed by context managers (`with`) that must be
  cleanly released.

In these scenarios, a simple interrupt handler is insufficient because automated
kills (`SIGTERM`) will bypass it, leaving orphaned processes, locked resources,
or uncommitted transactions.

#### The Advanced Snippet (Synchronous)

```python
import signal
import sys

def main():
    # Your main logic here
    ...

def sigterm_handler(signum, frame):
    # Translate SIGTERM into KeyboardInterrupt to trigger clean teardown
    raise KeyboardInterrupt

if __name__ == "__main__":
    # Converge SIGTERM and SIGINT into the same cleanup path
    signal.signal(signal.SIGTERM, sigterm_handler)

    try:
        main()
    except KeyboardInterrupt:
        # Protect teardown logic from re-entrant signals (user mashing Ctrl+C)
        signal.signal(signal.SIGINT, signal.SIG_IGN)
        signal.signal(signal.SIGTERM, signal.SIG_IGN)

        try:
            sys.stderr.write("\n")
            sys.stderr.flush()
        except Exception:
            pass
        sys.exit(130)
    except BrokenPipeError:
        # Python flushes standard streams on exit; redirect remaining output
        # to devnull to avoid another BrokenPipeError at shutdown
        import os
        devnull = os.open(os.devnull, os.O_WRONLY)
        os.dup2(devnull, sys.stdout.fileno())
        # 141 is the standard POSIX exit code for a script terminated by SIGPIPE
        sys.exit(141)
```

#### The Advanced Snippet (Asynchronous / Asyncio)

For async tools, use the event loop's signal handlers and task cancellation. We
track `_signal_received` to ensure that internal application cancellations do
not mistakenly report exit code `130` (user interrupt). Adopting
`asyncio.run(main())` guarantees that all asynchronous generators, default
executors, and pending background tasks are cleanly drained and shut down on
exit.

```python
import asyncio
import signal
import sys

# Global flag to track if cancellation was triggered by a signal
_signal_received = False

async def main():
    loop = asyncio.get_running_loop()
    main_task = asyncio.current_task()

    # Define the shutdown handler inside main to capture main_task via closure
    def shutdown_handler():
        global _signal_received
        _signal_received = True
        main_task.cancel()

    # Register handlers on the loop
    for sig in (signal.SIGINT, signal.SIGTERM):
        try:
            loop.add_signal_handler(sig, shutdown_handler)
        except NotImplementedError:
            # Safe guard for platforms (like Windows) that do not support loop signal handlers.
            # On these platforms, SIGINT will fall back to raising KeyboardInterrupt.
            pass

    try:
        # --- YOUR ACTUAL APPLICATION LOGIC HERE ---
        await asyncio.sleep(10)  # Example work
        # ------------------------------------------
    finally:
        # Unregister loop handlers to restore default signal behavior on exit
        for sig in (signal.SIGINT, signal.SIGTERM):
            try:
                loop.remove_signal_handler(sig)
            except Exception:
                pass

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except asyncio.CancelledError:
        if _signal_received:
            try:
                sys.stderr.write("\n")
                sys.stderr.flush()
            except Exception:
                pass
            sys.exit(130)
        else:
            # Task was cancelled by internal application logic, not a signal
            sys.exit(1)
    except KeyboardInterrupt:
        # Fallback catch for platforms without loop signal handlers (e.g. Windows)
        # or if a SIGINT lands outside the active event loop.
        try:
            sys.stderr.write("\n")
            sys.stderr.flush()
        except Exception:
            pass
        sys.exit(130)
    except BrokenPipeError:
        # Python flushes standard streams on exit; redirect remaining output
        # to devnull to avoid another BrokenPipeError at shutdown
        import os
        devnull = os.open(os.devnull, os.O_WRONLY)
        os.dup2(devnull, sys.stdout.fileno())
        # 141 is the standard POSIX exit code for a script terminated by SIGPIPE
        sys.exit(141)
```

#### Advanced Caveats & Requirements

1. **Process Hygiene (Subprocesses):** You must explicitly terminate and
   **reap** child processes in a `finally` or `atexit` block. Wrap `proc.kill()`
   to prevent crashes if the process exits in the microscopic window before the
   signal is sent.
   ```python
   try:
       proc.terminate()
       proc.wait(timeout=5.0)  # Wait for graceful exit
   except subprocess.TimeoutExpired:
       try:
           proc.kill()         # Force kill if hung
       except ProcessLookupError:
           pass                # Prevent crash if process exited just in time
       proc.wait()             # Reap the zombie
   ```
1. **Thread Cleanup:** Background threads spawned with `daemon=True` are killed
   abruptly at exit and **do not run cleanup**. If your threads require clean
   teardown, do not use `daemon=True`; instead, use an explicit stop `Event` and
   `join()` them during main thread cleanup.

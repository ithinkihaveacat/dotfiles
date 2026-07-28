# Caching and Offline Mode

This document defines the conventions for caching network responses and
supporting offline mode. For interface rules (flags, help text) see
`cli-tools.md`; for Bash idioms see `shell.md`.

## Core Principles

1. **Include Provenance:** Report the age of cached data.
1. **Expose Gaps:** Never silently ignore missing data.
1. **Provide Actionable Errors:** On cache miss, show the command needed to
   fetch the data.

## Scope and Obligations

Different scripts have different obligations:

1. **Every network call:** Must report failure clearly. Never silently treat a
   failed request as an empty result. A connection failure is different from a
   `404 Not Found`.
1. **Agent/CI driven scripts:** Must honor the offline switch (`<TOOL>_OFFLINE`
   or `AGENT_OFFLINE`).
1. **Caching scripts:** Must follow the caching rules in this document (layout,
   write-through, provenance).

Do not add caching to a script that has no reusable data (e.g., live API
queries, unique LLM prompts).

## The Offline Switch

Control offline behavior via environment variables:

```text
<TOOL>_OFFLINE   Per-tool override; takes precedence.
AGENT_OFFLINE    Workspace-wide policy.
```

Treat `1`, `true`, `yes`, and `on` (case-insensitive) as true. Anything else is
false. Do not use an `--offline` flag as the *only* way to trigger offline mode.

### What Offline Mode Means

**Offline mode disables network requests; it does not simulate a missing
network.**

If a cache exists (even from a previous network request), offline mode will
absolutely use it. It is designed to allow scripts to run safely without network
egress, not to test how a script behaves on a fresh machine with no state.

When offline mode is active:

- **Make no network calls.** Do not attempt a request and fall back on timeout.
- **Serve stale data.** Ignore TTLs. Return cached data regardless of age.
- **Timestamp the answer.** Output the cache age to stderr (e.g.,
  `(cached 3 days ago)`) before returning data.
- **Exit non-zero on a miss.** Fail clearly if data is missing. Provide the
  exact command to warm the cache.
- **Gate third-party paths.** Ensure plugins and underlying libraries do not
  attempt network calls.

*(Note: `AGENT_OFFLINE` only affects the script itself. If your script is
launched by a tool that fetches dependencies before execution—like
`uv run --script`—you must also set the launcher's offline flag, e.g.,
`UV_OFFLINE=1`.)*

### Incomplete Answers

If an operation requires multiple requests, you may silently skip optional
requests when online. **Offline, you must not.** If optional data is missing
offline:

- **Critical gap:** Fail the command.
- **Genuinely optional:** Warn the user on stderr about what is missing and how
  to cache it, but return the partial result.

Never silently return partial data offline.

## Online Behavior

When running online (the default):

- **Write-through on success:** Populate the cache automatically. Do not require
  a separate "warm up" command.
- **Do not fallback on failure:** If a network call fails, do not serve stale
  data silently. Fail and instruct the user to run with `AGENT_OFFLINE=1` if
  they want to use the cache.
- **Ignore cache write failures:** If the cache directory is unwritable (e.g.,
  in a read-only sandbox), silently skip writing and continue.
- **Validate transfers:** A `2xx` HTTP status is not enough. If a transfer is
  truncated or reset, reject it and do not cache it (e.g., check `curl`'s exit
  code, not just `%{http_code}`).

## Cache Layout

Store cached resources in a tool-specific directory:

```bash
${<TOOL>_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/<tool>}
```

- **Tool-specific roots:** Use `<TOOL>_CACHE_DIR`, not the base directory.
- **Subdivide by category:** Use subdirectories (e.g., `<cache>/http/`).
- **Mirror paths, do not hash:** For URLs, mirror the path directly (e.g.,
  `<cache>/http/dl.google.com/.../file.xml`). Hashes are opaque. Reject paths
  that escape the cache root.
- **No sensitive data:** The cache must be safe to share. Never cache
  credentials.

## Warming the Cache

The standard way to warm a cache is **write-through**: running a command online
caches data for future offline runs.

Avoid dedicated `warm` subcommands unless a caller knows the required inputs in
advance but cannot know the exact commands that will be run.

## Help Text

Document both environment variables under `Environment:`, including the default
cache location:

```text
Environment:
  JETPACK_OFFLINE     Answer only from the local cache; never use the network.
                      Falls back to AGENT_OFFLINE when unset.
  AGENT_OFFLINE       Workspace-wide offline policy (see JETPACK_OFFLINE).
  JETPACK_CACHE_DIR   Cache directory
                      (default: ${XDG_CACHE_HOME:-$HOME/.cache}/jetpack)
```

Tools that do not cache anything should omit `JETPACK_CACHE_DIR`. Consider
adding a `doctor` command to report the cache location, age, and offline status.

## Why This Matters

- **CI:** Shared egress gets rate-limited, and third-party endpoints fail
  independently of your changes. Caching makes CI deterministic and resilient.
- **Sandboxed Agents:** Agent sandboxes often deny network access outright.
  `AGENT_OFFLINE=1` ensures tools skip calls they cannot make, avoiding timeouts
  and misleading "not found" errors.

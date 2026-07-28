# Caching and Offline Mode

This document defines the conventions for caching network responses and
supporting offline mode in scripts. For interface rules (flags, help text,
errors) see `cli-tools.md`; for bash idioms see `shell.md`.

## The Goal

**A caller with no network gets an answer it can trust, or a clear reason it has
none.**

Three core principles apply:

1. **Include Provenance:** The caller must know how old the cached data is.
1. **Expose Gaps:** Never silently ignore missing data. Gaps must be explicitly
   reported.
1. **Provide Actionable Errors:** If a cache miss occurs offline, the error must
   show the command required to fix it (which must be run in an online
   environment).

## Where the Cache Lives

Store cached resources in a tool-specific directory:

```bash
${<TOOL>_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/<tool>}
```

- **Tool-specific roots:** `<TOOL>_CACHE_DIR` names the tool's own directory
  (e.g., `JETPACK_CACHE_DIR=/tmp/jp`), not the base directory.
- **Subdivide by category:** Use subdirectories (e.g., `<cache>/http/`,
  `<cache>/catalog/`). Do not split a tool's cache across multiple roots.
- **Disposable:** Deleting the cache must only cost time, never correctness.
- **No sensitive data:** The cache must be safe to share across CI jobs and
  sandboxed agents. Never cache credentials or user-specific data.

## Cache Layout

For URLs with path-like structures, mirror the URL directly under the cache root
rather than hashing it:

```text
<cache>/http/dl.google.com/android/maven2/.../maven-metadata.xml
```

A mirrored path is human-readable, easy to diff between CI runs, and simple to
prune. Hashes are opaque. Reject components that would escape the cache root
(e.g., `..`, empty segments), and do not cache URLs that cannot be safely
mapped.

## The Offline Switch

Control offline behavior via environment variables:

- **`<TOOL>_OFFLINE`**: Per-tool override; takes precedence (e.g., set to 0 to
  opt out).
- **`AGENT_OFFLINE`**: Workspace-wide policy; used when `<TOOL>_OFFLINE` is
  unset.

Treat `1`, `true`, `yes`, and `on` (case-insensitive) as true. Anything else is
false.

Do not use an `--offline` flag as the *only* way to trigger offline mode.
Callers running multiple commands (e.g., CI jobs, agent sessions) need a way to
disable network access globally without appending flags to every command.

### Offline Behavior

Offline mode does not simulate a clean, no-network environment. Instead, **it
explicitly dictates that a cached copy obtained from the network will absolutely
be used if present (by design).**

- **Make no network calls:** Never attempt network requests in offline mode. Do
  not "try, then fall back"—network timeouts slow down execution and produce
  confusing error messages in sandboxes.
- **Serve stale rather than fail:** Ignore Time-To-Live (TTL) freshness
  preferences when offline. Return the cached data regardless of its age.
- **Timestamp every answer on stderr:** Output the cache age to stderr (e.g.,
  `(cached 3 days ago)`) so stdout remains parseable. Ensure you check for
  offline mode *before* returning early based on TTL.
- **Exit non-zero on a miss:** If data is missing, fail clearly. State the
  missing resource and provide the exact command needed to warm the cache.
- **Gate unproven paths:** Assume all third-party handlers or plugins might
  attempt network calls. Route them through the offline check.

Example cache miss error:

```text
jetpack version: offline (AGENT_OFFLINE=1) and no cached copy of
  https://dl.google.com/android/maven2/.../maven-metadata.xml
jetpack version: run this where there is network to populate the cache:
  jetpack version androidx.wear.tiles:tiles ALPHA
```

### Handling Incomplete Answers

Some operations require multiple network requests. Online, a tool might silently
ignore a failed network request if it's considered optional, returning a partial
result. **Offline, this is unacceptable.**

For every network request that the tool treats as optional when running online
(i.e., where a network failure is quietly ignored), ask: *If this data is
missing offline, is the result still complete and accurate?*

- **No (Critical gap):** Fail the command. For example, if you cannot fetch
  metadata to determine if platform sources exist, you cannot return a valid
  package.
- **Yes (Genuinely optional):** Warn the user on stderr, but do not fail the
  command. State what is missing and how to cache it.

**Never silently ignore missing resources.** A partial result that looks
complete is actively misleading. A gap in the data must be clearly identifiable
to the user.

### Online Behavior

- **Write-through on every success:** Populate the cache automatically during
  normal online use. Do not require a separate "warm up" command.
- **Maintain normal behavior:** Adding a cache must not change the behavior of
  online runs. Only use read-side TTLs for expensive, slow-moving operations
  (e.g., full index downloads).
- **Do not fallback to cache on network failure:** If a network call fails
  online, do not serve stale data behind the caller's back. Instead, inform the
  user that a cached copy exists and instruct them to re-run with
  `AGENT_OFFLINE=1`.
- **Never let cache writes fail the run:** In read-only sandboxes, the cache
  directory may be unwritable. Silently skip the cache write and continue
  execution.

## Warming the Cache

The standard way to warm a cache is **write-through**: running a command online
automatically caches the required data for subsequent offline runs.

Do not create a dedicated `warm` or `prefetch` subcommand unless strictly
necessary. Such commands must guess what data future runs will need, which leads
to incomplete caches and duplicated fetching logic. Only use a `warm` command
when a caller knows the required inputs in advance (e.g., from a dependency
manifest) but cannot know the exact commands that will be run.

## Help Text

Document both environment variables under an `Environment:` section in the
tool's help output, including the default cache location:

```text
Environment:
  JETPACK_OFFLINE     Answer only from the local cache; never use the network.
                      Falls back to AGENT_OFFLINE when unset.
  AGENT_OFFLINE       Workspace-wide offline policy (see JETPACK_OFFLINE).
  JETPACK_CACHE_DIR   Cache directory
                      (default: ${XDG_CACHE_HOME:-$HOME/.cache}/jetpack)
```

Consider adding a `doctor` command to report the cache location, its age, and
whether offline mode is currently active.

## Where This Pays Off

**CI Environments**: CI jobs usually have network access, but problems arise
from shared egress getting rate-limited, third-party endpoints failing
independently, and the need for two runs of one commit to behave identically. A
mid-job network call is a flake and a reproducibility hole even when it
succeeds.

Using `AGENT_OFFLINE=1` on the job (after a dedicated cache priming step)
ensures that steps like `make build` are pinned to data fetched once and open to
inspection.

**Sandboxed Agents**: Agent sandboxes increasingly deny network access outright
as a safety feature (e.g., Codex's `read-only` sandbox).

- **Set `AGENT_OFFLINE=1` in the sandbox environment**, so tools skip calls they
  cannot make instead of spending the session's time on connect timeouts.
- **Behave sanely when it is not set**, because often it will not be: the
  network is simply gone and the tool finds out by failing. Distinguish "the
  server said no" from "no server was reached", say which happened, and point at
  offline mode when a cached copy exists.
- A read-only sandbox may also make the cache unwritable — this is handled
  gracefully by silently skipping cache writes.

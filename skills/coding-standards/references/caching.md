# Caching and Offline Mode

This is the cross-cutting convention for any script in this repository that
fetches something over the network and can usefully reuse the response. It
covers two questions every such script would otherwise answer ad hoc:

1. Where does the cache live, and how does a caller move it?
1. How does a caller force the script to run **offline**, against that cache?

Interface rules (flag and command naming, help text, errors) come from
`cli-tools.md`; the bash idioms come from `shell.md`. This file adds only what
is specific to caching and offline operation.

## Where the Cache Lives

```text
${<TOOL>_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/<tool>}
```

- `<TOOL>_CACHE_DIR` names **the tool's own cache directory**, not the base
  directory it sits in. `JETPACK_CACHE_DIR=/tmp/jp` puts the cache in `/tmp/jp`,
  not `/tmp/jp/jetpack`. (`XDG_CACHE_HOME`, by contrast, is the base — that is
  what the XDG spec says it is.)
- One cache root per tool. Subdivide *inside* it (`<cache>/http/`,
  `<cache>/catalog/`) rather than adding a second top-level location. A tool
  whose cache is spread over two roots cannot be warmed, inspected, pruned, or
  restored by a CI cache step as one unit.
- The directory is disposable by definition: deleting it must only cost time,
  never correctness. Nothing that is not re-derivable belongs in it.
- Never cache credentialed or user-specific responses in it. The cache is
  assumed to be safe to share between CI jobs and to hand to a sandboxed agent.

## Forcing Offline Operation

```text
<TOOL>_OFFLINE    per-tool switch (checked first; wins when set, including
                  when set to 0 to opt one tool out)
AGENT_OFFLINE     workspace-wide policy (used when <TOOL>_OFFLINE is unset)
```

Truthy values are `1`, `true`, `yes`, `on` (case-insensitive); anything else,
including empty, is false.

This mirrors the two-tier naming rule already documented in `workspace-config`:
`AGENT_*` variables are **policy** a human (or a CI job, or a sandbox harness)
sets once for an environment, while `<TOOL>_*` variables are **plumbing** for a
single tool. It also matches the `<TOOL>_OFFLINE` precedent set by `uv`
(`UV_OFFLINE`), which this repo's test suites already rely on, so an environment
that sets `UV_OFFLINE=1` and `AGENT_OFFLINE=1` reads consistently.

Do not add an `--offline` flag as the primary interface. The point of the
convention is that a caller who cannot enumerate every command that a build,
test run, or agent session will invoke can still turn off the network for all of
them at once. A flag is fine as an addition, never as the only switch.

### What Offline Mode Must Do

- **Make no network calls at all.** Not "try and fall back" — in a sandbox every
  attempt costs a DNS or connect timeout, and the resulting error usually looks
  like a missing resource rather than a missing network.
- **Serve stale data rather than erroring.** Offline is a promise that the tool
  will answer from what it has; a TTL that is meaningful online is not a reason
  to fail offline.
- **State the age of what it served, on stderr, every time.**
  `(cached 3 days ago)` is the difference between an agent reporting a version
  confidently and an agent reporting it with the caveat that makes it useful.
  Age goes to stderr so stdout stays parseable. *Every time* includes the paths
  a freshness TTL would have short-circuited: check offline mode **before** any
  "cache is younger than the TTL, return early" branch, or the common
  warm-then-freeze workflow — where the cache is usually fresh — is exactly the
  case that answers silently.
- **Fail loudly and actionably on a cache miss.** Name the resource that is
  missing and the command that would have warmed it, and exit non-zero. Never
  fall back to a guess — for an agent, an unsourced answer from training data is
  indistinguishable from a real one.
- **Gate on "could this need the network", not on the obvious remote case.** A
  handler that is cached is cached because it was expensive, which usually means
  remote; a plugin-provided or third-party one may do anything at all. If the
  tool cannot prove a code path is local, route it through the offline check
  rather than letting it fall through and dial out.

```text
jetpack version: offline (AGENT_OFFLINE=1) and no cached copy of
  https://dl.google.com/android/maven2/androidx/wear/tiles/tiles/maven-metadata.xml
jetpack version: warm the cache from a network-enabled environment first:
  jetpack warm cache androidx.wear.tiles:tiles
```

#### Optional Resources

Some fetches are best-effort online: their absence is normal and the command
still produces a correct result. Two rules keep them from becoming a hole in the
guarantee above:

- A resource whose absence *changes the answer* is not optional, whatever the
  online path does with it. `jetpack source` fetches a POM only to detect Kotlin
  Multiplatform targets, and tolerates a missing one online — but offline, a
  missing POM means the answer silently omits every platform target's sources,
  so it is fatal there.
- Where the miss really is tolerable — the resource may legitimately not exist,
  so a warmed cache can be correctly missing it and a hard error would be
  unfixable — warn on stderr naming what is absent and how to warm it, and carry
  on. What is never acceptable is passing over it in silence: the caller cannot
  see the gap in a result that looks complete.

### What the Online Path Must Do

- **Write through on every successful fetch.** Normal online use is what makes a
  later offline run possible; a cache that only fills when explicitly warmed
  will be empty exactly when it is needed.
- **Do not start serving stale answers online.** Adding a cache must not change
  what an online run returns. Reserve read-side TTLs for resources that are
  expensive and slow-moving (a whole-index download), document the TTL in the
  help text, and leave everything else fetching fresh.
- **On a network failure, name the cache instead of using it.** A run that was
  not told to go offline should not quietly answer from a week-old copy. Report
  the failure, and if a cached copy exists, say so and name the switch:
  `a cached copy from 3 days ago exists; re-run with AGENT_OFFLINE=1 to use it`.
  That keeps "report a failure, don't guess" intact while still giving an agent
  a next step it can take without human help.
- **Never let cache maintenance fail the run.** In a read-only sandbox the cache
  directory may not be writable. Failing to store a response is not an error;
  skip it and continue.

## Cache Layout

When the cached resources are URLs with path-shaped identity, mirror the URL
under the cache root instead of hashing it:

```text
<cache>/http/dl.google.com/android/maven2/androidx/wear/tiles/tiles/maven-metadata.xml
```

A hash is opaque: it cannot be listed for review, seeded by a test fixture,
pruned selectively, or diffed between CI runs. A mirrored path can. Reject or
sanitize path components that would escape the cache root (`..`, empty segments)
and fall back to not caching if the URL cannot be mapped safely.

## Warming the Cache

Every tool with an offline mode needs an answer to "how does a cold environment
with no network get a warm cache?" — a fresh CI runner and a from-scratch
sandboxed agent both start with nothing.

- Provide a **`warm cache` subcommand** (verb-noun, per `cli-tools.md`) that
  populates the cache for named targets in one network-enabled step, so warming
  is declarative rather than "remember to run the six commands the job will
  later need".
- Because the online path writes through, `warm cache` is a convenience, not the
  only route: running the real commands once with network is equivalent.
- Cold **and** offline **and** unwarmed is an unsupported state, and must fail
  with the actionable error above rather than being papered over.

## Documenting It

The tool's help text lists both variables under `Environment`, with the cache
default spelled out:

```text
Environment:
  JETPACK_OFFLINE     Answer only from the local cache; never use the network.
                      Falls back to AGENT_OFFLINE when unset.
  AGENT_OFFLINE       Workspace-wide offline policy (see JETPACK_OFFLINE).
  JETPACK_CACHE_DIR   Cache directory
                      (default: ${XDG_CACHE_HOME:-$HOME/.cache}/jetpack)
```

If the tool has a `doctor` command, it reports the cache location, the age of
what is in it, and whether offline mode is active — that is the pre-flight check
a CI job or an agent runs before trusting an offline answer.

## Two Environments This Is For

### CI

CI usually *has* network, which is why the constraint is easy to miss. The
constraints are different ones: shared egress that is rate-limited or
occasionally blocked, third-party endpoints that go down independently of your
change, and a hard requirement that two runs of the same commit behave the same.
A network call in the middle of a job is a flake source and a reproducibility
hole even when it succeeds.

The shape that solves all three:

```yaml
- name: Restore tool cache
  uses: actions/cache@v4
  with:
    path: ~/.cache/jetpack
    key: jetpack-${{ hashFiles('deps.txt') }}

- name: Warm cache            # the only step allowed to touch the network
  run: jetpack warm cache $(cat deps.txt)

- name: Build                 # deterministic; a network blip cannot reach it
  run: make build
  env:
    AGENT_OFFLINE: 1
```

One step owns the network, the cache restore makes it a no-op on most runs, and
everything after it is pinned to data that was fetched once and can be
inspected. `AGENT_OFFLINE` is set on the job rather than per-command precisely
because the job does not know which tools `make build` will reach for.

### Sandboxed Agents

Agent sandboxes increasingly deny network access outright — Codex's `read-only`
sandbox and `workspace-write` without
`sandbox_workspace_write.network_access=true` both do — and the denial is a
safety feature, not a misconfiguration to work around. Two consequences:

- **Set `AGENT_OFFLINE=1` in the sandbox environment.** Then the tools skip
  calls they cannot make, instead of spending the sandbox's time on connect
  timeouts and reporting failures that read like "this library does not exist".
- **Behave sanely when it is *not* set**, because often it will not be. The
  network is simply gone and the tool finds out by failing. Distinguish "the
  server said no" from "no server was reached" (an HTTP status vs. no response
  at all), report which one happened, and point at offline mode when a cached
  copy exists. Never present a remembered answer as a fetched one.
- A read-only sandbox may also make the cache unwritable — see "Never let cache
  maintenance fail the run" above.

The same reasoning applies to the repo's own test suites, which run under
`UV_OFFLINE=1` with a pre-warmed `uv` cache for exactly these reasons; see
`skills/workspace-config/tests/common.sh` for the "warm with real network, then
freeze" pattern, and `tests/README.md` for how to run the suite offline.

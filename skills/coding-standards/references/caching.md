# Caching and Offline Mode

The convention for any script here that fetches over the network and can reuse
the response: where its cache lives, and how a caller forces it to run offline
against that cache. Interface rules (flags, help text, errors) come from
`cli-tools.md`; the bash idioms from `shell.md`.

## The Goal

**A caller with no network gets an answer it can trust, or a clear reason it has
none.**

Three principles follow, and every rule below is one of them applied:

1. **Trust needs provenance.** Stale data is useful; undated stale data is not,
   because the caller cannot tell March's answer from today's.
1. **A gap must look like a gap.** Inventing an answer and quietly returning
   less than was asked for are the same failure — both read as success.
1. **The fix travels with the failure.** Whoever hits a cold cache is by
   definition in the environment that cannot fix it, so the error has to name
   the command that can.

## Where the Cache Lives

```text
${<TOOL>_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/<tool>}
```

- `<TOOL>_CACHE_DIR` names the tool's own directory, not the base it sits in:
  `JETPACK_CACHE_DIR=/tmp/jp` caches in `/tmp/jp`. (`XDG_CACHE_HOME` is the base
  — that is what the XDG spec makes it.)
- One root per tool, subdivided inside (`<cache>/http/`, `<cache>/catalog/`). A
  cache split across two roots cannot be warmed, inspected, pruned, or restored
  by a CI cache step as one unit.
- Disposable: deleting it costs time, never correctness.
- Nothing credentialed or user-specific. The cache is assumed safe to share
  between CI jobs and to hand to a sandboxed agent.

## The Offline Switch

```text
<TOOL>_OFFLINE   per-tool; wins whenever set, including =0 to opt one tool out
AGENT_OFFLINE    workspace-wide policy; used when <TOOL>_OFFLINE is unset
```

Truthy values are `1`, `true`, `yes`, `on` (case-insensitive); anything else,
empty included, is false.

Two tiers because `workspace-config` already fixes that split: `AGENT_*` is
policy an environment sets once, `<TOOL>_*` is plumbing for one tool. `uv`'s
`UV_OFFLINE` sets the same precedent, and this repo's suites already run under
it.

An `--offline` flag may be added, but never as the only switch: a caller who
cannot enumerate every command a build, test run, or agent session will invoke
still has to turn the network off for all of them at once.

### Offline

- **Make no network calls.** Not "try, then fall back" — in a sandbox each
  attempt buys a connect timeout and an error that reads like a missing resource
  rather than a missing network.
- **Serve stale rather than fail.** A TTL is a freshness preference online, not
  a reason to refuse offline.
- **Date every answer, on stderr** (`(cached 3 days ago)`), so stdout stays
  parseable. Check offline mode *before* any "younger than the TTL, return
  early" branch: under warm-then-freeze the cache is nearly always fresh, so
  testing it second skips the signal in exactly the common case.
- **On a miss, name the resource and the fix, and exit non-zero.** The fix is
  normally this same command run where there is network — see *Warming*.
- **Gate every path you cannot prove is local.** A path is cached because it was
  expensive, which usually means remote, and a plugin or third-party handler may
  do anything at all. Route it through the check rather than let it dial out.

```text
jetpack version: offline (AGENT_OFFLINE=1) and no cached copy of
  https://dl.google.com/android/maven2/androidx/wear/tiles/tiles/maven-metadata.xml
jetpack version: run this where there is network to populate the cache:
  jetpack version androidx.wear.tiles:tiles ALPHA
```

#### Incomplete Answers

Answering one question often takes several fetches, and online a tool may let
some of them fail without complaint: it carries on and the result is still
right. Offline, that same shrug turns a cache miss into a wrong answer wearing a
right answer's clothes.

So for each fetch the online path lets slide, ask: **if this one is missing, is
the result still complete?**

- **No — then it is not optional offline, whatever the online path does.**
  `jetpack source` fetches a POM only to learn whether a library has Kotlin
  Multiplatform targets. Online, missing it costs nothing. Offline it means
  nobody can tell whether platform sources belonged in the output, so the
  extracted source omits them and says nothing. Fatal.
- **Yes, and it may genuinely not exist — then warn, don't fail.** Some KMP
  targets never publish a sources JAR, so a correctly warmed cache can be
  missing one and a hard error would be unfixable. Name what is absent and how
  to cache it, then carry on.

What is never allowed is dropping it in silence: a result that looks complete
and isn't breaks *a gap must look like a gap* as surely as an invented answer
does.

### Online

- **Write through on every success.** Ordinary online use is what makes a later
  offline run possible; a cache that fills only when explicitly warmed is empty
  exactly when it is needed.
- **Don't start answering stale.** Adding a cache must not change what an online
  run returns. Reserve read-side TTLs for the expensive and slow-moving (a
  whole-index download) and document them in the help text.
- **On a network failure, name the cache instead of using it:**
  `a copy cached 3 days ago is on disk; re-run with AGENT_OFFLINE=1 to use it`.
  A run that was not told to go offline should not answer from a week-old file
  behind the caller's back — but it can still hand over the next step.
- **Never let cache maintenance fail the run.** A read-only sandbox may make the
  directory unwritable; skip the write and carry on.

## Cache Layout

Where cached resources are URLs with path-shaped identity, mirror the URL under
the cache root instead of hashing it:

```text
<cache>/http/dl.google.com/android/maven2/androidx/wear/tiles/tiles/maven-metadata.xml
```

A hash cannot be listed for review, seeded by a test fixture, pruned
selectively, or diffed between CI runs; a mirrored path can. Reject components
that would escape the cache root (`..`, empty segments), and simply don't cache
a URL that cannot be mapped safely.

## Warming

Every offline mode needs an answer to "how does a cold environment with no
network get a warm cache?" — a fresh CI runner and a from-scratch agent both
start with nothing.

Write-through is that answer. **Running the command once with network is the
warm-up**, which is why the miss above quotes the failing invocation back: the
command that fixes a miss is the one that hit it.

Resist adding a `warm`/`prefetch` subcommand on top of that. It cannot be more
reliable than re-running the real command, only less: it has to *guess* what a
later run will ask for — which version, with sources or without — and every
guess it gets wrong is a miss the caller still hits offline. It also duplicates
the fetching logic it is warming. Reach for one only when a caller genuinely
cannot know the commands in advance but does know the inputs (a dependency
manifest), and then say plainly in its help that it approximates.

Cold **and** offline **and** unwarmed stays unsupported, and fails with the
error above rather than being papered over.

## Help Text

Both variables belong under `Environment`, with the cache default spelled out:

```text
Environment:
  JETPACK_OFFLINE     Answer only from the local cache; never use the network.
                      Falls back to AGENT_OFFLINE when unset.
  AGENT_OFFLINE       Workspace-wide offline policy (see JETPACK_OFFLINE).
  JETPACK_CACHE_DIR   Cache directory
                      (default: ${XDG_CACHE_HOME:-$HOME/.cache}/jetpack)
```

A `doctor` command reports the cache location, the age of what is in it, and
whether offline mode is active — the pre-flight check a CI job or an agent runs
before trusting an offline answer.

## Where This Pays Off

### CI

CI usually *has* network, which is why the constraint is easy to miss. The
problems are elsewhere: shared egress that gets rate-limited or blocked,
third-party endpoints that fail independently of your change, and two runs of
one commit that have to behave the same. A mid-job network call is a flake and a
reproducibility hole even when it succeeds.

```yaml
- name: Restore tool cache
  uses: actions/cache@v4
  with:
    path: ~/.cache/jetpack
    key: jetpack-${{ hashFiles('deps.txt') }}

- name: Prime the cache       # the only step allowed to touch the network
  run: for a in $(cat deps.txt); do jetpack list dependencies "$a"; done

- name: Build                 # deterministic; a network blip cannot reach it
  run: make build
  env:
    AGENT_OFFLINE: 1
```

One step owns the network, the cache restore makes it a no-op on most runs, and
everything after is pinned to data fetched once and open to inspection.
`AGENT_OFFLINE` goes on the job rather than each command precisely because the
job cannot know what `make build` will reach for.

### Sandboxed Agents

Agent sandboxes increasingly deny network access outright — Codex's `read-only`
sandbox, and `workspace-write` without
`sandbox_workspace_write.network_access=true`, both do — and that denial is a
safety feature, not a misconfiguration to route around.

- **Set `AGENT_OFFLINE=1` in the sandbox environment**, so tools skip calls they
  cannot make instead of spending the session's time on connect timeouts and
  reporting failures that read like "this library does not exist".
- **Behave sanely when it is not set**, because often it will not be: the
  network is simply gone and the tool finds out by failing. Distinguish "the
  server said no" from "no server was reached" (an HTTP status versus no
  response at all), say which happened, and point at offline mode when a cached
  copy exists. Never present a remembered answer as a fetched one.
- A read-only sandbox may also make the cache unwritable — see **never let cache
  maintenance fail the run** above.

The repo's own suites run this way, under `UV_OFFLINE=1` against a pre-warmed
`uv` cache. See `skills/workspace-config/tests/common.sh` for the "warm with
real network, then freeze" pattern, and `tests/README.md` for running the suite
offline.

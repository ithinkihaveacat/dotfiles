---
name: pinboard
description: >-
  Searches and edits a Pinboard (pinboard.in) bookmark account through a local
  Git mirror: full-text search over titles, notes, tags and URLs, tag counts,
  adding and updating bookmarks through the API, version history and restoring
  deleted bookmarks. Use when finding, saving, tagging or recovering bookmarks,
  or when syncing or checking the Pinboard mirror.
compatibility: Requires Python 3.11+ (via uv), git, and a Pinboard API token.
---

# pinboard

`pinboard` keeps a Git mirror of a Pinboard account, answers questions from it,
and changes bookmarks through the Pinboard v1 API. Pinboard stays authoritative:
the mirror is never written back, so it can lag behind Pinboard but cannot drop
anything Pinboard holds.

Run it as `pinboard` when `bin/` is on `PATH`, otherwise as
`<skill-dir>/scripts/pinboard`.

## Setup

- `PINBOARD_API_TOKEN`: the API token (`USER:HEX`) from
  <https://pinboard.in/settings/password>.
- The mirror is a Git clone at `~/.pinboard` (or `PINBOARD_REPO`, or
  `--repo DIR` before the command). Clone the mirror repository there; an empty
  clone is fine, and the first `pinboard sync` imports every bookmark and pushes
  `main`.
- `pinboard doctor` checks the token, the clone, the files and freshness without
  calling the API. It asks `origin` for its branch head, without fetching, to
  report commits this clone lacks.

## Reading

Reads never call the API, so they are as fresh as the last sync; each says when
that was (on stderr, or as `mirror.synced` with `--json`). They read the clone's
last commit, so a sync in progress never shows half done.

```bash
pinboard search kotlin coroutines          # every term must match
pinboard search --tag recipes lemon --json # notes truncated; paged by --cursor
pinboard get https://example.com/post      # one bookmark, notes in full
pinboard tags | head                       # tags, most used first
pinboard history https://example.com/post  # the mirror's versions of one URL
```

`search` matches each term case-insensitively against the title, notes, tags and
URL, newest first, 20 per page; `--limit N` and the printed `--cursor` continue.
It exits 1 when nothing matches and 2 on an error.

## Writing

Writes go to Pinboard first; each bookmark is then read back with `posts/get`
and committed to the mirror, so the next search sees it.

```bash
pinboard add https://example.com/post --title "A post" --tags "web reading"
pinboard update https://example.com/post --add-tag later --remove-tag reading
pinboard restore https://example.com/post   # re-add a deleted bookmark
pinboard suggest https://example.com/post   # live tag suggestions
```

- `add` makes the bookmark private unless `--public`, and never replaces an
  existing bookmark: if Pinboard has the URL, it reports the bookmark unchanged.
- `update` reads the bookmark live, changes only the given fields and keeps its
  date. `--tags` replaces every tag; `--add-tag` and `--remove-tag` change some.
- `restore` re-adds the last version the mirror recorded, with its original
  date; `--title` supplies a title when the recorded one is empty, which
  Pinboard refuses.
- `--dry-run` on `add`, `update`, `restore` and `sync` shows what would be sent
  or changed.

## Syncing

`pinboard sync` calls `posts/update` and, only if Pinboard changed since the
last sync, fetches every bookmark with one `posts/all` call (allowed once every
5 minutes). It commits only when a bookmark changed. Edits made in Pinboard's
own apps and bookmarklet reach the mirror only through a sync.

The deletion guard protects the mirror from a bad response: it refuses an empty,
malformed or failed `posts/all`, refuses to delete more than 10 bookmarks, and
confirms each deletion with `posts/get`, keeping any bookmark Pinboard still
has. A refused sync changes nothing; check Pinboard, then `--force` deletes
without confirming.

## Auditing

`pinboard audit` checks bookmarks for link rot and records the verdict as tags.
It is resumable: state lives under `~/.local/state/pinboard/audit/<pass>/`, not
in the mirror.

```bash
pinboard audit plan --year 2026        # freeze a work list from the mirror
pinboard audit check --jobs 8          # HTTP checks, appending to the journal
pinboard audit apply --limit 50        # write .status:*.checked:* through the API
pinboard audit status                  # progress and verdict counts
pinboard audit verify                  # the mirror agrees with the journal
```

- Verdicts: `.status:ok` (loads and matches), `.status:moved` (redirects to
  matching content), `.status:changed` (loads, but not the saved page),
  `.status:dead` (404/410/DNS/refused), `.status:blocked` (auth wall, rate
  limit, timeout, TLS). The cohort tag is `.checked:YYYY`, pinned when the pass
  is planned. Tags are private because `.`-prefixed tags are owner-only; see
  decision 004 in the dotfiles tracker.
- `plan` writes `manifest.json`, `plan.jsonl` and `journal.jsonl` once; `--tag`
  and `--year` narrow the pass. `--force` replaces an existing pass.
- Every `apply` write is journaled as `intent` before the API call and `done`
  after it, with fsync. Resume resolves the one ambiguous `intent` with a single
  `posts/get`; completed writes are never repeated. A half-written mirror update
  is discarded and rebuilt from the journal.
- A complete later pass can move the whole cohort in one call with
  `pinboard audit bump --old .checked:2026 --new .checked:2027`; it refuses
  unless every planned URL is applied. Partial passes should write the cohort
  tag per bookmark instead.
- `check` uses a title-similarity heuristic and parking-page markers, not the
  original page bytes; `changed` and `blocked` are deliberately conservative.
  Review the first small pass before running the full account.

## Rate Limits and Failures

- The client waits 3 s between calls, gates `posts/all` to once every 5 minutes,
  and backs off on HTTP 429 (doubling, at most 5 attempts). A 429 on `posts/all`
  or `posts/recent` is not retried: it reports when the gate next allows a call.
  A write that loses its response is re-read, never re-sent; if the bookmark
  then differs from the request, `add` reports it as already there.
- `AGENT_OFFLINE=1` refuses every API call; reads, `history` and `doctor` still
  work.
- Git writes never force-push. A write whose push is rejected is re-applied on
  the new remote head; a sync's commit is not (its `posts/all` is gated), so it
  stays unpushed and the next run pushes it. A commit that cannot be pushed is
  reported (exit 1). Fetches and pushes time out after 2 minutes.
- Writes refuse while the clone has uncommitted changes.

## MCP Server

`pinboard mcp` serves the same mirror to agents that cannot run the CLI, over
stdio or, with `--http`, Streamable HTTP at `/mcp`:

```bash
claude mcp add pinboard -- pinboard mcp      # a local agent, over stdio
pinboard mcp --http                          # loopback only, no authentication
```

- Tools: `search_bookmarks` (words, tags, dates, to-read, private, paged),
  `get_bookmark` and `list_tags` read the mirror and never call the API;
  `suggest_tags` is live; `add_bookmark`, `update_bookmark` and `sync` write.
  `get_bookmark` reports a URL the mirror lacks as `not_found`. There is no
  delete. Bookmarks are shown with `private` (the inverse of Pinboard's
  `shared`), and every read says when the mirror last synced.
- Writes behave as `add` and `update` do, and take the same lock on the clone,
  so the server and the CLI can share one mirror. `sync` runs one at a time and
  refuses inside the `posts/all` window with `retry_after` in seconds.
- Over HTTP the server also syncs whenever the last sync is older than
  `--sync-every` hours (24 by default), checking at startup and then hourly. A
  stdio server never syncs on its own.
- Hosted behind Cloudflare Access, `--access-team` and `--access-aud` make it
  check the `Cf-Access-Jwt-Assertion` token on every request but `GET /up`;
  without them it binds loopback only.
- Each call is logged to `~/.local/state/pinboard/mcp.jsonl` (or `--log`),
  rotated at 8 MiB: the tool, outcome and duration, the host of a written URL
  and a hash of search text, never titles, notes or the token.

## Reference

- [Command Index](references/command-index.md): every command's `--help`.

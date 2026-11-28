---
name: daybrief
description: >-
  Generates, inspects, and serves a context-aware morning briefing over CLI and
  MCP, backed by read-only personal context snapshots, a silent Producer's
  Packet for conversational follow-ups, operational cooldown memory, and a
  separate size-bounded weekly retrospective. Use when presenting or reviewing
  today's Daybrief morning briefing, answering follow-up questions about a
  briefing item, recording explicit briefing feedback or answers, running a
  retrospective, or operating the daybrief CLI and MCP server.
compatibility: Requires Python 3.11+ (via uv) and git.
---

# daybrief

`daybrief` produces a concise morning briefing (~150–250 words) from read-only
personal and external sources, pairs it with a silent ~10–15× **Producer's
Packet** for conversational follow-ups, and serves stored briefings over stdio
or Streamable HTTP (`daybrief mcp`).

Run it as `daybrief` when `bin/` is on `PATH`, otherwise as
`<skill-dir>/scripts/daybrief`.

## Presenter Rules (Consuming `daybrief` in an Agent UI)

When presenting a morning briefing or assisting in a Daybrief conversation:

1. **Deliver Turn 1 faithfully.** Call `get_today_brief` (or `daybrief show`)
   and render `deliver_verbatim_to_user` directly, without generic assistant
   cheerleading, extra bullet padding, or obligation framing. When `status` is
   `quiet`, deliver the short quiet-day note as-is (or stay brief).
1. **Keep backstage context silent until asked.** Never dump
   `backstage_context_for_followups_only` into the initial message. Hold its
   item dossiers, figures, URLs, rejected alternatives, assumptions, and
   `checked_and_omitted` notes in working memory so follow-ups ("how much was
   that?", "why Option A over B?", "anything good on Chalk today?") can be
   answered immediately in natural prose.
1. **Separate briefing from execution.** `daybrief` is strictly read-only over
   authoritative sources. When the user asks to act on an item ("let's start on
   the third one"), combine the Producer's Packet context with your separately
   authorised tools or MCP connectors (such as `taskgo` or `pinboard`), and
   obtain explicit user confirmation before any consequential external action or
   source write. Clarify genuinely ambiguous replies before acting.
1. **Treat silence as ambiguous.** Do not nag about ignored suggestions or treat
   past briefings as an unread backlog. Call `record_feedback` (or
   `daybrief feedback`) only when the user explicitly answers a question, states
   a preference, snoozes an item, or reports an outcome.

## Setup and Store Layout

State lives in `--dir DIR`, else `$DAYBRIEF_DIR`, else
`$XDG_STATE_HOME/daybrief` (`~/.local/state/daybrief`, mode `0700`):

- `constitution.md`: human-owned principles (`0444`). Runtime commands verify
  its SHA-256 before and after execution and never modify it.
- `editorial-guidance.md`: mutable selection and tone heuristics, capped at
  2,000 characters and updated only by `daybrief retro` (with full history in
  `guidance-history/`).
- `memory.db`: SQLite store holding generated briefings, Producer's Packets,
  item cooldowns and source-state hashes, explicit feedback, and retrospective
  audit records.
- `config.toml`: optional source paths and coordinates (environment variables
  override every setting).

Initialize a new store with:

```bash
daybrief init
daybrief doctor
```

## Collecting Context and Generating a Briefing

`daybrief collect` builds a sanitized, read-only Stage 1 snapshot across
configured sources without calling a model:

- **Taskgo (`DAYBRIEF_TASKGO_ROOT`):** active, ready, blocked, due-soon, and
  dormant projects/tasks plus recent commit activity.
- **Calendar (`DAYBRIEF_CALENDAR_ICS`):** local `.ics` files or private Secret
  `.ics` URLs. Upstream sanitization keeps descriptions only for events whose
  `ORGANIZER` matches `DAYBRIEF_OWNER_EMAILS` (or has no external organizer),
  drops unaccepted `PARTSTAT=NEEDS-ACTION` invites from unknown senders, and
  strips `DESCRIPTION` and URLs from third-party events.
- **Bookmarks (`DAYBRIEF_PINBOARD_REPO`):** reads `bookmarks/YYYY.jsonl` from
  the Pinboard Git mirror without `PINBOARD_API_TOKEN`.
- **Personal & household skills (`DAYBRIEF_PRIVATE_SKILLS`):** read-only
  excerpts and brand affinities from `personal-profile` and `home-manual`.
- **Price drops (`DAYBRIEF_CHALK_DB`):** queries `ptracker`'s `products.db` via
  SQLite `?mode=ro&immutable=1` (`PRAGMA query_only = ON`), pre-joining recent ≥
  15% markdowns against `personal-profile` brands.
- **Weather (`DAYBRIEF_WEATHER_LAT`, `DAYBRIEF_WEATHER_LON`):** 7-day Open-Meteo
  forecast cached under `$XDG_CACHE_HOME/daybrief` (honouring
  `AGENT_OFFLINE=1`).

`daybrief generate` runs Stage 1 collection followed by the multi-turn read-only
Stage 2 Morning Editor (`read_source_file`, `search_bookmarks`,
`query_price_drops`, and call-capped `web_scout`—zero shell or write tools),
validates constitutional integrity, and records the briefing and cooldowns:

```bash
daybrief collect --json
daybrief generate
daybrief generate --dry-run --json
daybrief show
daybrief show --backstage
```

## Feedback and Weekly Retrospectives

Record explicit user notes, question answers, outcomes, or item snoozes in
operational memory:

```bash
daybrief feedback "Prefer Heathrow over Gatwick for early flights" --kind preference
daybrief feedback "Snooze exterior paint until dry forecast" --item DB-20261128-2 --kind snooze
```

Run the separate retrospective over a bounded window (default 7 days) to propose
or apply an evidence-linked, ≤ 2,000-character revision to
`editorial-guidance.md`, or roll back the latest change:

```bash
daybrief retro --dry-run
daybrief retro
daybrief retro --rollback
```

## MCP Server

`daybrief mcp` serves the operational store over stdio, or with `--http` over
Streamable HTTP at `/mcp` (port `8794` by default):

```bash
claude mcp add daybrief -- daybrief mcp
daybrief mcp --http
```

- **Tools:** `get_today_brief` (`readOnlyHint: true`, returns both
  `deliver_verbatim_to_user` and `backstage_context_for_followups_only`),
  `get_brief` (`readOnlyHint: true`), `list_briefs` (`readOnlyHint: true`), and
  `record_feedback` (`readOnlyHint: false`, writes only to Daybrief's feedback
  and snooze tables).
- **Prompts & instructions:** Exposes the `morning-brief` MCP prompt and server
  `instructions` so scheduled cloud tasks (Gemini Scheduled Actions, ChatGPT
  Scheduled Tasks, Claude Routines) follow the presenter rules even without a
  local `SKILL.md` file.
- **Access & logging:** `--access-team` and `--access-aud` require a valid
  `Cf-Access-Jwt-Assertion` header on every HTTP path except unauthenticated
  `GET /up`. Without them `--http` binds loopback only. Request records (never
  briefing or feedback prose) are written to
  `$XDG_STATE_HOME/daybrief/mcp.jsonl` and read by `mcp logs`.

## Reference

- [Command Index](references/command-index.md): every command's `--help`.

# Command Index

<!-- markdownlint-disable MD013 -->

## Contents

- [Help](#help)
- [init](#init)
- [collect](#collect)
- [generate](#generate)
- [show](#show)
- [list](#list)
- [feedback](#feedback)
- [retro](#retro)
- [mcp](#mcp)
- [doctor](#doctor)

## Help

The blocks below are generated from each command's `--help` by
`command-index-format`.

<!-- generated: ../scripts/daybrief --help -->

```text
Usage: daybrief [-h] [--dir DIR] COMMAND ...

Generate, inspect, and serve context-aware morning briefings with read-only sources and a silent Producer's Packet.

positional arguments:
  COMMAND
    init      Initialize the Daybrief state directory
    collect   Build a read-only, sanitized context snapshot
    generate  Collect context, run the Morning Editor, and store a briefing
    show      Display the latest stored briefing, or a brief ID or date
    list      List stored briefings, newest first
    feedback  Record explicit owner feedback, answer, or snooze
    retro     Run weekly retrospective or roll back editorial guidance
    mcp       Serve stored briefings over MCP
    doctor    Check store, constitution, guidance cap, and sources

Options:
  -h, --help  Display this help message and exit
  --dir DIR   State directory (default: $DAYBRIEF_DIR, else
              ~/.local/state/daybrief)

Environment:
  DAYBRIEF_DIR               State directory (default: $XDG_STATE_HOME/daybrief)
  DAYBRIEF_CACHE_DIR         HTTP cache directory (default: $XDG_CACHE_HOME/daybrief)
  DAYBRIEF_MODEL             Model override (default: gemini-3.8-flash)
  DAYBRIEF_TASKGO_ROOT       Taskgo control repository path
  DAYBRIEF_PINBOARD_REPO     Pinboard Git mirror path
  DAYBRIEF_PRIVATE_SKILLS    Private skills directory path
  DAYBRIEF_CHALK_DB          Read-only Chalk SQLite database path
  DAYBRIEF_CALENDAR_ICS      Space- or comma-separated .ics paths or URLs
  DAYBRIEF_TRIPIT_ICS        Space- or comma-separated TripIt .ics paths/URLs
  DAYBRIEF_OWNER_EMAILS      Trusted calendar organizer emails (comma-separated)
  DAYBRIEF_TIMEZONE          IANA timezone (default: Europe/London)
  GEMINI_API_KEY             API key used by generate and retro
  AGENT_OFFLINE              Set to 1 to forbid network calls and use cache

Examples:
  daybrief init
  daybrief collect --json
  daybrief generate
  daybrief show --backstage
  daybrief feedback "Prefer morning trains" --kind preference
  daybrief retro --dry-run
  daybrief mcp --http
```

<!-- /generated -->

## init

<!-- generated: ../scripts/daybrief init --help -->

```text
Usage: daybrief init [-h] [--json]

Options:
  -h, --help  Display this help message and exit
  --json      Print JSON
```

<!-- /generated -->

## collect

<!-- generated: ../scripts/daybrief collect --help -->

```text
Usage: daybrief collect [-h] [--date YYYY-MM-DD] [--pull] [--json] [-o FILE]

Options:
  -h, --help         Display this help message and exit
  --date YYYY-MM-DD  Reference date
  --pull             Fetch managed mirror clones inside $DAYBRIEF_DIR/repos/
                     first
  --json             Print JSON
  -o, --output FILE  Write output to FILE
```

<!-- /generated -->

## generate

<!-- generated: ../scripts/daybrief generate --help -->

```text
Usage: daybrief generate [-h] [--date YYYY-MM-DD] [--model MODEL] [--pull]
                         [--dry-run] [--json] [-o FILE]

Options:
  -h, --help         Display this help message and exit
  --date YYYY-MM-DD  Briefing date
  --model MODEL      Model identifier
  --pull             Fetch managed mirror clones inside $DAYBRIEF_DIR/repos/
                     first
  --dry-run          Run synthesis without recording briefing or cooldowns
  --json             Print JSON
  -o, --output FILE  Write output to FILE
```

<!-- /generated -->

## show

<!-- generated: ../scripts/daybrief show --help -->

```text
Usage: daybrief show [-h] [--backstage] [--item ITEM_ID] [--json] [-o FILE]
                     [ID_OR_DATE]

positional arguments:
  ID_OR_DATE         Brief ID or YYYY-MM-DD

Options:
  -h, --help         Display this help message and exit
  --backstage        Include silent Producer's Packet notes
  --item ITEM_ID     Filter to one item ID
  --json             Print JSON
  -o, --output FILE  Write output to FILE
```

<!-- /generated -->

## list

<!-- generated: ../scripts/daybrief list --help -->

```text
Usage: daybrief list [-h] [--limit N] [--json]

Options:
  -h, --help  Display this help message and exit
  --limit N   Maximum rows (default: 10)
  --json      Print JSON
```

<!-- /generated -->

## feedback

<!-- generated: ../scripts/daybrief feedback --help -->

```text
Usage: daybrief feedback [-h] [--brief BRIEF_ID] [--item ITEM_ID]
                         [--kind {note,answer,outcome,preference,snooze}]
                         [--snooze-days N] [--json]
                         TEXT

positional arguments:
  TEXT                  Feedback or answer text

Options:
  -h, --help            Display this help message and exit
  --brief BRIEF_ID      Target brief ID
  --item ITEM_ID        Target item ID
  --kind {note,answer,outcome,preference,snooze}
                        Feedback kind (default: note)
  --snooze-days N       Days to suppress cooldown key when --kind snooze
                        (default: 14)
  --json                Print JSON
```

<!-- /generated -->

## retro

<!-- generated: ../scripts/daybrief retro --help -->

```text
Usage: daybrief retro [-h] [--days N] [--model MODEL] [--dry-run] [--rollback]
                      [--json]

Options:
  -h, --help     Display this help message and exit
  --days N       Lookback window in days (default: 7)
  --model MODEL  Model identifier
  --dry-run      Preview diff without writing
  --rollback     Restore previous editorial-guidance.md version
  --json         Print JSON
```

<!-- /generated -->

## mcp

<!-- generated: ../scripts/daybrief mcp --help -->

```text
Usage: daybrief mcp [-h] [--dir DIR] [--http] [--host HOST] [--port PORT]
                    [--allow-host HOST] [--access-team HOST]
                    [--access-aud AUD] [--log FILE]

Serve stored Daybrief morning briefings and Producer's Packets over MCP, and record explicit owner feedback.

Options:
  -h, --help          Display this help message and exit
  --dir DIR           State directory (default: $DAYBRIEF_DIR, else
                      ~/.local/state/daybrief)
  --http              Serve HTTP at /mcp, not stdio
  --host HOST         HTTP address
  --port PORT         HTTP port (default: 8794)
  --allow-host HOST   Also accept requests addressed to HOST, such as a
                      tunnel's hostname
  --access-team HOST  Cloudflare Access team domain (default:
                      DAYBRIEF_MCP_ACCESS_TEAM)
  --access-aud AUD    Cloudflare Access application audience tag (default:
                      DAYBRIEF_MCP_ACCESS_AUD)
  --log FILE          Request log (default: $DAYBRIEF_MCP_LOG)

Tools:
  get_today_brief   latest (or dated) briefing with silent Producer's Packet
  get_brief         inspect a briefing or single item dossier by ID or date
  list_briefs       metadata list of recent briefings, newest first
  record_feedback   record explicit user note, answer, preference, or snooze

Environment:
  DAYBRIEF_DIR                  State directory (default: ~/.local/state/daybrief)
  DAYBRIEF_MCP_LOG              Request log (default: $XDG_STATE_HOME/daybrief/mcp.jsonl)
  DAYBRIEF_MCP_ACCESS_TEAM      Cloudflare Access team domain
  DAYBRIEF_MCP_ACCESS_AUD       Cloudflare Access application audience tag
  DAYBRIEF_MCP_ACCESS_CERTS_URL Team certificate URL, for testing

Examples:
  claude mcp add daybrief -- daybrief mcp
  daybrief mcp --http
  daybrief mcp --http --host 0.0.0.0 --allow-host daybrief.example.com \
    --access-team example.cloudflareaccess.com --access-aud AUD
  mcp logs --server daybrief --since 1d

GET /up is open for a proxy health check and is not logged. With both Access
flags, every other HTTP request must carry a valid Cf-Access-Jwt-Assertion
token; without them --http binds loopback only.
```

<!-- /generated -->

## doctor

<!-- generated: ../scripts/daybrief doctor --help -->

```text
Usage: daybrief doctor [-h] [--json]

Options:
  -h, --help  Display this help message and exit
  --json      Print JSON
```

<!-- /generated -->

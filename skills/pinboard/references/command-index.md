# Command Index

<!-- markdownlint-disable MD013 -->

## Contents

- [Help](#help)
- [sync](#sync)
- [search](#search)
- [get](#get)
- [tags](#tags)
- [add](#add)
- [update](#update)
- [restore](#restore)
- [history](#history)
- [suggest](#suggest)
- [doctor](#doctor)
- [mcp](#mcp)

## Help

The blocks below are generated from each command's `--help` by
`command-index-format`.

<!-- generated: ../scripts/pinboard --help -->

```text
Usage: pinboard [--repo DIR] COMMAND [OPTIONS]

Keep a Git mirror of a Pinboard account, search it, and change bookmarks
through the Pinboard API. Pinboard stays authoritative: the mirror is never
written back.

Commands:
  sync              Bring the mirror up to date with Pinboard
  search [TERM...]  Search the mirror (every term must match)
  get URL           Show one bookmark from the mirror
  tags              List tags in the mirror, most used first
  add URL           Add a bookmark (private, never replacing one)
  update URL        Change a bookmark's title, notes, tags or flags
  restore URL       Re-add a deleted bookmark from the mirror's history
  history URL       List the mirror's versions of a bookmark
  suggest URL       Ask Pinboard for tag suggestions
  doctor            Check the token, the clone and the mirror (read-only)
  mcp               Serve the mirror to agents over MCP

Options:
  --repo DIR   The mirror clone (default: $PINBOARD_REPO, else ~/.pinboard);
               must appear before COMMAND
  -h, --help   Display this help message and exit

Environment:
  PINBOARD_API_TOKEN  API token, USER:HEX, from https://pinboard.in/settings/password
  PINBOARD_REPO       The mirror clone, if --repo is not given
  PINBOARD_API_URL    API base URL (default: https://api.pinboard.in/v1/)
  AGENT_OFFLINE       Refuse every API call; search, get, tags, history and
                      doctor still work from the mirror

Examples:
  pinboard sync
  pinboard search rust async --tag programming
  pinboard add https://example.com/post --title "A post" --tags "reading web"
  pinboard update https://example.com/post --add-tag later --remove-tag reading

Reads never call the API, so results are as fresh as the last sync; search,
get and tags say when that was. sync calls posts/update, then posts/all only
if Pinboard changed, and refuses to delete more than 10 bookmarks at once.
```

<!-- /generated -->

## sync

<!-- generated: ../scripts/pinboard sync --help -->

```text
Usage: pinboard sync [-h] [--full] [--force] [--dry-run]

Bring the mirror up to date with Pinboard. Calls posts/update and, only if
Pinboard changed, posts/all (allowed once every 5 minutes); commits and pushes
the result. The deletion guard refuses an empty or malformed response, refuses
to delete more than 10 bookmarks, and confirms each deletion with posts/get.

Options:
  -h, --help  Display this help message and exit
  --full      Fetch posts/all even if posts/update reports no change
  --force     Delete any number of missing bookmarks without confirming each
              (an empty or malformed response is still refused)
  --dry-run   Fetch and report, but change nothing

Examples:
  pinboard sync
  pinboard sync --dry-run
  pinboard sync --full
```

<!-- /generated -->

## search

<!-- generated: ../scripts/pinboard search --help -->

```text
Usage: pinboard search [-h] [--tag TAG] [--limit N] [--cursor CURSOR] [--json]
                       [TERM ...]

Search the mirror: every TERM must appear, case-insensitively, in the title,
notes, tags or URL. Newest first; notes are truncated (use get for all of
them). Exits 1 if nothing matches and 2 on an error.

Arguments:
  TERM             Words that must all match

Options:
  -h, --help       Display this help message and exit
  --tag TAG        Only bookmarks with TAG (repeatable)
  --limit N        Results per page (default: 20)
  --cursor CURSOR  Continue from a previous page
  --json           Print JSON

Examples:
  pinboard search sqlite
  pinboard search --tag recipes lemon
  pinboard search --json --limit 50 kotlin coroutines
```

<!-- /generated -->

## get

<!-- generated: ../scripts/pinboard get --help -->

```text
Usage: pinboard get [-h] [--json] URL

Show one bookmark from the mirror, with its notes in full. Exits 1 if the
mirror does not have it.

Arguments:
  URL         The bookmark's exact URL

Options:
  -h, --help  Display this help message and exit
  --json      Print JSON

Examples:
  pinboard get https://example.com/post
  pinboard get --json https://example.com/post
```

<!-- /generated -->

## tags

<!-- generated: ../scripts/pinboard tags --help -->

```text
Usage: pinboard tags [-h] [--json]

List the tags in the mirror with their counts, most used first.

Options:
  -h, --help  Display this help message and exit
  --json      Print JSON

Examples:
  pinboard tags | head
  pinboard tags --json
```

<!-- /generated -->

## add

<!-- generated: ../scripts/pinboard add --help -->

```text
Usage: pinboard add [-h] --title TITLE [--notes TEXT] [--tags TAGS] [--public]
                    [--toread] [--dry-run]
                    URL

Add a bookmark through the API, private unless --public. It never replaces an
existing bookmark: if Pinboard already has URL, it is shown unchanged. The
bookmark is then read back and committed to the mirror.

Arguments:
  URL            The URL to bookmark

Options:
  -h, --help     Display this help message and exit
  --title TITLE  Title (at most 255 characters)
  --notes TEXT   Notes (at most 65,536 characters)
  --tags TAGS    Tags, separated by spaces or commas
  --public       Make the bookmark public
  --toread       Mark it to read
  --dry-run      Show the request without sending it

Examples:
  pinboard add https://example.com/post --title "A post"
  pinboard add https://example.com/post --title "A post" --tags "web reading" --toread
  pinboard add https://example.com/post --title "A post" --dry-run
```

<!-- /generated -->

## update

<!-- generated: ../scripts/pinboard update --help -->

```text
Usage: pinboard update [-h] [--title TITLE] [--notes TEXT] [--tags TAGS]
                       [--add-tag TAG] [--remove-tag TAG] [--public |
                       --private] [--toread | --read] [--dry-run]
                       URL

Change a bookmark. Reads it live from Pinboard, changes only the given fields,
keeps its date, then reads it back and commits it to the mirror.

Arguments:
  URL               The bookmark's exact URL

Options:
  -h, --help        Display this help message and exit
  --title TITLE     Title (at most 255 characters)
  --notes TEXT      Notes (at most 65,536 characters)
  --tags TAGS       Tags, separated by spaces or commas; replaces all tags
  --add-tag TAG     Add TAG (repeatable)
  --remove-tag TAG  Remove TAG (repeatable)
  --public          Make it public
  --private         Make it private
  --toread          Mark it to read
  --read            Mark it read
  --dry-run         Show the change without sending it

Examples:
  pinboard update https://example.com/post --add-tag later
  pinboard update https://example.com/post --tags "web rust" --private
  pinboard update https://example.com/post --title "Better title" --dry-run
```

<!-- /generated -->

## restore

<!-- generated: ../scripts/pinboard restore --help -->

```text
Usage: pinboard restore [-h] [--dry-run] URL

Re-add a bookmark deleted from Pinboard, as the mirror last recorded it,
keeping its original date. Refuses if the mirror still has URL.

Arguments:
  URL         The deleted bookmark's exact URL

Options:
  -h, --help  Display this help message and exit
  --dry-run   Show the request without sending it

Examples:
  pinboard history https://example.com/post
  pinboard restore https://example.com/post
```

<!-- /generated -->

## history

<!-- generated: ../scripts/pinboard history --help -->

```text
Usage: pinboard history [-h] [--json] URL

List the versions of a bookmark recorded in the mirror's Git history, newest
first. Exits 1 if there are none.

Arguments:
  URL         The bookmark's exact URL

Options:
  -h, --help  Display this help message and exit
  --json      Print JSON

Examples:
  pinboard history https://example.com/post
  pinboard history --json https://example.com/post
```

<!-- /generated -->

## suggest

<!-- generated: ../scripts/pinboard suggest --help -->

```text
Usage: pinboard suggest [-h] [--json] URL

Ask Pinboard for popular and recommended tags for URL (a live API call).

Arguments:
  URL         The URL to suggest tags for

Options:
  -h, --help  Display this help message and exit
  --json      Print JSON

Examples:
  pinboard suggest https://example.com/post
```

<!-- /generated -->

## doctor

<!-- generated: ../scripts/pinboard doctor --help -->

```text
Usage: pinboard doctor [-h] [--json]

Check the token, the clone and its remote, the mirror files, unpushed
commits, freshness and rate limits. Read-only; makes no API call. Exits 1 on
any WARN or FAIL.

Options:
  -h, --help  Display this help message and exit
  --json      Print JSON

Examples:
  pinboard doctor
  pinboard doctor --json
```

<!-- /generated -->

## mcp

<!-- generated: ../scripts/pinboard mcp --help -->

```text
Usage: pinboard mcp [-h] [--repo DIR] [--http] [--host HOST] [--port PORT]
                    [--allow-host HOST] [--access-team HOST]
                    [--access-aud AUD] [--sync-every HOURS] [--log FILE]

Serve the Pinboard mirror to agents over MCP: search it, and add
or update bookmarks through the API.

Options:
  -h, --help          Display this help message and exit
  --repo DIR          The mirror clone (default: $PINBOARD_REPO, else
                      ~/.pinboard)
  --http              Serve streamable HTTP at /mcp, not stdio
  --host HOST         HTTP address (default: 127.0.0.1)
  --port PORT         HTTP port (default: 8791)
  --allow-host HOST   Also accept requests addressed to HOST, such as a
                      tunnel's hostname
  --access-team HOST  Cloudflare Access team domain (default:
                      PINBOARD_MCP_ACCESS_TEAM)
  --access-aud AUD    Cloudflare Access application audience tag (default:
                      PINBOARD_MCP_ACCESS_AUD)
  --sync-every HOURS  With --http, sync when the last sync is this old
                      (default: 24; 0 never syncs on its own)
  --log FILE          Request log (default: $PINBOARD_MCP_LOG)

Tools:
  search_bookmarks, get_bookmark, list_tags   read the mirror; never the API
  suggest_tags                                a live Pinboard call
  add_bookmark, update_bookmark               write to Pinboard, then the mirror
  sync                                        bring the mirror up to date

Environment:
  PINBOARD_API_TOKEN            API token, as for every pinboard command
  PINBOARD_REPO                 The mirror clone, if --repo is not given
  PINBOARD_MCP_LOG              Request log (default:
                                $XDG_STATE_HOME/pinboard/mcp.jsonl, else
                                ~/.local/state/pinboard/mcp.jsonl)
  PINBOARD_MCP_ACCESS_TEAM      Cloudflare Access team domain
  PINBOARD_MCP_ACCESS_AUD       Cloudflare Access application audience tag
  PINBOARD_MCP_ACCESS_CERTS_URL Team certificate URL, for testing (default:
                                https://TEAM/cdn-cgi/access/certs)

Examples:
  claude mcp add pinboard -- pinboard mcp
  pinboard mcp --http
  pinboard mcp --http --host 0.0.0.0 --allow-host pinboard.example.com \
    --access-team example.cloudflareaccess.com --access-aud AUD

Over stdio the server never syncs on its own; call the sync tool, or run
'pinboard sync'. Over HTTP (at /mcp) it also syncs whenever the last sync
is older than --sync-every hours: at startup, then checking hourly, so a
refused or failed run is retried an hour later. Each tool call and scheduled
sync is appended to the request log, rotated at 8 MiB with four old files kept.

The HTTP server serves GET /up without a token for a proxy's health check.
Without --access-team and --access-aud it listens on loopback only and does no
authentication of its own. With both, it may bind another --host and requires
the Cf-Access-Jwt-Assertion header on every other request, checking the token
against the team's certificates, issuer, audience, and expiry. --allow-host
admits the proxy's hostname.
```

<!-- /generated -->

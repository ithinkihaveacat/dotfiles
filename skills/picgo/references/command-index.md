# Command Index

<!-- markdownlint-disable MD013 -->

## Contents

- [Help](#help)
- [upload](#upload)
- [get](#get)
- [list](#list)
- [delete](#delete)
- [mcp](#mcp)
- [doctor](#doctor)

## Help

The blocks below are generated from each command's `--help` by
`command-index-format`.

<!-- generated: ../scripts/picgo --help -->

```text
Usage: picgo [-h] [--dir DIR] COMMAND ...

Keep the last ten images or videos in a store, for sharing with agents.

positional arguments:
  COMMAND
    upload    Add images or videos
    get       Read the latest item, or ID, as bytes
    list      Show the stored items, newest first
    delete    Remove items
    mcp       Serve the store over MCP
    doctor    Check the store and image support

Options:
  -h, --help  Display this help message and exit
  --dir DIR   The store (default: $PICGO_DIR, else ~/.cache/picgo)

  picgo upload photo.jpg clip.mp4
  picgo list
  picgo get --output latest.jpg
  picgo get 20261112T143012.123456Z-7f3a9c --output photo.jpg
  PICGO_SERVER=https://picgo.example.com picgo upload photo.jpg
  picgo mcp --http --host 0.0.0.0 --allow-host picgo.example.com
```

<!-- /generated -->

## upload

<!-- generated: ../scripts/picgo upload --help -->

```text
Usage: picgo upload [-h] [--json] FILE [FILE ...]

positional arguments:
  FILE

Options:
  -h, --help  Display this help message and exit
  --json      Print JSON
```

<!-- /generated -->

## get

<!-- generated: ../scripts/picgo get --help -->

```text
Usage: picgo get [-h] [-o FILE] [--json] [ID]

positional arguments:
  ID

Options:
  -h, --help         Display this help message and exit
  -o, --output FILE  Write to FILE
  --json             Print metadata, not bytes
```

<!-- /generated -->

## list

<!-- generated: ../scripts/picgo list --help -->

```text
Usage: picgo list [-h] [--json]

Options:
  -h, --help  Display this help message and exit
  --json      Print JSON
```

<!-- /generated -->

## delete

<!-- generated: ../scripts/picgo delete --help -->

```text
Usage: picgo delete [-h] ID [ID ...]

positional arguments:
  ID

Options:
  -h, --help  Display this help message and exit
```

<!-- /generated -->

## mcp

<!-- generated: ../scripts/picgo mcp --help -->

```text
Usage: picgo mcp [-h] [--dir DIR] [--http] [--host HOST] [--port PORT]
                 [--allow-host HOST] [--access-team HOST] [--access-aud AUD]
                 [--log FILE]

Serve a store of the last ten images or videos over MCP, and serve the PWA's REST API.

Options:
  -h, --help          Display this help message and exit
  --dir DIR           The store (default: $PICGO_DIR, else ~/.cache/picgo)
  --http              Serve HTTP at /mcp, not stdio
  --host HOST         HTTP address
  --port PORT         HTTP port (default: 8793)
  --allow-host HOST   Also accept requests addressed to HOST, such as a
                      tunnel's hostname
  --access-team HOST  Cloudflare Access team domain (default:
                      PICGO_MCP_ACCESS_TEAM)
  --access-aud AUD    Cloudflare Access application audience tag (default:
                      PICGO_MCP_ACCESS_AUD)
  --log FILE          Request log (default: $PICGO_MCP_LOG)

Tools:
  upload_media   add an image or video from base64 data
  get_media      the most recent item, or one ID, with its bytes attached
  list_media     metadata only, newest first
  delete_media   remove one item

Environment:
  PICGO_DIR                  The store (default: ~/.cache/picgo)
  PICGO_MAX_EDGE             Longest edge for images (default: 2048)
  PICGO_MAX_UPLOAD_BYTES     Largest accepted upload (default: 67108864)
  PICGO_MCP_LOG              Request log (default:
                             $XDG_STATE_HOME/picgo/mcp.jsonl)
  PICGO_MCP_ACCESS_TEAM      Cloudflare Access team domain
  PICGO_MCP_ACCESS_AUD       Cloudflare Access application audience tag
  PICGO_MCP_ACCESS_CERTS_URL Team certificate URL, for testing

Examples:
  claude mcp add picgo -- picgo mcp
  picgo mcp --http
  picgo mcp --http --host 0.0.0.0 --allow-host picgo.example.com \
    --access-team example.cloudflareaccess.com --access-aud AUD
  mcp logs --server picgo --since 1d

Over stdio the server serves one store. Over HTTP it also serves the PWA at /
and its REST API at /api/media. GET /up is open for a proxy's health check and
is not logged. With both Access flags, every other request must carry a valid
Cf-Access-Jwt-Assertion token; without them the server binds loopback only.
```

<!-- /generated -->

## doctor

<!-- generated: ../scripts/picgo doctor --help -->

```text
Usage: picgo doctor [-h]

Options:
  -h, --help  Display this help message and exit
```

<!-- /generated -->

---
name: picgo
description: >-
  Keeps the ten most recent images and videos in one directory and serves them
  to agents over MCP and to a phone-friendly web app over REST. Upload by file,
  by phone camera, or by base64 over MCP; get the latest item with its bytes
  attached. Use when sharing a photo or short video with an agent, or when
  looking at what was uploaded most recently.
compatibility: Requires Python 3.11+ (via uv) and Pillow.
---

# picgo

`picgo` is a small, disposable store for the ten most recent images and videos.
It exists so that a photo taken on a phone, or an image already on disk, can be
handed to an agent by asking it to "check the latest item in picgo", without a
URL that the agent has to fetch and without a permanent archive.

The directory is the database: one file per item, newest ten kept. There is no
index, no metadata file and no cleanup job. A single `flock` covers each write,
its eviction and each read, so a reader never sees a half-written or
half-deleted item, and concurrent uploads cannot leave eleven files.

Run it as `picgo` when `bin/` is on `PATH`, otherwise as
`<skill-dir>/scripts/picgo`.

## Setup

- The store is `$PICGO_DIR`, else `$XDG_CACHE_HOME/picgo`, else
  `~/.cache/picgo`. It is disposable: deleting it loses the current ten items
  and nothing else.
- `PICGO_MAX_EDGE` caps an image's long edge (default 2048 px).
- `PICGO_MAX_UPLOAD_BYTES` rejects larger uploads (default 64 MiB).
- `PICGO_SERVER` makes `upload`, `get`, `list` and `delete` use a remote
  server's REST API instead of the local store.

`picgo doctor` checks that the store is writable, reports the item count and
whether HEIC support is loaded.

## Uploading

```bash
picgo upload photo.jpg
picgo upload clip.mp4 screenshot.png
picgo upload --json photo.jpg          # item metadata as JSON
```

Images are normalised on ingest:

| Input                             | Stored as                     |
| --------------------------------- | ----------------------------- |
| JPEG, HEIC, HEIF, BMP, TIFF, AVIF | JPEG, quality 85, progressive |
| PNG                               | PNG, optimised                |
| WebP                              | WebP, quality 85              |
| Animated GIF or WebP              | unchanged                     |
| Video                             | unchanged                     |

EXIF orientation is applied before resizing, and re-encoding drops the rest of
the metadata, including GPS coordinates. The long edge is capped at 2048 px and
the image is kept under about 2 MiB by stepping JPEG/WebP quality down; a very
large PNG is halved once. Images are never upscaled.

Videos are not transcoded. They count against `PICGO_MAX_UPLOAD_BYTES` and are
stored as they arrived.

## Reading

```bash
picgo list                     # ID, kind, type, size and time, newest first
picgo list --json
picgo get -o latest.jpg        # the latest item's bytes
picgo get <ID> -o photo.jpg    # one item
picgo get --json               # metadata only
```

`picgo get` with no ID returns the most recent item regardless of kind. An ID is
the filename without its extension, such as `20261112T143012.123456Z-7f3a9c`.

`picgo delete <ID>...` removes items. Deleting one does not backfill from older
items: the store simply holds fewer.

## Eviction and Concurrency

After each successful write the directory is listed newest first and everything
past the tenth is unlinked, all inside the same exclusive lock as the write. The
new bytes go to a `.tmp-*` file in the same directory, are fsynced and then
renamed into place, so a crash leaves either the old set or the new item, never
a partial file. Stray `.tmp-*` files are ignored by every read and by eviction.

Reads take a shared lock and read the file inside it. A read therefore never
races a writer or an eviction; an ID that has genuinely gone returns a clear "no
such item" error rather than a partial result.

## MCP Server

`picgo mcp` serves the store to agents over stdio, or with `--http` over
Streamable HTTP at `/mcp`:

```bash
claude mcp add picgo -- picgo mcp
picgo mcp --http
```

- Tools: `upload_media` (base64), `get_media` (an ID, or the latest item),
  `list_media` (metadata only) and `delete_media`.
- `get_media` attaches the bytes: an `ImageContent` block for JPEG, PNG, GIF and
  WebP, and an `EmbeddedResource` blob for a video. The text block carries the
  item's ID, kind, type, size and creation time. Video is not a typed MCP
  content block, so a client may save the blob rather than display it.
- Over HTTP the server also serves the phone app at `/` and its REST API:
  `POST /api/media` (raw body plus `Content-Type` and `X-Picgo-Filename`),
  `GET /api/media`, `GET /api/media/<id>`, `DELETE /api/media/<id>`. `GET /up`
  is an unauthenticated health check.
- `--access-team` and `--access-aud` make it check the `Cf-Access-Jwt-Assertion`
  header on every request but `GET /up`. Without them it binds loopback only.
- Each request is one JSON record in `--log`, else `PICGO_MCP_LOG`, else
  `$XDG_STATE_HOME/picgo/mcp.jsonl`, rotated at 8 MiB; `mcp logs` reads it.

## Limits

- The store holds ten items. Uploading an eleventh evicts the oldest, whichever
  kind it is.
- There is no authentication of its own. Put it behind something that gates the
  host, such as Cloudflare Access, and keep the media paths behind the same
  gate: an agent receives bytes through MCP and never needs a public URL.
- HEIC needs the pinned `pillow-heif`; without it `picgo doctor` warns and a
  HEIC upload is refused.
- The PWA is one HTML file with no service worker. On iOS, Share → Add to Home
  Screen; on Android, the browser's install prompt may be absent.

## Reference

- [Command Index](references/command-index.md): every command's `--help`.

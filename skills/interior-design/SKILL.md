---
name: interior-design
description: >
  Extracts image URLs and listing metadata from inigo.com property listings,
  and triages downloaded photography with an LLM (e.g. find rooms with a
  bedside table, a fireplace with art above, mismatched dining chairs).
  Captures the Inigo-specific JSON paths (both the legacy __NEXT_DATA__ form
  and the current React Server Components form) and a uv-runnable LLM query
  script. Use when scraping inigo.com listings, cataloguing interior-design
  reference photos, or running yes/no visual questions over a directory of
  JPGs. Triggers: inigo, inigo.com, interior design, property photography,
  gallery scrape, image triage, bedside table, fireplace, mismatched chairs.
compatibility: >-
  inigo-gallery is zero-dependency Python 3 (stdlib only). query-llm.py uses
  `uv run` with inline dependencies (llm, llm-gemini, pillow) and needs an
  LLM API key configured via `llm keys`. To download images, pipe
  inigo-gallery into wget/curl/aria2c.
---

# Interior Design (Inigo)

## Important: Use Scripts First

**ALWAYS prefer the scripts in `scripts/` over hand-rolled HTTP and HTML
parsing.** They encode site-specific knowledge that is otherwise easy to get
wrong:

- The exact JSON paths Inigo uses for gallery images (different in the current
  App-Router site versus the legacy Pages-Router pages)
- Unwrapping the RSC `self.__next_f.push(...)` chunk format to get to the
  listing payload
- A memoised `resize_image` helper that the query script needs to stay fast
  across re-runs

**When to read the script source:** if a script doesn't do what you need, or
fails because Inigo has changed their page structure again, read the source —
it's short, and the format-detection edge cases are the actual value.

## Quick Start

### Find listings matching criteria

```bash
scripts/inigo-search                       # 20 active listing URLs
scripts/inigo-search --sold --price-to 500 # sold listings up to £500k
scripts/inigo-search --address london --json
```

Prints one listing-detail URL per line on stdout (or full summaries with
`--json`). Inigo's index pages only embed the first 20 results plus 6 optional
`--include-featured` — pagination is JS-only and not URL-addressable, so a
single invocation sees ≤ 26 listings. The total catalogue size is printed to
stderr.

### Get gallery image URLs

```bash
scripts/inigo-gallery https://www.inigo.com/past-sales/<slug>
```

Prints one image URL per line on stdout. Add `--json` to get the full parsed
listing payload (address, price, body text, gallery, etc.) instead.

### Download a gallery into a directory

```bash
mkdir <slug> && scripts/inigo-gallery <URL> | wget -i - -P <slug>/
```

### Search → download in one pipeline

```bash
scripts/inigo-search --sold --price-to 500 --limit 3 \
  | while read url; do
      slug=$(basename "$url"); mkdir -p "$slug"
      scripts/inigo-gallery "$url" | wget -q -i - -P "$slug/"
    done
```

Or with parallel downloads:

```bash
scripts/inigo-gallery <URL> | xargs -n1 -P4 -I{} curl -sO --output-dir <slug>/ {}
```

### Triage downloaded images with an LLM

```bash
scripts/query-llm.py ./<slug> \
  --prompt "Does this image feature a bedside table?" \
  --schema "has_bedside_table bool" \
  --filter has_bedside_table
```

Recursively walks `*.jpg` under the given directory, asks the configured LLM the
prompt with a JSON-schema response, and prints filenames whose boolean field is
true. Omit `--filter` to dump the full parsed JSON for each file.

## Scripts

- `scripts/inigo-search [filters]` — print listing-detail URLs from `/all-homes`
  (or `/past-sales` with `--sold`). Filters: `--price-from K`, `--price-to K`
  (£000s), `--bedrooms N`, `--min-bedrooms N`, `--address SUBSTR`,
  `--include-featured`, `--limit N`, `--json`. Limited to 20–26 listings per
  invocation; see the reference doc for why. Zero deps.
- `scripts/inigo-gallery URL` — print gallery image URLs from an Inigo listing.
  `--json` emits the full listing payload instead. Zero deps. See
  [references/inigo-source-structure.md](references/inigo-source-structure.md)
  for the JSON paths used.
- `scripts/query-llm.py DIR --prompt … --schema …` — run a yes/no visual
  question over every JPG in DIR. Flags: `--filter FIELD`, `--model MODEL`
  (default `gemini/gemini-2.5-flash-lite`), `--max-size N` (default `512`).

## Example schemas

Worked-in-practice prompts the existing data was triaged with:

| Topic                | Prompt                                                                                     | Schema                                                   |
| -------------------- | ------------------------------------------------------------------------------------------ | -------------------------------------------------------- |
| Bedside table        | `"Does this image feature a bed? Does it feature a bedside table?"`                        | `"has_bed bool, has_bedside_table bool"`                 |
| Mismatched chairs    | `"Does this image feature a dining table with mismatched chairs (not in the same style)?"` | `"has_mismatched_chairs bool"`                           |
| Fireplace + art + TV | `"Does this image show a fireplace? Artwork above a fireplace? A TV?"`                     | `"fireplace bool, artwork_over_fireplace bool, tv bool"` |

## Safety Notes

- `inigo-gallery` only fetches HTML; it does not download images. The caller
  decides what to do with the URLs.
- `query-llm.py` sends each resized image to the configured LLM provider. Costs
  scale with directory size; the local `tempfile`-based cache only saves on
  re-resize, not on re-prompting.

## Reference Material

- [references/inigo-source-structure.md](references/inigo-source-structure.md) —
  URL surface (`/all-homes`, `/past-sales`, `/sales-list/<slug>`), both Inigo
  gallery JSON formats, search/discovery JSON shape, observed filename patterns,
  verification probes, model notes.

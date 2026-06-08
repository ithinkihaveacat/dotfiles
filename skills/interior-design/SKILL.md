---
name: interior-design
description: >
  Extracts image URLs and listing metadata from inigo.com property listings.
  Pairs with `agent-tools/scripts/photo-query` for triaging downloaded
  photography with an LLM (e.g. find rooms with a bedside table, a fireplace
  with art above, mismatched dining chairs). Captures the Inigo-specific JSON
  paths (both the legacy __NEXT_DATA__ form and the current React Server
  Components form). Use when scraping inigo.com listings or cataloguing
  interior-design reference photos. Triggers: inigo, inigo.com, interior
  design, property photography, gallery scrape, image triage, bedside table,
  fireplace, mismatched chairs.
compatibility: >-
  inigo-search and inigo-gallery are zero-dependency Python 3 (stdlib only).
  To download images, pipe inigo-gallery into wget/curl/aria2c. For
  image triage, use `photo-query` from the agent-tools skill (requires
  GEMINI_API_KEY).
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

**When to read the script source:** if a script doesn't do what you need, or
fails because Inigo has changed their page structure again, read the source —
it's short, and the format-detection edge cases are the actual value.

## Quick Start

### Find listings matching criteria

Two modes:

```bash
scripts/inigo-search website [filters]    # live data, ≤26 per section, filterable
scripts/inigo-search sitemap [filters]    # full catalogue (~700 URLs), slug only
```

`website` queries the embedded `initialData` on `/all-homes` and `/past-sales`
(merging both by default; pass `--active` or `--sold` to narrow). Pagination is
JS-only, so each section yields ≤ 20 summaries plus 6 with `--include-featured`.
Supports price/bedrooms/address filters; emits URLs (or full summaries with
`--json`).

`sitemap` enumerates every listing URL from `https://www.inigo.com/sitemap.xml`
— ~520 sold + ~170 active. Best for archive enumeration or initial pulls. Only
slug-substring filtering is available because the sitemap carries no metadata
beyond `<loc>` and `<lastmod>`.

Both modes print catalogue counts to stderr.

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
scripts/inigo-search website --sold --price-to 500 --limit 3 \
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

Triage is delegated to `photo-query` from the agent-tools skill — it handles
EXIF rotation, resizing, and caches pre-processed bytes so multiple queries
against the same directory don't re-encode.

```bash
~/.claude/skills/agent-tools/scripts/photo-query ask --recursive \
  --prompt "Does this image feature a bedside table?" \
  --schema "has_bedside_table bool" \
  --filter has_bedside_table \
  ./<slug>
```

Prints paths whose boolean field is true. Omit `--filter` to emit the full
parsed JSON per file. See the `agent-tools` skill for full subcommand docs
(`has-people`, `describe`, `ask`).

## Scripts

- `scripts/inigo-search website [filters]` — query the live index pages
  (`/all-homes`, `/past-sales`). Filters: `--active`/`--sold` (default merges
  both), `--price-from K`, `--price-to K` (£000s), `--bedrooms N`,
  `--min-bedrooms N`, `--address SUBSTR`, `--include-featured`, `--limit N`,
  `--json`. Limited to ≤ 26 listings per section because pagination is JS-only;
  see the reference doc for why. Zero deps.
- `scripts/inigo-search sitemap [filters]` — enumerate every listing URL via
  `sitemap.xml` (~690 URLs). Filters: `--active`/`--sold` (default merges both),
  `--address` (slug substring), `--limit N`, `--json`. Use for archive
  enumeration or initial pulls. Zero deps.
- `scripts/inigo-gallery URL` — print gallery image URLs from an Inigo listing.
  `--json` emits the full listing payload instead. Zero deps. See
  [references/inigo-source-structure.md](references/inigo-source-structure.md)
  for the JSON paths used.

For LLM-based image triage, use the `photo-query` script from the `agent-tools`
skill (no duplicate here).

## Example queries

Worked-in-practice prompts the existing data was triaged with, run via
`photo-query ask`:

| Topic                | `--prompt`                                                                                 | `--schema`                                               |
| -------------------- | ------------------------------------------------------------------------------------------ | -------------------------------------------------------- |
| Bedside table        | `"Does this image feature a bed? Does it feature a bedside table?"`                        | `"has_bed bool, has_bedside_table bool"`                 |
| Mismatched chairs    | `"Does this image feature a dining table with mismatched chairs (not in the same style)?"` | `"has_mismatched_chairs bool"`                           |
| Fireplace + art + TV | `"Does this image show a fireplace? Artwork above a fireplace? A TV?"`                     | `"fireplace bool, artwork_over_fireplace bool, tv bool"` |

## Safety Notes

- `inigo-gallery` only fetches HTML; it does not download images. The caller
  decides what to do with the URLs.
- `photo-query` (in the agent-tools skill) sends each resized image to the
  Gemini API. Costs scale with directory size × queries; its disk cache only
  amortises the local resize/encode step, not the per-query API spend.

## Reference Material

- [references/inigo-source-structure.md](references/inigo-source-structure.md) —
  URL surface (`/all-homes`, `/past-sales`, `/sales-list/<slug>`), both Inigo
  gallery JSON formats, search/discovery JSON shape, observed filename patterns,
  verification probes.

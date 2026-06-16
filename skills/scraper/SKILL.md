---
name: scraper
description: >
  Extracts catalogue and item URLs plus structured metadata from gallery-style
  websites. Ships paired per-site primitives — a `catalog` script that
  enumerates a site's items and a `gallery` script that pulls one item's image
  URLs (or full JSON payload). Currently covers inigo.com property listings
  (zero-dependency stdlib) and dezeen.com article galleries (a real Chrome you
  launch yourself, to clear Cloudflare). Pairs well with an LLM image-query tool
  for triaging downloaded photography. Use when scraping inigo.com or dezeen.com,
  enumerating a site's listings/articles, or cataloguing reference photos.
  Triggers: scrape, scraper, gallery scrape, image triage, catalog listings,
  inigo, inigo.com, dezeen, dezeen.com, playwright, cloudflare, property
  photography, interior design, bedside table, fireplace, kitchen extension.
compatibility: >-
  The inigo-* scripts are zero-dependency Python 3 (stdlib only). The dezeen-*
  scripts need Playwright (auto-installed via the uv script header) and a real
  Chrome you launch with --remote-debugging-port (Cloudflare blocks scripted and
  automation-launched browsers). To download images, pipe a gallery script into
  wget/curl/aria2c. Image triage needs an LLM image-query tool (typically
  requiring an API key such as GEMINI_API_KEY).
---

# Scraper

Retrieval primitives for gallery-style websites. Each supported site gets the
same two scripts, so once you learn the shape for one site you know it for all:

| Script           | Scope      | Input                       | Output                                             |
| ---------------- | ---------- | --------------------------- | -------------------------------------------------- |
| `<site>-catalog` | collection | a search/sitemap/tag target | item URLs (one per line; `--json` = summary cards) |
| `<site>-gallery` | item       | one item URL                | image URLs (one per line; `--json` = full payload) |

They are deliberately small Unix primitives — text in, text out, no shared state
— so they compose by pipe:

```bash
scripts/<site>-catalog TARGET | while read -r url; do
  scripts/<site>-gallery "$url" | wget -i - -P "$(basename "$url")/"
done
```

Bulk-download orchestration (deciding a data-directory layout, skipping
already-fetched items, counting progress) is intentionally **not** in this
skill: it is project-specific glue that belongs with the data it writes. This
skill ends at "here are the URLs and metadata".

## Important: Use Scripts First

**ALWAYS prefer the scripts in `scripts/` over hand-rolled HTTP and HTML
parsing.** They encode site-specific knowledge that is otherwise easy to get
wrong — the exact JSON paths, the page-format quirks, and (for Dezeen) the
Cloudflare workaround.

**When to read the script source:** if a script doesn't do what you need, or
fails because a site changed its page structure, read the source — it's short,
and the parsing details are the actual value. References to `scripts/...` and
`references/...` in this skill are relative to this skill directory.

## Sites

### Inigo (inigo.com) — zero-dependency stdlib

Property listings. Both scripts are pure Python 3 stdlib (no install step).

```bash
# Enumerate listings (two modes)
scripts/inigo-catalog website [filters]   # live index, ≤26 per section, filterable
scripts/inigo-catalog sitemap  [filters]  # full catalogue (~700 URLs), slug only

# One listing's gallery
scripts/inigo-gallery https://www.inigo.com/past-sales/<slug>          # image URLs
scripts/inigo-gallery https://www.inigo.com/past-sales/<slug> --json   # full payload
```

`inigo-catalog website` queries the embedded `initialData` on `/all-homes` and
`/past-sales` (merging both by default; pass `--active` or `--sold` to narrow).
Pagination is JS-only, so each section yields ≤ 20 summaries plus 6 with
`--include-featured`. Supports price/bedrooms/address filters; emits URLs (or
full summaries with `--json`).

`inigo-catalog sitemap` enumerates every listing URL from
`https://www.inigo.com/sitemap.xml` (~520 sold + ~170 active). Best for archive
enumeration or initial pulls. Only slug-substring filtering is available because
the sitemap carries no metadata beyond `<loc>` and `<lastmod>`. Both modes print
catalogue counts to stderr.

See [references/inigo-source-structure.md](references/inigo-source-structure.md)
for the JSON paths and page formats.

### Dezeen (dezeen.com) — needs a Chrome you launch yourself

Article galleries. The `dezeen-*` scripts depend on Playwright **and** on a real
Chrome you launch and keep visible: Cloudflare bot management 403s scripted HTTP
clients (`curl`/`urllib`) and rejects automation-launched/headless browsers
(`navigator.webdriver = true`). The reliable path is connecting over the
DevTools protocol to a human-launched Chrome, which looks like an ordinary
browser. Launch one once per session:

```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
    --remote-debugging-port=9222 --user-data-dir=/tmp/chrome-dezeen-profile &
```

Then:

```bash
# Enumerate a tag's articles (walks all pages)
scripts/dezeen-catalog london-extensions
scripts/dezeen-catalog london-extensions --limit 10 --json   # summary cards

# One article's gallery
scripts/dezeen-gallery https://www.dezeen.com/2026/05/18/<slug>/          # image URLs
scripts/dezeen-gallery https://www.dezeen.com/2026/05/18/<slug>/ --json   # full payload
```

If a Cloudflare challenge ever appears, solve it once in that window — the
clearance cookie covers the rest of the session, and the scripts wait for you.
Override the DevTools endpoint with `DEZEEN_CDP_URL`. Only the HTML needs the
browser; images download straight from `static.dezeen.com` with `wget`. See
[references/dezeen-source-structure.md](references/dezeen-source-structure.md)
for the full findings.

## Triage downloaded images with an LLM

Once images are on disk, triage is best delegated to a dedicated LLM image-query
tool rather than hand-rolled API calls. The right shape of tool takes a
free-form question plus a structured-output schema (e.g.
`"has_bedside_table bool"`), runs it against a directory of images, and can
filter to just the paths whose boolean field is true — ideally handling EXIF
rotation, resizing, and caching of pre-processed bytes so repeated queries don't
re-encode.

Search the installed skills for such a tool before writing anything yourself —
this dotfiles ecosystem ships one. Check the available skills (and `bin/`) for
an image- or photo-query tool and use its documented interface.

Worked-in-practice prompts:

| Topic                | Prompt                                                                                     | Schema                                                   |
| -------------------- | ------------------------------------------------------------------------------------------ | -------------------------------------------------------- |
| Bedside table        | `"Does this image feature a bed? Does it feature a bedside table?"`                        | `"has_bed bool, has_bedside_table bool"`                 |
| Mismatched chairs    | `"Does this image feature a dining table with mismatched chairs (not in the same style)?"` | `"has_mismatched_chairs bool"`                           |
| Fireplace + art + TV | `"Does this image show a fireplace? Artwork above a fireplace? A TV?"`                     | `"fireplace bool, artwork_over_fireplace bool, tv bool"` |

## Scripts

- `scripts/inigo-catalog website [filters]` — query Inigo's live index pages.
  Filters: `--active`/`--sold` (default merges both), `--price-from K`,
  `--price-to K` (£000s), `--bedrooms N`, `--min-bedrooms N`,
  `--address SUBSTR`, `--include-featured`, `--limit N`, `--json`. ≤ 26 per
  section (JS-only pagination). Zero deps.
- `scripts/inigo-catalog sitemap [filters]` — enumerate every listing URL via
  `sitemap.xml` (~700 URLs). Filters: `--active`/`--sold`, `--address` (slug
  substring), `--limit N`, `--json`. Zero deps.
- `scripts/inigo-gallery URL [--json]` — print one Inigo listing's gallery image
  URLs, or its full listing payload. Zero deps.
- `scripts/dezeen-catalog TAG [--limit N] [--pages N] [--json]` — enumerate a
  Dezeen tag's article URLs (walks the paginated index). Needs Playwright +
  launched Chrome.
- `scripts/dezeen-gallery URL [--json]` — print one Dezeen article's gallery
  image URLs (captioned in `--json`), or its full article payload. Needs
  Playwright + launched Chrome.

## Safety Notes

- The `*-gallery` and `*-catalog` scripts only fetch/parse HTML; they never
  download images. The caller decides what to do with the URLs.
- The `dezeen-*` scripts drive a Chrome you control and wait for you to clear
  any Cloudflare challenge; they do not bypass bot management headlessly.
- LLM image triage sends each (resized) image to a remote API. Costs scale with
  directory size × queries; a local disk cache only amortises the resize/encode
  step, not the per-query API spend.

## Reference Material

- [references/inigo-source-structure.md](references/inigo-source-structure.md) —
  Inigo URL surface, both gallery JSON formats, search/discovery JSON shape,
  filename patterns, verification probes.
- [references/dezeen-source-structure.md](references/dezeen-source-structure.md)
  — Dezeen URL surface, the Cloudflare findings, article JSON-LD + gallery DOM
  shapes, verification probes.

# Inigo source structure

What's documented here is specific to inigo.com and was discovered by
inspection. General Next.js / `llm` knowledge is deliberately omitted.

**Captured:** 2026-06-07. Inigo's site changes — if anything below stops
matching reality, see [Verification](#verification) for a known-stable URL to
probe.

## URL surface

Inigo uses two parallel sections, each with an index page and per-listing detail
pages. Both render data via Next.js App Router (React Server Components).

| Purpose               | URL pattern          | Example                                        |
| --------------------- | -------------------- | ---------------------------------------------- |
| Active listings index | `/all-homes`         | `https://www.inigo.com/all-homes`              |
| Active listing detail | `/sales-list/<slug>` | `https://www.inigo.com/sales-list/pitcombe`    |
| Sold listings index   | `/past-sales`        | `https://www.inigo.com/past-sales`             |
| Sold listing detail   | `/past-sales/<slug>` | `https://www.inigo.com/past-sales/mare-street` |

Slug values are the third segment of any listing URL and are the join key across
the API: index pages list them, detail pages are addressed by them, and they
appear in the listing's CMS payload as `slug.current`.

The `inigo-gallery` script accepts any listing-detail URL (active or sold).

## Per-listing detail pages

Data is embedded in `self.__next_f.push([1,"..."])` inline scripts (Next.js App
Router / RSC). Each chunk is a JSON-escaped string; the chunk containing the
listing starts with an RSC line like `5:[...]` whose 4th array element is the
props object. The listing payload is at `.listing` inside those props, and image
URLs are at:

```
.listing.gallery.images[].imageUrl
```

CDN host: `cdn.themodernhouse.com`. Filenames are sequential integers (`1.jpg`,
`2.jpg`, …) inside listing-specific path segments. This format is the only one
served by inigo.com today — verified against the oldest sitemap entries
(2025-11) on 2026-06-08.

### Listing payload shape (`--json` output)

`inigo-gallery --json` emits the listing object. Top-level keys observed on
current listings:

- `slug` — `{_type: "slug", current: "<slug>"}`
- `address`, `bedroomCount`, `architect`, `areas`
- `propertyType` — `"house"` or `"flat"`
- `price` — integer, in £ (no formatting)
- `ownership` — e.g. `"freehold"`, `"leasehold"`
- `publishedDate`, `_createdAt`, `_updatedAt`
- `body` — rich-text blocks describing the property
- `gallery.images[]` — `{_key, alt, imageUrl, imageUpload}`
- `floorplan`, `epc` — separate asset objects
- `_id` — Salesforce ID (`a0EP6...` / `a0OP6...` / `a0O8e...`)

## Search and discovery (`/all-homes`, `/past-sales`)

Both index pages embed the same data shape under `props.initialData` and a
curated `props.featuredListings`:

```
props.featuredListings[]    — 6 hand-picked listings, full CMS payload (29 keys, including gallery)
props.initialData
  ├── properties[]          — first 20 results as summary objects (see below)
  ├── resultsCount          — total matching listings (e.g. 171 active, 520 sold)
  ├── nextCursor            — {lastId, lastPrice, lastPublishedDate} for pagination
  ├── locations[]           — {name, slug} of all areas
  ├── propertyTypes[]       — {name, slug} of all types
  ├── priceFrom[]           — allowed price-from values, in £000s
  └── priceTo[]             — allowed price-to values, in £000s
```

A property summary in `initialData.properties[]` has these keys (21 observed):
`id`, `address`, `architect`, `name`, `price` (a formatted string like
`"£550,000"`), `slug` (a bare string, not the `{_type, current}` form), `sold`,
`statuses`, `tenure`, `buildingWithPlanningPermission`, `thumbnail`,
`thumbnailAlt`, `location`, `bedrooms`, `date`, `gallery`, `coords`, `brand`,
`newPrice`, `viewingDay`, `hideMap`. Note: `propertyType` and `location` are
typically null/placeholder in the summary view; the JS client fills them in.

### Important: query-string filters are not enforced server-side

The URL parameters that drive the on-page filters (`?price-from=800`,
`?price-to=2000`, `?locations=london`, `?bedrooms=2`, etc.) **are ignored by the
server**. Every request to `/all-homes` returns the same 20 summaries regardless
of query string; filtering happens entirely in client-side JS. The allowed
parameter *values* for each filter, however, are in `initialData.priceFrom`,
`initialData.priceTo`, `initialData.locations[].slug`,
`initialData.propertyTypes[].slug`.

For agents, this means:

- To enumerate listings, fetch `/all-homes` or `/past-sales` and read
  `initialData.properties`.
- To filter, do it **client-side** against those summaries (price, sold,
  bedrooms, slug, address etc.). Don't trust query strings to subset.

### Pagination is server-action-based and not URL-addressable

The index pages only embed the first 20 results plus a `nextCursor`. The "load
more" button in the UI posts to a Next.js Server Action (no stable public URL;
the action ID is bundled into the JS). There is no `?page=`, `?cursor=`, or
`/page/N` URL pattern that the server honours — tested empirically. So:

- The first 20 + featured (6, overlap possible) are the only listings you can
  get with a single GET to an index page.
- For complete enumeration, use `sitemap.xml` instead — it lists every listing
  URL (see below). Reverse-engineering the Server Action protocol is fragile
  (action IDs change on every deploy) and driving a real browser is heavyweight;
  neither is needed.
- `resultsCount` tells you the total so you at least know what you're missing.

## Sitemap

`https://www.inigo.com/sitemap.xml` (advertised in `robots.txt`, ~240 KB
uncompressed) carries every listing URL Inigo publishes. As of 2026-06-08:

- 520 `<loc>…/past-sales/<slug></loc>` entries (matches the live `resultsCount`
  on `/past-sales`)
- 168 `<loc>…/sales-list/<slug></loc>` entries (matches `resultsCount` on
  `/all-homes`; note the URL section is `sales-list`, not `all-homes`, on detail
  pages)
- ~660 `/almanac/<slug>` entries (editorial content, not listings) and a handful
  of static pages

Each entry is wrapped in
`<url><loc>…</loc><lastmod>YYYY-MM-DDTHH:MM:SSZ</lastmod></url>` with no other
metadata. That makes the sitemap ideal for URL enumeration (archive backfill,
initial pulls) but useless for price/bedrooms/address filtering — those require
fetching each detail page.

`inigo-search sitemap` uses this; `inigo-search website` retains the live
filterable behaviour against the index pages.

## No browser needed

All structured data — gallery JSON on detail pages, `initialData` on index pages
— is server-rendered into the initial HTML. A plain `urllib` GET with a
reasonable `User-Agent` is sufficient. Earlier iterations used headless Chrome
via `url-cat-dom`; that turned out to be unnecessary.

If Inigo ever switches to client-only rendering, parsing scripts will fail with
"could not find …" and a browser path will be needed (`playwright` is the modern
choice).

## Observed image filename patterns

Useful for recognising Inigo-sourced files in mixed directories. All current
listings are served from `cdn.themodernhouse.com`:

- Sequential integers: `1.jpg`, `2.jpg`, … `18.jpg`
- Full URL shape:
  `https://cdn.themodernhouse.com/<orgId>/<listingId>/<hash>/<n>.jpg`
- A second pattern seen on active listings uses Salesforce IDs embedded in the
  path:
  `https://cdn.themodernhouse.com/<orgId>/<hash>/a0OP6XXX_NN_jpg/a0OP6XXX_NN_webres.jpg`

## Verification

If the documentation above stops matching reality, these are known probes to
confirm what changed. **All verified live on 2026-06-07.** Inigo does delist
sold listings over time (e.g. `mare-street` and `woburn-walk` from the local
test data are now gone), so if a specific probe slug returns the soft-404 page
(response is 200 OK with ~48 KB and no `gallery` substring — the real listings
are ~110 KB), pick any current slug from `/past-sales` instead.

- **`https://www.inigo.com/past-sales/cranfield-road`** — sold listing with 18
  gallery images. `inigo-gallery` should print 18 image URLs on the
  `cdn.themodernhouse.com` host.
- **`https://www.inigo.com/past-sales/highgate-west-hill`** — second
  sold-listing probe in case the first is gone.
- **`https://www.inigo.com/past-sales`** — index page. Should embed
  `initialData` with `resultsCount` in the hundreds and at least the
  `cranfield-road` and `highgate-west-hill` slugs reachable somewhere in the
  catalogue.
- **`https://www.inigo.com/all-homes`** — active-listings index. Should embed
  `initialData` with `priceFrom`, `priceTo`, `locations` (8 entries:
  east-anglia, london, midlands, north-england, scotland, south-east-england,
  south-west-england, wales), and `propertyTypes` (2 entries: house, flat).

Soft-404 detection: missing listing URLs (`/past-sales/<bad-slug>` or
`/sales-list/<bad-slug>`) return **HTTP 200** with a ~48 KB page that has no
`gallery` substring. Don't trust status codes alone — check for the data shape.

If the URL paths themselves change (e.g. `/sales-list/<slug>` starts returning a
real 404), grep an index page for the slug of a known property — Inigo's slugs
are stable, so the surrounding URL path tells you the new convention.

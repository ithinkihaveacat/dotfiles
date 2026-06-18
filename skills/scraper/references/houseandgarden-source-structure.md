# House & Garden source structure

What's documented here is specific to houseandgarden.co.uk and was discovered
by inspection.

**Captured:** 2026-06-17. The site structure could change; see
[Verification](#verification) for known-stable probes.

## No browser needed

Plain `urllib` with a realistic `User-Agent` and `Accept` headers returns full
HTML (HTTP 200). The page is ~900KB–1MB. No Cloudflare, no bot management on
article pages.

## URL surface

| Purpose            | URL pattern                                 | Example                                                                    |
| ------------------ | ------------------------------------------- | -------------------------------------------------------------------------- |
| Topic index        | `/topic/<slug>`                             | `https://www.houseandgarden.co.uk/topic/london-houses`                     |
| Topic index page N | `/topic/<slug>?page=N`                      | `https://www.houseandgarden.co.uk/topic/london-houses?page=2`              |
| Gallery article    | `/gallery/<slug>`                           | `https://www.houseandgarden.co.uk/gallery/chelsea-townhouse-reimagined-by-lonika-chande` |
| Article (text)     | `/article/<slug>`                           | `https://www.houseandgarden.co.uk/article/nomad-designs-chelsea-house`     |

Topics contain both `/gallery/` and `/article/` URLs — the gallery script only
processes `/gallery/` pages (which have the slideshow format). `/article/` pages
are text-only and don't have gallery slides.

## Topic index pages (`/topic/<slug>`)

Each page embeds a JSON-LD `ItemList` block:

```json
{
  "@type": "ItemList",
  "itemListElement": [
    {"@type": "ListItem", "name": "Title…", "url": "https://…", "position": 1},
    …
  ]
}
```

20 items per page (last page may have fewer). Pagination is `?page=N` — returns
HTTP 404 once N exceeds the last page. Page 1 has no `?page=1` parameter.
The `<link rel="next">` header and a "More Stories" button in the body confirm
the next page URL.

The `london-houses` topic has 21 pages / 418 articles as of 2026-06-17.

## Gallery article pages (`/gallery/<slug>`)

### Metadata — NewsArticle JSON-LD

The first `<script type="application/ld+json">` block is a `NewsArticle` with:

| Field            | Contents                                                    |
| ---------------- | ----------------------------------------------------------- |
| `headline`       | Article title                                               |
| `author[]`       | Array of `{@type: "Person", name: "…", sameAs: "…"}` |
| `datePublished`  | ISO 8601 datetime                                           |
| `articleSection` | e.g. `"houses"`                                             |
| `articleBody`    | Intro text; contains `[#image: /photos/…]` markers (strip) |

Tags come from the `<meta name="keywords" content="…">` element, comma-separated.

### Gallery slides

Gallery slide images are identified by their **`/master/` image transform** — the
full, uncropped rendition each carousel slide uses:

```html
<picture …><source srcSet="…/photos/<24-hex-id>/master/w_1024%2Cc_limit/<filename>.jpg …"><img … src="…/photos/<24-hex-id>/master/w_2560,c_limit/<filename>.jpg" …></picture>
```

Collect every distinct 24-hex photo id appearing under `/master/`, in document
order, and normalise the width to `w_2560,c_limit` for the largest rendition.
The same id recurs many times per slide (one per `srcSet` width, across
`<source>` and `<img>`), so dedupe by id. Widths carry a literal or
`%2C`-encoded comma — match both.

> **Do not key on `GallerySlideWrapper`.** H&G serves two page templates: a newer
> one renders each slide inline next to its wrapper, but an older one (the
> majority of the sampled `london-houses` articles) renders most slides far from
> any wrapper marker. The previous scraper scanned a fixed window after each
> `GallerySlideWrapper` and so silently truncated old-template galleries to the
> first ~4–6 slides. The `/master/` transform is template-independent.

**Recirculation / social crops are excluded for free.** "Related"/"more from"
cards and social-card images are *also* `media.houseandgarden.co.uk/photos/…`
URLs, but they use fixed-aspect transforms (`1:1`, `16:9`, …), never `/master/`.
The one image this drops is a lead/cover shot rendered solely as a `16:9` social
crop (not a carousel slide).

**Captions** come from `data-item="…"` attributes — HTML-entity-encoded JSON:

```html
<div … data-item="{&quot;id&quot;:&quot;<24-hex-id>&quot;,&quot;image&quot;:{&quot;caption&quot;:&quot;…&quot;,&quot;credit&quot;:&quot;…&quot;,…}}">
```

The `id` field matches the photo id in the slide URL, pairing caption to image.
Parse with `html.unescape()` then `json.loads()`. The regex `data-item="(\{[^"]*)"`
extracts the attribute reliably (inner quotes are `&quot;`, never literal `"`).
This manifest is partial — it covers only some slides — so it is used for
captions only, never as the image list.

**Count:** typically ~8–35 slides per article, captured in full.

### Image CDN

All images are on `media.houseandgarden.co.uk`. URL shape:

```
https://media.houseandgarden.co.uk/photos/<24-hex-id>/<ratio>/w_<N>,c_limit/<filename>
```

| Segment     | Examples                     | Notes                                |
| ----------- | ---------------------------- | ------------------------------------ |
| `<24-hex>`  | `6668190bb069c7d83c09d1f1`   | MongoDB-style ObjectId               |
| `<ratio>`   | `master`, `16:9`, `1:1`      | `master` preserves original crop     |
| `w_<N>`     | `w_1024`, `w_2560`           | Max width; use `2560` for high-res   |
| `c_limit`   | literal                      | Don't crop; preserve aspect ratio    |
| `<filename>` | `230606_LonikaChande2096_014_HiRes.jpg` | As-shot filename |

The ratio is not meaningful for `master` (it's the native crop). Use `master` +
`w_2560` as the canonical download URL.

## `window.__PRELOADED_STATE__`

A large (500KB+) JSON blob is embedded under `window.__PRELOADED_STATE__`. It
contains component config and rendition breakpoint tables but **not** the
article content or gallery images — those come from the JSON-LD and DOM structure
above. Do not parse this for image extraction.

## Verification

Both verified live on 2026-06-17:

- **`https://www.houseandgarden.co.uk/topic/london-houses`** — should return an
  ItemList JSON-LD with 20 items; `<link rel="next">` pointing to `?page=2`.
- **`https://www.houseandgarden.co.uk/gallery/chelsea-townhouse-reimagined-by-lonika-chande`**
  — should return a NewsArticle JSON-LD with `headline` containing "Chelsea
  townhouse" and ~13 distinct `/master/` photo ids (the gallery slides).

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

Slides are identified by `GallerySlideWrapper` in the HTML. Each article has
roughly 2× as many `GallerySlideWrapper` occurrences as images — alternate
wrappers are navigational/caption metadata elements without `<img>` tags.

**Image slides** contain:

```html
<picture …><img … src="https://media.houseandgarden.co.uk/photos/<24-hex-id>/master/w_1024%2Cc_limit/<filename>.jpg" …></picture>
```

The URL uses URL-encoded commas (`%2C`). Replace `w_1024%2Cc_limit` (or any
`w_N,c_limit`) with `w_2560,c_limit` for the largest available rendition.
`master` preserves the original image aspect ratio.

**Caption slides** contain a `data-item="…"` attribute with HTML-entity-encoded
JSON:

```html
<div … data-item="{&quot;id&quot;:&quot;<24-hex-id>&quot;,&quot;image&quot;:{&quot;caption&quot;:&quot;…&quot;,&quot;credit&quot;:&quot;…&quot;,…}}">
```

The photo ID (`id` field) matches the 24-hex segment in the image slide's URL,
allowing caption–image pairing. Parse with `html.unescape()` then `json.loads()`.
The regex `data-item="(\{[^"]*)"` extracts the attribute value reliably (the
attribute content uses `&quot;` for inner quotes, never literal `"`).

**Count:** The metered paywall restricts some slides from rendering `<img>` tags.
Unauthenticated access typically yields 8–18 images per article.

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
  townhouse" and at least 8 `GallerySlideWrapper` elements with `<img>` tags.

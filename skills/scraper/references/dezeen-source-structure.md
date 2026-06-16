# Dezeen source structure

What's documented here is specific to dezeen.com and was discovered by
inspection. It is the Dezeen counterpart to the Inigo source-structure notes
that ship with the `scraper` skill.

**Captured:** 2026-06-15. Dezeen's site changes — if anything below stops
matching reality, see [Verification](#verification) for known-stable URLs to
probe.

## URL surface

Dezeen is a WordPress site. Two URL shapes matter for scraping:

| Purpose          | URL pattern                 | Example                                                         |
| ---------------- | --------------------------- | --------------------------------------------------------------- |
| Tag index        | `/tag/<tag-slug>/`          | `https://www.dezeen.com/tag/london-extensions/`                 |
| Tag index page N | `/tag/<tag-slug>/page/<n>/` | `https://www.dezeen.com/tag/london-extensions/page/2/`          |
| Article detail   | `/<yyyy>/<mm>/<dd>/<slug>/` | `https://www.dezeen.com/2026/05/18/house-of-em-loggia-house-…/` |

The article **slug** (last path segment) is the stable key, mirroring the role
the Inigo slug plays. Articles are dated; the date prefix is part of the URL but
not needed once you have the slug.

## Cloudflare

Dezeen is fronted by Cloudflare bot management, which materially shapes how it
must be scraped. The decisive factor is **automation detection, not the HTTP
client**:

- **`curl` and `urllib` behave identically** — both get 200 on edge-cached URLs
  (homepage, tag page 1) and **403** on everything uncached (deeper tag pages,
  every article detail page), regardless of headers. An earlier theory that
  `urllib`'s TLS fingerprint was specifically blocked did not hold up under
  testing; swapping client makes no difference.
- **A headless / automation-launched browser is worse, not better.** A Chrome
  driven by Puppeteer/CDP sets `navigator.webdriver = true`, which Cloudflare
  Turnstile reads directly: the challenge then loops forever and can never be
  solved (Google and YouTube reject the same browser for the same reason).
- **What works is driving a real Chrome you launch yourself** with
  `--remote-debugging-port` and *no* automation flags, so `navigator.webdriver`
  is `false`. Connect to it over CDP (the scripts use Playwright's
  `connect_over_cdp`) and read the rendered DOM. To Cloudflare this is an
  ordinary human browser: tag pages 2+ and article detail pages all load
  cleanly, with no throttling observed across sustained sequential scraping.
- **If a managed challenge does appear**, it is solvable by a human clicking it
  once in that window; the resulting `cf_clearance` cookie then covers the rest
  of the session. The scripts detect the interstitial by title and wait for it
  to clear rather than failing.
- The WordPress REST API (`/wp-json/wp/v2/...`) is behind a full Cloudflare
  interstitial challenge and is **not usable** for scraping.

The images themselves are exempt: `static.dezeen.com` is a plain CDN with no bot
management, so `wget`/`urllib` download them directly — the browser is only
needed for the HTML pages.

## Tag index pages

Server-rendered HTML (no JS needed). Each result is an
`<article data-article-id="…">` block containing:

- the article URL, in an
  `<h3><a href="https://www.dezeen.com/yyyy/mm/dd/slug/">`
- the title (the `<h3>` link text)
- a thumbnail `<img src="https://static.dezeen.com/uploads/…">`
- the author, in an `<a rel="author">…</a>`
- the publish date, in `<time datetime="YYYY-MM-DD HH:MM">`
- a short excerpt, in the first `<p>` of the block

### Pagination

`/tag/<slug>/page/<n>/`. Important quirk: the numbered pager rendered on page 1
**under-reports** the total (it showed a max of 5 while page 6 still returned 20
articles). So do not trust the on-page pager — walk pages incrementally until a
page returns **HTTP 404** (out-of-range) or contains no `<article>` blocks.
Article URLs can repeat across pages, so de-duplicate.

`scripts/dezeen-search` implements this walk.

## Article detail pages

### Metadata: JSON-LD

The reliable metadata source is the `NewsArticle` JSON-LD block (a
`<script type="application/ld+json">`; sometimes the relevant object is nested
in an `@graph` array). Fields used:

- `headline`, `description`
- `author` (array of `{name}`) / `creator` (array of strings)
- `datePublished`, `dateModified`
- `articleSection` (e.g. `"Architecture"`)
- `keywords` (array of tag strings, e.g. `"london houses"`, `"uk"`)

### Gallery images

The genuine gallery images are the **only** ones carrying a `data-lightboximage`
attribute on their `<figure class="wp-caption …">`:

```
<figure … data-lightboximage="https://static.dezeen.com/uploads/…/img.jpg">
  <img class="wp-image-NNNN size-full" src="…">
  <… class="wp-caption-text">Caption text</…>
</figure>
```

Related-post thumbnails, hero/social squares and sidebar images do **not** have
`data-lightboximage`, so keying on that attribute cleanly excludes the noise.
`data-lightboximage` points at the full-resolution upload (some are WordPress
`-scaled.jpg` variants). Captions, when present, are in the `wp-caption-text`
element inside the same figure. Floorplans appear as gallery figures too.

CDN host: `static.dezeen.com/uploads/<yyyy>/<mm>/<filename>`. Filenames are
descriptive (e.g. `loggia-house-…_dezeen_2364_col_0.jpg`), not sequential
integers as on Inigo's CDN.

### Body text

Best-effort only. Prose `<p>` paragraphs precede the
`<div class="article-tags">` block; figure captions (`wp-caption-text`) and
related-post blurbs after the tags are excluded. The JSON-LD `description` is
the dependable one-line summary; the extracted `body` is a convenience.

## `listing.json` shape (`dezeen-gallery --json`)

```
{
  "slug":          "<article slug>",
  "url":           "<article URL>",
  "title":         "<headline>",
  "author":        ["<name>", …],
  "datePublished": "<ISO 8601>",
  "dateModified":  "<ISO 8601>",
  "description":   "<one-line summary>",
  "section":       "Architecture",
  "tags":          ["…", …],
  "body":          "<plain-text prose>",
  "gallery": { "images": [ { "imageUrl": "…", "caption": "… | null" }, … ] }
}
```

`gallery.images[].imageUrl` deliberately matches Inigo's key so the
metadata-first download pattern (fetch JSON, filter, then pull image URLs from
the same payload) transfers directly.

## Verification

Known probes, all confirmed live on 2026-06-15:

- **`https://www.dezeen.com/tag/london-extensions/`** — tag index. Should embed
  `<article data-article-id=…>` blocks (~20) and a `…/page/2/` link.
  `dezeen-search london-extensions --limit 5` should print 5 article URLs.
- **`https://www.dezeen.com/tag/london-extensions/page/99/`** — out-of-range
  page. Returns **HTTP 404** (the pagination-stop signal).
- **`https://www.dezeen.com/2026/05/18/house-of-em-loggia-house-north-london/`**
  — article detail page with 12 gallery images (10 photos + 2 floorplans).
  `dezeen-gallery <url>` should print 12 `static.dezeen.com` URLs (with a
  debuggable Chrome running; see Cloudflare above).

If `dezeen-search` returns no articles, the tag may have been renamed or the
`<article>` markup changed — fetch the tag page and re-grep for the article link
pattern. If `dezeen-gallery` reports "could not find gallery images" on a page
that clearly has them, check whether the `data-lightboximage` attribute is still
present (Dezeen could switch its lightbox implementation).

# Travel Booking Guides — Meta Reference

Standards, goals, and editorial principles for travel redemption and booking reference guides. Applicable to any mode of travel where pricing is complex, non-transparent, or varies significantly by timing, loyalty programme, or booking method — airlines, cruises, rail passes, hotels, ferries, etc.

These guides are written for readers who already understand how loyalty programmes, redemption pricing, and travel booking work in general. What they document is the specific, non-obvious operational detail that can only be established through direct investigation: which tools actually work, which URL structures exist, what was tested and found not to work, and what the real costs are on real routes after fees. General travel knowledge — that surcharges change, that booking windows matter, that peak pricing exists — is assumed and not restated.

---

## Design Goals

These guides try to do things that official airline/operator sites and generic blog posts don't:

- **Pre-calculate the maths.** Show the points/miles/currency cost *and* the cash component (taxes, fees, surcharges, booking fees) together, so the reader can assess total cost without juggling multiple sources. Where possible, include worked examples for real routes or sailings with approximate figures.
- **Document the booking workflow, not just the facts.** Explain which tool to use, in what order, and with what inputs — especially where a multi-step process can be shortened. If a particular search flow consistently surfaces better availability or lower prices, describe it.
- **Explicitly document dead ends.** If no shortcut exists (despite testing), say so. This prevents readers from attempting the same fruitless search. See [Dead End Documentation](#dead-end-documentation) below.
- **Annotate access requirements per tool.** Each booking or search tool should be tagged to indicate whether an account, login, or membership is required. Readers may be planning searches from a work device, a shared computer, or a region-locked browser.
- **Timestamp technical findings.** Websites, booking flows, and URL structures change. Any specific finding about how a tool behaves should note when it was verified.
- **Link to primary sources.** Where a fact comes from an official page or a credible third-party source, link it directly so verification is one click, not a search.

---

## Content Standards

### Volatility tiers — how often to re-check

Different types of information change at different rates. When writing or updating a guide, note the tier of each key fact so readers know how much to trust it.

| Tier | Type | Typical change frequency | Examples |
|------|------|--------------------------|---------|
| **High** | Prices, surcharges, fees | Months or less | Airline carrier surcharges; cruise fuel supplements; dynamic pricing floors |
| **High** | Promotional offers | Weeks to months | Sign-up bonuses; transfer bonuses; limited-time fare sales |
| **Medium** | Award chart / redemption values | 6–24 months (usually announced) | Airline miles charts; loyalty point valuations; hotel category assignments |
| **Medium** | Booking tool behaviour | Varies; tied to site rebuilds | URL parameters; login gates; search form layout |
| **Low** | Programme structure | Years | Earning rates; tier thresholds; partner relationships |
| **Annual** | Seasonal pricing calendars | Issued annually | Peak/off-peak date lists; cruise season pricing bands |

When writing a fact in a guide, indicate the tier inline if the reader needs to know it's perishable — e.g. "as of [month year]" or a footnote.

### Pre-calculation format

Where the value of a booking depends on combining multiple cost components, the guide should show the full picture. A pre-calculated entry should include:

1. **The "currency" cost** — points, miles, or the programme's unit
2. **The cash component** — taxes, fees, surcharges, or booking charges (note the date these were observed, as they change)
3. **Total cost in cash-equivalent terms** — e.g. at an assumed valuation of X per point
4. **A comparison point** — what the equivalent cash booking would cost (or the best cash alternative)
5. **Caveats** — whether the figure is peak or off-peak, a specific date, or route-dependent

*Example structure (airline Business class redemption):*
> LHR → JFK off-peak: 50,000 Avios + ~£250 taxes/surcharges per person (observed Oct 2025). Cash equivalent ~£2,000–3,000 one-way. Avios value implied: ~3.5–5.5p/point.

*Example structure (cruise loyalty redemption):*
> Caribbean 7-night, inside cabin: 35,000 points + ~$200 port fees (observed Jan 2026). Cash brochure rate: $1,100. Discount offered vs brochure: ~$950. Points implied value: ~2.7¢/point.

### Access requirement annotations

Each tool or resource referenced should carry a clear annotation:

- 🔓 **No account required** — accessible without login or membership
- 🔒 **Account/login required** — must be signed in to access or see full results
- 🌐 **Region-restricted** — may behave differently or be unavailable outside certain countries
- 📞 **Phone only** — no online equivalent; must call

If a tool shows different information depending on whether you're logged in (e.g. availability visible without login but pricing only visible when signed in), document both states separately.

---

## Dead End Documentation

When a shortcut, URL parameter, or workflow has been searched for and found not to exist, document it explicitly. This is as valuable as documenting what *does* work.

**Format for a dead-end note:**

> ⚠️ **[What was tested]**: [specific parameter, URL, or flow attempted] — [result]. [Date tested]. [What to do instead.]

**Examples:**

> ⚠️ **BA booking search — URL deep-link parameters**: Results URL always returns as a bare path with no query string regardless of search inputs — pure server-side session state. Not bookmarkable or shareable. Verified June 2026. No workaround exists; every session must start from the search form.

> ⚠️ **`redemption_type=2_4_1` URL parameter**: Tested June 2026 — no effect on the BA booking form. Same blank form appears as with the standard parameter. There is no URL shortcut for companion voucher searches.

> ⚠️ **Cruise availability calendar deep-link**: [Operator] booking portal does not support pre-filled cabin type or sailing date via URL. The search form always loads blank. Tested [date].

The goal is not to be exhaustive, but to document dead ends that were actively investigated in response to a plausible question, so future readers don't repeat the attempt.

---

## Verification Checklist Template

When creating or updating a guide, work through a checklist specific to the programme or operator. Below is a template — copy and adapt for each guide.

- [ ] **Core pricing / redemption chart** — verified against official source; date noted
- [ ] **Fees and surcharges** — tested against a live search or booking; date noted
- [ ] **Current promotional offers** (sign-up bonuses, transfer bonuses, etc.) — verified; date noted
- [ ] **Seasonal calendar** (peak/off-peak dates, sailing seasons, etc.) — current year confirmed
- [ ] **Login/access requirements** — tested in an incognito/logged-out browser; results documented
- [ ] **URL parameters and booking flow** — tested; deep-link support or absence confirmed
- [ ] **Third-party tool availability** — tools still operational; limitations noted
- [ ] **Partner/alliance coverage** — no partner relationships have changed since last update
- [ ] **Dead ends still accurate** — shortcuts that didn't exist previously still don't exist

---

## Source Standards

For each guide, maintain a sources table covering:

| Column | What to include |
|--------|----------------|
| **Source** | Name and direct link |
| **Authoritative for** | What specific facts this source is the best reference for |
| **Reliability** | Official (operator-published) / reputable third-party / community |
| **Check frequency** | How often to revisit given the volatility of the content it covers |

Prefer official operator sources for pricing and chart data. Prefer specialist third-party sources (e.g. points/miles blogs, cruise forums) for tactics, workarounds, and surcharge tracking — these are often more current than official pages on operational details.

---

*Template written June 2026.*

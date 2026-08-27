---
name: travel
description: >-
  Technical references, pre-calculated points-plus-cash costs, and booking workflows
  for airline loyalty redemptions and booking URL engineering. Covers British Airways
  Executive Club Avios (UK-origin), Qantas Frequent Flyer and Amex Membership Rewards
  (Australia-origin), and Finnair deep-link JSON URL construction. Use when planning
  or pricing award flight redemptions, comparing carrier surcharges, checking reward
  availability, or generating Finnair booking URLs.
---

# Travel Booking

This skill provides practical, field-tested references for redeeming airline
loyalty points and constructing direct booking URLs. The redemption guides
pre-calculate points-plus-cash costs, document actual booking workflows and
search tools, and record verified dead ends so they are not repeated.

## Reward Flight Redemption Guides

- **[British Airways Avios](references/ba.md)** — UK-origin redemptions: BA
  Executive Club Avios (earned via Amex Premium Plus Card), Companion Voucher
  mechanics, Avios group transfer partners (Qatar, Iberia, Finnair), award
  charts, carrier surcharge comparisons, key routes from London, and
  availability tools.
- **[Qantas Points & Amex MR](references/qantas.md)** — Australia-origin
  redemptions: Qantas Frequent Flyer points (via Amex Membership Rewards),
  Classic vs. Classic Plus vs. Upgrade rewards, the Australia–UK route, carrier
  charges, and the Flight Reward Finder.

> [!TIP] **Round-Trip Strategy:** For a round trip between the UK and Australia,
> compare booking each one-way leg separately through the cheaper programme
> (e.g., BA Avios outbound from London, Qantas Points outbound from Australia)
> to minimize carrier surcharges.

## Finnair Booking URL Engineering

To construct direct booking URLs for Finnair deep-linking to the fare selection
screen:

```text
https://www.finnair.com/gb-en/booking/flight-selection?json=<URL-encoded JSON>
```

### JSON Structure & Quick Example

```json
{
  "flights": [
    {
      "origin": "LON",
      "destination": "HEL",
      "departureDate": "2026-12-19"
    },
    {
      "origin": "HEL",
      "destination": "MEL",
      "departureDate": "2026-12-26"
    }
  ],
  "cabin": "ECOPREMIUM",
  "adults": 1,
  "c15s": 0,
  "children": 0,
  "infants": 0
}
```

### Critical Quirks & Gotchas

- **Cabin Parameter:** Valid values are `ECONOMY`, `ECOPREMIUM`, and `BUSINESS`.
  Using `PREMIUM_ECONOMY` or `PREMIUM` results in a silent redirect to the
  homepage.
- **Passenger Age Banding (`c15s`):** Finnair uses its own age category for
  young passengers aged 12–15 (`c15s`), distinct from `adults` (16+) and
  `children` (2–11).
- **Cold-Start Access:** The URL works from a cold start with no session, login,
  or cookies required.

## Reference Material

- **[British Airways Avios Reference](references/ba.md)** — UK-origin points
  pricing, companion vouchers, partner redemptions, and surcharges.
- **[Qantas Points & Amex MR Reference](references/qantas.md)** —
  Australia-origin points pricing, reward tiers, and carrier fees.
- **[Finnair Booking URL Reference](references/finnair.md)** — Full JSON
  parameter spec, encoding rules, multi-city examples, and code snippets.
- **[Travel Booking Meta Reference](references/guide-meta.md)** — Shared
  standards for volatility tiers, pre-calculations, access levels, and dead-end
  documentation.

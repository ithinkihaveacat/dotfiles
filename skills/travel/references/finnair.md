# Finnair: Booking URL Engineering Reference

A practical reference for constructing direct Finnair booking URLs —
deep-linking to the fare-selection screen with custom segments, cabin classes,
and passenger counts by percent-encoding a JSON payload.

Unlike the BA Avios and Qantas Points guides in this skill, this reference is
deliberately narrow: it documents Finnair's booking-URL mechanics only. This
document provides the URL structure, worked examples, and code rather than
exhaustive tables.

______________________________________________________________________

## Coverage

This reference follows the shared guide pattern, but Finnair booking-URL
engineering is its only subject. The standard guide sections are listed here for
consistency; most are out of scope and not collected in this skill.

| Standard guide section              | In this reference                                                                                          |
| ----------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| Earning / transfer partners         | Not provided — Finnair Plus is an Avios group member; see the [BA Avios guide](./ba.md)                    |
| Reward types                        | Not provided                                                                                               |
| Award chart / points pricing        | Not provided                                                                                               |
| Carrier surcharges                  | Not provided — the [BA](./ba.md) and [Qantas](./qantas.md) guides note Finnair's low-to-no carrier charges |
| Key routes                          | Not provided                                                                                               |
| Technical: booking URL construction | **Covered in full below**                                                                                  |

______________________________________________________________________

## Base URL

```
https://www.finnair.com/gb-en/booking/flight-selection?json=<URL-encoded JSON>
```

> 🔓 **No login required** — the URL works from a cold start with no Finnair
> session, cookie, or prior homepage visit (see
> [Quirks](#no-sessioncookie-required)).

The locale segment (`gb-en`) can be changed for other markets (e.g. `fi-fi`,
`us-en`), but prices and availability may differ. Use `gb-en` for GBP pricing.

______________________________________________________________________

## JSON Parameter Structure

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
    },
    {
      "origin": "MEL",
      "destination": "LHR",
      "departureDate": "2027-01-08"
    }
  ],
  "cabin": "ECONOMY",
  "adults": 3,
  "c15s": 0,
  "children": 0,
  "infants": 0
}
```

The entire JSON object must be URL-encoded and passed as the `json=` query
parameter.

______________________________________________________________________

## Fields

### `flights` (array, required)

Each entry is a flight leg. Supports 1–N legs (one-way, return, or multi-city).

| Field           | Type   | Format                    | Notes                                        |
| --------------- | ------ | ------------------------- | -------------------------------------------- |
| `origin`        | string | IATA airport or city code | City codes (e.g. `LON`) include all airports |
| `destination`   | string | IATA airport or city code | Same as above                                |
| `departureDate` | string | `YYYY-MM-DD`              | Exact departure date for that leg            |

### `cabin` (string, required)

**Critical:** only the following values are valid. Any other value silently
redirects to the Finnair homepage with no error.

| Value        | Cabin           |
| ------------ | --------------- |
| `ECONOMY`    | Economy         |
| `ECOPREMIUM` | Premium Economy |
| `BUSINESS`   | Business        |

> **Quirk:** `PREMIUM_ECONOMY` and `PREMIUM` look reasonable but both redirect
> to the homepage. The correct value for Premium Economy is `ECOPREMIUM`. This
> can be confirmed by using the search form on the Finnair homepage and
> inspecting the resulting URL — it will contain `"cabin":"ECOPREMIUM"`.

### Passenger counts (integers, required — use 0 if none)

| Field      | Meaning                                        |
| ---------- | ---------------------------------------------- |
| `adults`   | Adults (16+ in Finnair's banding)              |
| `c15s`     | Young passengers aged 12–15 (Finnair-specific) |
| `children` | Children aged 2–11                             |
| `infants`  | Infants aged 0–2                               |

> **Why `c15s` exists — and why it looks "wrong" if you assume Oneworld
> defaults.** Finnair uses its **own** passenger age-banding in its booking
> engine, which is *not* the generic IATA/Oneworld convention. Under the common
> Oneworld/airline-API model, a passenger aged 2–11 is a "child" and **anyone 12
> or older is treated as an adult** for fare and ticketing purposes — so a
> reviewer applying that rule will flag `c15s` as a mistake. It isn't: Finnair
> carves out **12–15-year-olds as a distinct booking category** (`c15s`),
> separate from both `adults` and `children`, even though they are generally
> charged adult-level fares. Finnair's own pages treat 12–15 as a special group
> (e.g. the
> [unaccompanied-minor service covers 12–17](https://www.finnair.com/us-en/special-assistance-and-health/children-travelling-alone-and-young-travellers),
> and its FAQ notes a
> [15-year-old is booked outside the standard child fare](https://www.finnair.com/en/frequently-asked-questions/bookings-and-payments/my-child-is-15-years-of-age--can-i-book-him-an-adult-ticket--1890474)).
>
> **Verified against the live booking engine (June 2026):** loading the booking
> URL with `"c15s":2` makes Finnair's fare-selection screen render the journey
> for **"1 adult, 2 children"** — i.e. the field is parsed as a real, distinct
> passenger type, not ignored. If `c15s` were not a genuine Finnair parameter it
> would have no effect on the passenger summary. Do **not** "normalise" `c15s`
> into `adults`/`children` to match Oneworld conventions — that would break the
> URL's correspondence with Finnair's own system.

______________________________________________________________________

## Full Worked Examples

### One-way, Economy, 1 adult

```
https://www.finnair.com/gb-en/booking/flight-selection?json=%7B%22flights%22%3A%5B%7B%22origin%22%3A%22HEL%22%2C%22destination%22%3A%22MEL%22%2C%22departureDate%22%3A%222026-12-26%22%7D%5D%2C%22cabin%22%3A%22ECONOMY%22%2C%22adults%22%3A1%2C%22c15s%22%3A0%2C%22children%22%3A0%2C%22infants%22%3A0%7D
```

Decoded JSON:

```json
{"flights":[{"origin":"HEL","destination":"MEL","departureDate":"2026-12-26"}],"cabin":"ECONOMY","adults":1,"c15s":0,"children":0,"infants":0}
```

### Multi-city, Premium Economy, 3 adults

```
https://www.finnair.com/gb-en/booking/flight-selection?json=%7B%22flights%22%3A%5B%7B%22origin%22%3A%22LON%22%2C%22destination%22%3A%22HEL%22%2C%22departureDate%22%3A%222026-12-19%22%7D%2C%7B%22origin%22%3A%22HEL%22%2C%22destination%22%3A%22MEL%22%2C%22departureDate%22%3A%222026-12-26%22%7D%2C%7B%22origin%22%3A%22MEL%22%2C%22destination%22%3A%22LHR%22%2C%22departureDate%22%3A%222027-01-08%22%7D%5D%2C%22cabin%22%3A%22ECOPREMIUM%22%2C%22adults%22%3A3%2C%22c15s%22%3A0%2C%22children%22%3A0%2C%22infants%22%3A0%7D
```

Decoded JSON:

```json
{"flights":[{"origin":"LON","destination":"HEL","departureDate":"2026-12-19"},{"origin":"HEL","destination":"MEL","departureDate":"2026-12-26"},{"origin":"MEL","destination":"LHR","departureDate":"2027-01-08"}],"cabin":"ECOPREMIUM","adults":3,"c15s":0,"children":0,"infants":0}
```

______________________________________________________________________

## What the URL Does

Navigating directly to this URL lands you at the **fare class selection screen**
(Economy / Premium Economy / Business and their sub-types: Light, Classic,
Flex). From there the booking flow is:

1. **Select travel class** — choose fare sub-type (Light / Classic / Flex)
1. **Select flight per leg** — one screen per leg, showing all available flights
   with price deltas
1. Passengers → Seats → Baggage → Travel extras → Checkout

Prices shown on the fare class screen are the **total for all passengers for the
entire multi-city journey** in GBP.

______________________________________________________________________

## Quirks and Gotchas

### No session/cookie required

The URL works from a cold start with no prior Finnair session. No login, no
cookie, no prior homepage visit needed. Paste it directly into any browser or
automation tool.

### Cabin value must match route availability

Requesting a cabin that isn't operated on the route (e.g. Business on a short
domestic leg) may still load but show no results, or may default to the next
available class. Always verify results loaded the intended cabin by checking the
heading on the fare selection screen.

### Premium Economy is `ECOPREMIUM`, not `PREMIUM_ECONOMY`

This is the single biggest footgun. The Finnair UI labels the cabin "Premium
Economy" but the internal parameter is `ECOPREMIUM`. Wrong values redirect
silently to the homepage — there is no error message.

### Technical stops vs connections

Some Finnair long-haul flights (e.g. HEL–MEL as AY146) include a **technical
stop** at an intermediate airport (Bangkok/BKK). This is not a separate bookable
leg — it's one continuous flight on the same aircraft. It will appear as a "1
stop" itinerary but cannot be split for partial-cabin upgrades. The booking
system treats the entire flight as a single segment.

### Cabin applies to all legs

The `cabin` parameter sets the cabin class for the **entire journey**. There is
no URL mechanism to mix cabin classes across legs (e.g. Economy outbound,
Business return). Mixed-cabin pricing is not supported through this URL format.

### City codes vs airport codes

`LON` (city code) matches all London airports (LHR, LGW, STN, etc.) and will
offer flights from any of them. Use a specific IATA airport code (e.g. `LHR`) to
restrict to one terminal. Both work in the URL.

### Price deltas on the flight selection screen

After selecting a fare class, each alternative flight on a given leg shows a
**price delta** (e.g. `+£561.90`) relative to the cheapest option for that leg.
The total price shown in the header reflects the sum of all selected legs. The
cheapest option shows `+£0.00`.

### Authority approval warning

Some routes (notably Finnair flights via Thai airspace, including HEL–MEL) may
display: *"Ticket sales for this route are awaiting final approval from local
authorities."* This is a legal disclaimer; the ticket can still be purchased and
a full refund is offered if approval is not ultimately granted.

______________________________________________________________________

## URL Encoding Notes

The JSON must be percent-encoded. Key characters:

| Character | Encoded |
| --------- | ------- |
| `{`       | `%7B`   |
| `}`       | `%7D`   |
| `[`       | `%5B`   |
| `]`       | `%5D`   |
| `"`       | `%22`   |
| `:`       | `%3A`   |
| `,`       | `%2C`   |

Most languages have built-in URL encoding. Examples:

**Python:**

```python
import urllib.parse, json

params = {
    "flights": [
        {"origin": "LON", "destination": "HEL", "departureDate": "2026-12-19"},
        {"origin": "HEL", "destination": "MEL", "departureDate": "2026-12-26"},
        {"origin": "MEL", "destination": "LHR", "departureDate": "2027-01-08"},
    ],
    "cabin": "ECOPREMIUM",
    "adults": 3,
    "c15s": 0,
    "children": 0,
    "infants": 0,
}
url = "https://www.finnair.com/gb-en/booking/flight-selection?json=" + urllib.parse.quote(json.dumps(params, separators=(',', ':')))
```

**JavaScript:**

```javascript
const params = {
  flights: [
    { origin: "LON", destination: "HEL", departureDate: "2026-12-19" },
    { origin: "HEL", destination: "MEL", departureDate: "2026-12-26" },
    { origin: "MEL", destination: "LHR", departureDate: "2027-01-08" },
  ],
  cabin: "ECOPREMIUM",
  adults: 3,
  c15s: 0,
  children: 0,
  infants: 0,
};
const url = `https://www.finnair.com/gb-en/booking/flight-selection?json=${encodeURIComponent(JSON.stringify(params))}`;
```

______________________________________________________________________

## Resources

### Official Finnair

- [Finnair booking flow](https://www.finnair.com/gb-en/booking/flight-selection)
  — Live booking page targeted by the URLs in this reference

### Related guides

- [BA Avios Flight Redemption Reference](./ba.md) — Finnair as an Avios group
  member and oneworld partner (UK-origin redemptions)
- [Qantas Points & Amex MR Flight Redemption Reference](./qantas.md) — Finnair
  as a Qantas partner (Australia-origin redemptions)

### Editorial standard

- [Travel Booking Guides — Meta Reference](./guide-meta.md) — Shared standards
  for the guides in this skill

______________________________________________________________________

*Guide compiled June 2026. Finnair's booking-URL structure may change with site
rebuilds; URL behaviour verified June 2026.*

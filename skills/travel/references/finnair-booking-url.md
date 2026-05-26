# Finnair Multi-City Booking URL Reference

This document provides a technical guide for constructing and using Finnair's
multi-city booking URLs by percent-encoding custom JSON payloads.

## Base URL

```
https://www.finnair.com/gb-en/booking/flight-selection?json=<URL-encoded JSON>
```

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

| Field      | Meaning                                         |
| ---------- | ----------------------------------------------- |
| `adults`   | Adults (18+)                                    |
| `c15s`     | Children aged 12–15 (Finnair-specific category) |
| `children` | Children aged 2–11                              |
| `infants`  | Infants aged 0–2                                |

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

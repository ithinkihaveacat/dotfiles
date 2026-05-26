---
name: travel
description: >-
  Offers technical references and workflows for flight bookings and itinerary
  planning, focusing on Finnair booking URL parameter engineering. Use when
  generating, debugging, or analyzing Finnair booking URLs.
---

# Travel Booking

This skill provides references and instructions for constructing, debugging, and
engineering flight booking URLs.

## Finnair Booking URL Engineering

To construct direct booking URLs for Finnair with custom segments, cabin
classes, and passenger options:

- See
  [Finnair Multi-City Booking URL Reference](references/finnair-booking-url.md)
  for the full JSON parameter structure, valid cabin options, passenger
  configurations, and code examples.

### Core Tip

- **Cabin Value:** The cabin parameter must match route availability. Premium
  Economy is represented by `ECOPREMIUM` (not `PREMIUM_ECONOMY`). Incorrect
  values will result in a silent homepage redirect.

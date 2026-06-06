---
name: travel
description: >-
  Technical references and workflows for award flight redemption and itinerary
  planning. Covers British Airways Executive Club Avios (UK-origin), Qantas
  Frequent Flyer points and Amex Membership Rewards (Australia-origin), and
  Finnair booking URL engineering. Use when planning or pricing reward flights,
  comparing programmes/carrier surcharges, finding award availability, or
  generating, debugging, or analyzing Finnair booking URLs.
---

# Travel Booking

This skill provides practical, field-tested references for redeeming airline
loyalty points and constructing booking URLs. The redemption guides pre-calculate
points-plus-cash costs, document the actual booking workflows and search tools,
and record verified dead ends so they aren't repeated.

## Reward Flight Redemption Guides

- **[British Airways Avios](references/ba.md)** — UK-origin
  redemptions. BA Executive Club Avios (earned via the Amex Premium Plus Card),
  the Companion Voucher, the Avios group transfer partners, award charts,
  carrier surcharge comparisons, key routes from London, and availability tools.

- **[Qantas Points & Amex MR](references/qantas.md)** —
  Australia-origin redemptions. Qantas Frequent Flyer points (earned via Amex
  Membership Rewards transfers), Classic / Classic Plus / Upgrade rewards, the
  Australia–UK route, carrier-charge comparisons, and the Flight Reward Finder.

These two guides are counterparts: for a round trip between the UK and Australia,
compare booking each one-way leg through the cheaper programme. They cross-link
to each other for this reason.

## Finnair Booking URL Engineering

To construct direct booking URLs for Finnair with custom segments, cabin
classes, and passenger options:

- See
  [Finnair Booking URL Engineering Reference](references/finnair.md)
  for the full JSON parameter structure, valid cabin options, passenger
  configurations, and code examples.

### Core Tip

- **Cabin Value:** The cabin parameter must match route availability. Premium
  Economy is represented by `ECOPREMIUM` (not `PREMIUM_ECONOMY`). Incorrect
  values will result in a silent homepage redirect.

## Editorial Standard

All redemption guides in this skill follow a shared meta standard for how facts
are sourced, pre-calculated, timestamped, and how dead ends are documented:

- See the [Travel Booking Guides — Meta Reference](references/guide-meta.md) for
  the design goals, volatility tiers, pre-calculation format, access-requirement
  annotations (🔓 / 🔒 / 🌐 / 📞), dead-end documentation format, and source
  standards. Consult it when creating or updating any guide in this skill.

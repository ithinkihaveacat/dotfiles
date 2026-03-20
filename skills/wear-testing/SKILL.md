---
name: wear-testing
description: >
  Provides a guide and ADB commands for testing Wear OS applications. Focuses on
  triggering system state changes, simulating edge cases, and interacting with
  Wear-specific surfaces (tiles, complications, watchfaces). Triggers: wear os,
  testing, wear os testing, test wear os app, adb, pixel watch, galaxy watch.
compatibility:
  Requires adb and a connected Wear OS device (e.g., Pixel Watch, Galaxy Watch)
  or emulator.
---

# Wear OS Testing Guide

This skill provides workflows and ADB commands to test Wear OS applications
reliably, particularly for system state changes and edge cases that are hard to
reproduce manually (like Doze mode, data layer disconnection, and global
location constraints).

This skill covers both physical devices (Pixel Watches, Samsung Galaxy Watches)
and emulators. Official `DEBUG_SYSUI` and `DEBUG_SURFACE` intents are utilized
to interact with Wear surfaces, ensuring compatibility across all Wear OS device
implementations.

## How to use this skill

1. Review the task the user wants to test.
2. Load the relevant reference file for specific ADB commands and workflows.
3. Use the provided scripts to simulate complex states or manage UI surfaces
   like Tiles.

## References

- **System States & Edge Cases**: `references/system-states.md` (Network
  isolation, Doze mode, location permissions, battery states, language, and
  display density).
- **Permissions & OS Behavior**: `references/permissions.md` (Managing API 30-36
  changes, granular health permissions, FGS crashes, and cross-device
  requesting).
- **Health Services & Synthetic Data**: `references/health-services.md`
  (Triggering simulated exercises, sensor data, sleep states, and fall
  detection).
- **App Testability Patterns**: `references/testability.md` (Patterns for making
  Wear apps more debuggable via auth bypass, data seeding, and triggers).
- **Wear Surfaces**: `references/surfaces.md` (Interacting with Tiles,
  Watchfaces, and Complications using `DEBUG_SURFACE` and `DEBUG_SYSUI`).

## Scripts

- `scripts/wear-network-isolate`: Helper script to completely isolate the watch
  from the phone and internet to test data layer queuing and offline states.
- `scripts/adb-tile-add`: Deploy and refresh a specific Tile on the device.
- `scripts/adb-tile-remove`: Remove a specific Tile from the carousel.
- `scripts/adb-tile-show`: Bring a specific Tile to the foreground.
- `scripts/adb-theme`: Get or set the Android system theme customization
  (Dynamic Colors on API 36+).

---
name: android-testing
description: >-
  Workflows and ADB commands for testing Android and Wear OS applications. Covers
  system state simulation (Doze mode, battery levels, network failover, Bluetooth
  proxy), location and sensor spoofing, health permissions, UI automation guidelines,
  and Wear OS surfaces (tiles, complications, watch faces). Use when testing Android
  or Wear OS apps, simulating edge cases, debugging device connectivity, or
  automating UI test procedures.
compatibility: Requires adb and a connected Android phone or Wear OS device/emulator.
---

# Android & Wear OS Testing Guide

This skill provides comprehensive workflows, guidelines, and ADB commands to
test Android applications reliably across mobile phones and Wear OS devices. It
focuses on triggering system state changes, validating real-time
synchronization, implementing robust UI automation, and simulating complex edge
cases (Doze mode, data layer disconnection, and Fused Location spoofing limits).

## Procedural Workflows & Testing Recipes

### 1. Power & Doze Mode Simulation

Test how applications handle background execution, power constraints, and Doze
mode transitions:

```bash
# Force device into Doze (Idle) mode
adb shell dumpsys deviceidle force-idle

# Exit Doze mode
adb shell dumpsys deviceidle unforce

# Simulate low battery level (5%)
adb shell dumpsys battery unplug
adb shell dumpsys battery set level 5

# Reset battery state to default hardware behavior
adb shell dumpsys battery reset
```

### 2. Connectivity & Network Edge Cases

Simulate network isolation and diagnose Bluetooth proxy / Wi-Fi fallback:

```bash
# Isolate device (disable Bluetooth and Wi-Fi simultaneously)
adb shell svc bluetooth disable
adb shell svc wifi disable

# Restore connectivity
adb shell svc bluetooth enable
adb shell svc wifi enable

# Direct Wi-Fi credential injection (bypasses stale watch credentials)
adb shell 'cmd wifi connect-network "<SSID>" wpa2 <PASSWORD>'
```

> [!NOTE] **Wear OS Wi-Fi Delay:** Wear OS delays activating Wi-Fi for 45–60
> seconds after Bluetooth disconnection to conserve power. Wait at least 60
> seconds before evaluating Wi-Fi fallback.

### 3. Headless Emulator Setup & Tutorial Bypass

Bootstrap fresh or headless emulators to ensure tests run without blocking
overlays or keyguard locks:

```bash
# Wake up and dismiss keyguard
adb shell input keyevent KEYCODE_WAKEUP
adb shell wm dismiss-keyguard

# Dismiss charging animation overlay (if present)
adb shell dumpsys battery unplug

# Bypass Wear OS tutorial and initial setup overlays
adb shell am broadcast -a com.google.android.clockwork.action.TEST_MODE
adb shell am broadcast -a com.google.android.clockwork.action.TUTORIAL_SKIP
```

### 4. Wear OS Surface Interaction

Trigger debug broadcasts to update or inspect Wear OS Tiles and Complications:

```bash
# Add a Tile component to the carousel
adb shell am broadcast -a com.google.android.wearable.app.DEBUG_SURFACE \
  --es operation add-tile --ecn component "<PACKAGE>/<TILE_SERVICE>" --ei type 0

# Switch active Tile by index
adb shell am broadcast -a com.google.android.wearable.app.DEBUG_SYSUI \
  --es operation show-tile --ei index 0

# Trigger a Complication update
adb shell am broadcast -a com.google.android.wearable.app.DEBUG_SYSUI \
  --es operation complication_update --ei complication_id <ID>
```

## How to Approach Testing

1. **Review Requirements:** Identify the specific device form factor, API level
   (API 30–36+), and subsystem under test.
1. **Apply Capabilities:** Use standard ADB commands or workspace device
   automation tools to simulate state changes.
1. **Consult References:** Load the dedicated reference documents below for
   in-depth guidelines, sensor schemas, and platform quirks.

## Reference Material

- **[UI Automation Guidelines](references/ui-automation-guidelines.md)** —
  "Behave Like a Real User" and "Visual Timeline" policies for robust, non-flaky
  UI test automation.
- **[System States & Connectivity](references/system-states-and-connectivity.md)**
  — Bluetooth proxy bandwidth limits, Wi-Fi failovers, Doze mode, and battery
  simulation.
- **[Location & Sensors](references/location-and-sensors.md)** — Fused Location
  Provider rules, Mock Location App requirements, Wear Health Services synthetic
  data, and One-Handed Gestures (Double-Pinch) simulation.
- **[Permissions & OS Behavior](references/permissions-and-os-behavior.md)** —
  Foreground Service types, API 30–36 changes, and Wear OS granular health
  permissions.
- **[Wear Surfaces](references/wear-surfaces.md)** — Interacting with Tiles,
  Watch Faces, and Complications via `DEBUG_SURFACE`/`DEBUG_SYSUI`; includes
  headless setup and GMS capability sync workarounds.
- **[Testability Patterns](references/testability-patterns.md)** — App-side
  debug receivers, data seeding, OOBE race conditions, and standby buckets.

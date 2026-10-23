---
name: android-testing
description: >-
  Workflows and ADB commands for testing Android and Wear OS applications. Covers
  simulating devices without hardware (off-device @Preview rendering, standalone
  watch bootstrapping, paired phone-watch emulator Data Layer bridging), network
  and power state simulation (Doze mode, battery levels, Wi-Fi failover, Bluetooth
  proxy), UI/display and physical input simulation (themes, font scale, rotary
  crown, Wear OS 7+ one-handed gestures), location and synthetic health sensors,
  permissions, watch faces and complications, and UI automation guidelines. Use
  when testing Android or Wear OS apps, simulating edge cases, debugging device
  connectivity, or automating UI test procedures.
compatibility: Requires adb and a connected Android phone or Wear OS device/emulator (or a host JVM @Preview renderer for off-device UI verification).
---

# Android & Wear OS Testing Guide

This skill provides workflows, decision rules, and ADB commands to test Android
applications reliably across mobile phones and Wear OS devices—from fast
off-device `@Preview` checks and headless emulator pairing to system state
simulation, synthetic sensors, and non-flaky UI automation.

## Quick-Start Workflows & Recipes

### 1. Simulating Devices Without Hardware

Choose the lightest simulation tier that covers the behavior under test (see
**[Simulating Devices Without Hardware](references/simulating-devices.md)** for
the full decision boundary and GMSCore architecture):

- **Off-Device Host-JVM `@Preview` Rendering (No Emulator Needed)**: For layout,
  circular watch bezel clipping (`id:wearos_small_round` /
  `id:wearos_large_round`), font scale, locales, Wear Tiles (`TilePreviewData`),
  Remote Compose (`.rc`), and ATF accessibility checks, render previews directly
  on the host JVM (e.g., via `compose-preview` or Robolectric) before booting an
  emulator.
- **Standalone Watch Bootstrapping (No Companion Phone)**: Bypass OOBE, the OEM
  setup wizard, and tutorial overlays on a fresh watch or emulator (`adb root`
  required for `pm disable`):
  ```bash
  adb shell settings put global device_provisioned 1
  adb shell settings put secure user_setup_complete 1
  adb shell pm disable com.google.android.wearable.setupwizard
  adb shell dumpsys battery unplug
  adb shell input keyevent KEYCODE_WAKEUP
  adb shell wm dismiss-keyguard
  adb shell am broadcast -a com.google.android.clockwork.action.TEST_MODE
  adb shell am broadcast -a com.google.android.clockwork.action.TUTORIAL_SKIP
  adb shell input keyevent KEYCODE_HOME
  ```
- **Paired Phone & Wear OS Emulator Bridging (Data Layer API)**: Bridge a
  running `google_apis` / `google_apis_ps16k` (`userdebug`) phone emulator and a
  Wear OS emulator over TCP port `5601` using the workspace `adb-wear-pair`
  helper if available (or follow the manual sequence in
  **[Simulating Devices Without Hardware](references/simulating-devices.md#paired-phone--wear-os-emulator-bridging)**):
  ```bash
  # Pair auto-detected phone and watch emulators over TCP port 5601
  adb-wear-pair

  # Inspect pairing state on one or both emulators ([PASS] Connected / [WARN] Disconnected / [FAIL] Unpaired)
  adb-wear-pair --status
  ```

### 2. Network & Power State Simulation

Test background execution, Doze mode, battery levels, and radio isolation (see
**[Network & Power States](references/network-and-power.md)**):

```bash
# Force / exit Doze (Idle) mode
adb shell dumpsys deviceidle force-idle
adb shell dumpsys deviceidle unforce

# Simulate low battery (5%) and restore default hardware state
adb shell dumpsys battery unplug
adb shell dumpsys battery set level 5
adb shell dumpsys battery reset

# Isolate device (disable Bluetooth and Wi-Fi) and restore connectivity
adb shell svc bluetooth disable
adb shell svc wifi disable
adb shell svc bluetooth enable
adb shell svc wifi enable
```

> [!NOTE] **Wear OS Wi-Fi Delay:** Wear OS delays activating Wi-Fi for 45–60
> seconds after Bluetooth disconnection to conserve power. Wait at least 60
> seconds before evaluating Wi-Fi fallback.

### 3. Synthetic Sensors & One-Handed Gestures

Simulate biometric exercise data and physical Wear OS 7+ hand gestures without
physical movement (see
**[Location & Sensors](references/location-and-sensors.md)** and
**[UI, Display & Physical Inputs](references/ui-and-inputs.md)**):

```bash
# Enable Wear Health Services synthetic sensor mode and start a simulated run
adb shell am broadcast -a "whs.USE_SYNTHETIC_PROVIDERS" com.google.android.wearable.healthservices
adb shell am broadcast -a "whs.synthetic.user.START_RUNNING" com.google.android.wearable.healthservices
adb shell am broadcast -a "whs.synthetic.user.STOP_EXERCISE" com.google.android.wearable.healthservices

# Bypass off-body check and inject a Wear OS 7+ Double Pinch (PrimaryAction)
adb shell cmd IWearGestureService override-constraints offbody-state
adb shell cmd IWearGestureService gesture DoublePinch
```

## How to Approach Testing

1. **Pick the Simulation Tier:** Use host-JVM `@Preview` rendering for pure UI,
   layout, Tile, and accessibility checks; boot a single emulator for OS
   services and sensors; pair phone and watch emulators when testing Wearable
   Data Layer synchronization.
1. **Apply Capabilities:** Use workspace `adb-*` helper scripts where available
   or standard `adb` commands to drive state changes and capture evidence.
1. **Consult References:** Load the dedicated reference documents below for
   in-depth guidelines, sensor schemas, and platform quirks.

## Reference Material

- **[Simulating Devices Without Hardware](references/simulating-devices.md)** —
  Off-device host-JVM `@Preview` rendering boundaries, emulator image selection,
  standalone watch OOBE bypass, and headless phone–watch emulator Data Layer
  bridging (`adb-wear-pair`).
- **[Network & Power States](references/network-and-power.md)** — Bluetooth
  companion proxy bandwidth limits, 60-second Wi-Fi handoff delays, direct WPA2
  credential injection, dual bugreports, Doze mode, and battery simulation.
- **[UI, Display & Physical Inputs](references/ui-and-inputs.md)** — Dynamic
  color themes (API 36+), font scale, display density (DPI), rotary crown and
  wrist keyevents, and Wear OS 7+ One-Handed Gestures (`IWearGestureService`).
- **[Location & Sensors](references/location-and-sensors.md)** — Fused Location
  Provider anti-spoofing rules, Mock Location App requirements, and Wear Health
  Services (`whs.*`) synthetic exercise and biometric data.
- **[Permissions & OS Behavior](references/permissions-and-os-behavior.md)** —
  Wear OS 5 vs. 6 granular health permissions, Foreground Service types, Watch
  Face Push permission limits, `FLAG_STOPPED` de-isolation, locale switching,
  and cloud backup/restore (`bmgr`).
- **[Watch Faces & Complications](references/watch-faces-and-complications.md)**
  — Forcing complication updates via `DEBUG_SYSUI` (`adb-complication-update`)
  and simulating ambient mode (`cmd wearable_sensing set-ambient-mode`).
- **[UI Automation Guidelines](references/ui-automation-guidelines.md)** —
  "Behave Like a Real User" and "Visual Timeline" policies, awake/demo mode
  setup, companion app onboarding, and real-time sync verification.
- **[Testability Patterns](references/testability-patterns.md)** — App-side
  debug broadcast receivers, data seeding, OOBE race conditions, and standby
  buckets.

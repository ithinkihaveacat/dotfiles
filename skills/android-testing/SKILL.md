---
name: android-testing
description: >
  Provides a comprehensive guide and ADB workflows for testing Android applications
  (both phone and Wear OS). Focuses on triggering system state changes, simulating
  connectivity edge cases, implementing robust UI automation, and interacting with
  Wear-specific surfaces. Triggers: android testing, wear os, testing, adb, pixel
  watch, galaxy watch, spoofing, fused location.
compatibility: Requires adb and a connected Android phone or Wear OS device/emulator.
---

# Android & Wear OS Testing Guide

This skill provides comprehensive workflows, guidelines, and ADB commands to
test Android applications reliably across both mobile phones and Wear OS
devices. It focuses particularly on triggering system state changes, validating
real-time synchronization, implementing robust UI automation, and simulating
complex edge cases (like Doze mode, data layer disconnection, and Fused Location
spoofing limits).

## How to use this skill

1. Review the testing tasks or edge cases required for your application.
1. Load the relevant reference file for specific guidelines, architectural
   constraints, and ADB workflows.
1. Cross-reference other active skills to automate system manipulations.

## References

- **UI Automation Guidelines**: `references/ui-automation-guidelines.md`
  (Generalized "Behave Like a Real User" and "Visual Timeline" policies for
  robust, non-flaky UI testing).
- **System States & Connectivity**:
  `references/system-states-and-connectivity.md` (Bluetooth proxy bottlenecks,
  Wi-Fi failovers, Doze mode, and battery simulation).
- **Location & Sensors**: `references/location-and-sensors.md` (Fused Location
  Provider security, Mock Location App requirements, Wear OS Health Services
  synthetic data, and One-Handed Gestures (Double-Pinch) simulation/overrides).
- **Permissions & OS Behavior**: `references/permissions-and-os-behavior.md`
  (Foreground Service types, API 30-36 changes, and Wear OS granular health
  permissions).
- **Wear Surfaces**: `references/wear-surfaces.md` (Interacting with Tiles,
  Watchfaces, and Complications using `DEBUG_SURFACE` and `DEBUG_SYSUI`).
- **Testability Patterns**: `references/testability-patterns.md` (App-side debug
  receivers, data seeding, OOBE race conditions, and standby buckets).

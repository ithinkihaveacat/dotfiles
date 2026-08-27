---
name: apk
description: >-
  Performs offline binary analysis, extraction, decoding, decompilation, and inspection
  of Android APKs and split-APK ZIP archives. Provides tools for reading manifests,
  extracting launcher icons, inspecting Wear OS tiles/complications, and decoding
  resources.
  Use when inspecting APK metadata, decompiling resources, analyzing binary manifests,
  extracting icons, or installing local APK packages on a device.
compatibility: >-
  Requires apkanalyzer, unzip, and xmllint. Some scripts require xpath, aapt, or apktool.
  Designed for filesystem-based agents with bash access.
---

# Android APK Utilities

This skill provides a comprehensive suite of utilities for working with Android
APK files and split-APK ZIP archives offline.

## Using Helper Scripts vs. Raw CLI Tools

Use the scripts in `scripts/` as the primary interface for APK inspection. They
automate handling split-APK ZIP archives (extracting base splits to temporary
directories), normalize output across `aapt`, `aapt2`, and `apkanalyzer`, and
format XML manifests for clean readability.

When raw tools like `apkanalyzer` or `aapt2` are needed for specialized flags,
refer to the helper scripts as reference implementations for handling archive
extraction and error recovery.

## Script Index

See `references/command-index.md` for detailed usage.

- `scripts/apk-info`: The unified read-only APK metadata and file inspector.
  Supports subcommands (`package`, `manifest`, `version`, `libraries`, `tiles`,
  `complications`, `launcher`, `file`).

### Extraction & Decoding

- `scripts/apk-decode`: Decompile the entire APK using apktool to inspect
  resources.
- `scripts/apk-launcher-icon-extract`: Decompile and extract the launcher and
  round launcher icons as files.
- `scripts/apk-unzip`: Unzip ZIP archives, split APK bundles, or app bundles.

### Device Interaction

- `scripts/apk-install-and-launch`: Install the APK/ZIP on a connected device
  and launch its main activity.

> [!TIP] If the application is already installed on the device and you want to
> launch it without reinstalling (preserving state and cache), you can compose
> the `scripts/apk-info` package query with an ADB package management utility
> (such as `packagename`, if available in your workspace):
>
> - **Fish:** `packagename launch (apk-info package app.apk)`
> - **Bash/Zsh:** `packagename launch $(apk-info package app.apk)`

## Reference Material

- **[Command Index](references/command-index.md)** — Detailed synopsis, options,
  and examples for all APK scripts.
- **[Troubleshooting](references/troubleshooting.md)** — Solutions for missing
  dependencies (`apkanalyzer`, `xpath`, `apktool`, `aapt`).

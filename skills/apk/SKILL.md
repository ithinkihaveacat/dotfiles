---
name: apk
description: >
  Performs offline binary analysis, extraction, decoding, decompilation, and
  inspection of Android APKs and ZIP archives (split APKs). Provides utilities for
  reading manifests, extracting launcher icons, listing Wear OS tiles/complications,
  and decoding resources. Use when inspecting APK properties, performing binary
  analysis, extracting files from packages, or installing local APKs. Triggers: apk,
  binary analysis, binary decoding, apkanalyzer, apktool, aapt, android manifest.
compatibility: >-
  Requires apkanalyzer, unzip, and xmllint. Some scripts require xpath, aapt, or apktool.
  Designed for filesystem-based agents with bash access.
---

# Android APK Utilities

This skill provides a comprehensive suite of utilities for working with Android
APK files and split-APK ZIP archives offline.

## Important: Use Scripts First

**ALWAYS prefer the scripts in `scripts/` over running raw tool commands.**
Scripts are located in the `scripts/` subdirectory of this skill's folder. They
handle complex tasks like automatically extracting split APKs from ZIP archives
and formatting output XML files for readability.

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

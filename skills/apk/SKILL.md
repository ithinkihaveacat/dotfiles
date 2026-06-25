---
name: apk
description: >
  Performs offline analysis, extraction, decoding, and inspection of Android
  APKs and ZIP archives (split APKs). Provides utilities for reading manifests,
  extracting launcher icons, listing Wear OS tiles/complications, and decoding
  resources. Use when inspecting APK properties, extracting files from packages,
  or installing local APKs. Triggers: apk, apkanalyzer, apktool, aapt, android manifest.
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

### Information & Manifest Inspection

- `scripts/apk-packagename`: Extract the application ID/package name.
- `scripts/apk-cat-manifest`: Display a formatted, readable AndroidManifest.xml.
- `scripts/apk-version-code` / `scripts/apk-version-name`: Read version
  metadata.
- `scripts/apk-version-whs` / `scripts/apk-version-wear-compose`: Read specific
  library versions inside the APK.

### Wear OS Specializations

- `scripts/apk-tiles`: List all Wear OS tiles services declared in the manifest.
- `scripts/apk-complications`: List all Wear OS complications data providers
  declared.

### Extraction & Decoding

- `scripts/apk-unzip`: Unzip files from the APK.
- `scripts/apk-cat-file`: Extract and print the contents of a specific file
  inside the APK.
- `scripts/apk-cat-launcher`: Extract and print the launcher icon file contents.
- `scripts/apk-launcher-icon-extract`: Decompile and extract the launcher icon
  as a PNG.
- `scripts/apk-decode`: Decompile the entire APK using apktool.

### Device Interaction

- `scripts/apk-install-and-launch`: Install the APK and launch its main
  activity.
- `scripts/apk-launch`: Launch the main activity of an already installed
  package.

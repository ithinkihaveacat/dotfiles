---
name: apk
description: >-
  Performs offline binary analysis, extraction, decoding, decompilation, and inspection
  of Android APKs and split-APK ZIP archives. Provides tools for reading manifests,
  extracting launcher icons, inspecting Wear OS tiles/widgets/complications, decoding
  resources, rasterizing vector drawables, and disassembling DEX bytecode to smali
  for evidence-grade code checks (overrides, call sites, annotations).
  Use when inspecting APK metadata, decompiling resources, analyzing binary manifests,
  verifying what compiled code does (smali, R8/obfuscation-aware checks),
  extracting icons, rasterizing vector drawables to PNG, or installing local APK
  packages on a device.
compatibility: >-
  Requires apkanalyzer, unzip, and xmllint. Some scripts require xpath, aapt, or apktool.
  apk-smali requires uv, plus baksmali or apktool to disassemble; jadx is optional.
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
  `complications`, `launcher`, `file`, `doctor`). `apk-info doctor` (also
  available as `apk-doctor`) checks tool dependencies and capability readiness.

### Extraction & Decoding

- `scripts/apk-decode`: Decompile the entire APK using apktool to inspect
  resources.
- `scripts/apk-launcher-icon-extract`: Decompile and extract the launcher and
  round launcher icons as files.
- `scripts/apk-unzip`: Unzip ZIP archives, split APK bundles, or app bundles.
- `scripts/avd-to-png`: Convert Android Vector Drawable (AVD) XML files to SVG
  and render them to PNG.

### Bytecode Analysis

- `scripts/apk-smali`: Disassemble all DEX files of an APK, split-APK archive,
  or App Bundle into one smali tree (`disassemble`), then query it: classes that
  declare, call, extend, implement, or are annotated with something (`find`),
  and a class, method body with its same-class callees, class annotations, or
  superclass chain (`show class`, `show method`, `show annotations`,
  `show hierarchy`). `find` and `show` also read a pre-disassembled smali
  archive (any ZIP or directory of baksmali output) in place. See
  `references/bytecode-analysis.md` for when to use smali versus jadx and how to
  report findings.

### Device Interaction

- `scripts/apk-install-and-launch`: Install the APK/ZIP on a connected device
  and launch its main activity.

> [!TIP] If the application is already installed on the device and you want to
> launch it without reinstalling (preserving state and cache), you can compose
> the `scripts/apk-info` package query with `adb` (or an ADB package management
> helper such as `packagename` if available in your workspace):
>
> - **Standard ADB:**
>   `adb shell monkey -p "$(scripts/apk-info package app.apk)" -c android.intent.category.LAUNCHER 1`
> - **With `packagename` (Bash/Zsh):**
>   `packagename launch "$(apk-info package app.apk)"`
> - **With `packagename` (Fish):**
>   `packagename launch (apk-info package app.apk)`

## Reference Material

- **[Command Index](references/command-index.md)** — Detailed synopsis, options,
  and examples for all APK scripts.
- **[Bytecode Analysis](references/bytecode-analysis.md)** — Smali versus jadx
  versus dexdump, smali basics, static-analysis limits, evidence rules, and
  cross-checking against upstream library sources.
- **[Troubleshooting](references/troubleshooting.md)** — Solutions for missing
  dependencies (`apkanalyzer`, `xpath`, `apktool`, `aapt`, `baksmali`).

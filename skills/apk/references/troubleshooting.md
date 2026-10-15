# Troubleshooting

<!-- markdownlint-disable MD013 -->

## Contents

- [Missing Dependencies](#missing-dependencies)

## Missing Dependencies

### `apkanalyzer` not found

**Context**: `apk-packagename`, `apk-cat-manifest`, `apk-version-code`, and
`apk-version-name` require the Android SDK `apkanalyzer` tool to extract
manifest metadata. **Solution**:

- Install Android Command Line Tools via Android Studio or SDK Manager.
- Ensure `cmdline-tools/bin` is in your PATH.

### `xpath` not found

**Context**: `apk-tiles` and `apk-complications` use `xpath` to parse elements
from the manifest. **Solution**:

- macOS: Comes with Perl, but if missing: `brew install libxml2` (includes
  xmllint) or check perl modules.
- Debian/Ubuntu: `sudo apt-get install libxml-xpath-perl`

### `apktool` not found

**Context**: `apk-decode` and `apk-launcher-icon-extract` require `apktool` to
decompile resources. **Solution**:

- macOS: `brew install apktool`
- Debian/Ubuntu: `sudo apt-get install apktool`

### `aapt` not found

**Context**: `apk-cat-launcher` requires `aapt` to read badging information and
extract the launcher icon path. **Solution**:

- macOS / Debian / Ubuntu: Install Android SDK Build-Tools via Android Studio or
  SDK Manager, and ensure the build-tools directory (e.g.,
  `Android/sdk/build-tools/<version>/`) is in your PATH.

### `baksmali` not found (`apk-smali disassemble` exits 127)

**Context**: `apk-smali disassemble` turns DEX bytecode into smali with
`baksmali`, falling back to `apktool d --no-res` when `baksmali` is not on PATH.
It exits 127 only when neither is available. `apk-smali find` and
`apk-smali show` need neither tool, and neither does `disassemble` when its
input is already smali. **Solution** (either tool is enough; `baksmali` is
preferred because it also handles raw `.dex` files and App Bundles):

- `baksmali`: on macOS, `brew install smali` provides `baksmali`. Elsewhere, get
  a baksmali JAR as described in the
  [smali README](https://github.com/google/smali) (requires Java) and put a
  wrapper named `baksmali` on PATH:
  ```bash
  printf '#!/bin/sh\nexec java -jar "$HOME/lib/baksmali.jar" "$@"\n' >~/.local/bin/baksmali
  chmod +x ~/.local/bin/baksmali
  ```
- `apktool`: see [`apktool` not found](#apktool-not-found) above.

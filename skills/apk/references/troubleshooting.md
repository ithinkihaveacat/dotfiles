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

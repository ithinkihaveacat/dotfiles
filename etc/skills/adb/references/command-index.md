<!-- markdownlint-disable MD013 -->

# Command Index

## Contents

- [Device Basics](#device-basics)
- [Media Capture](#media-capture)
- [Tile Management (Wear OS)](#tile-management-wear-os)
- [Activity Discovery](#activity-discovery)
- [Package Operations](#package-operations)
- [Wear OS Data Layer](#wear-os-data-layer)
- [Display & Demo Mode](#display--demo-mode)

## Device Basics

### `scripts/adb-devices`

**Purpose**: List connected devices (serial numbers only). **Dependencies**:
`adb` **Usage**: `scripts/adb-devices` **Raw Command**:

```bash
adb devices -l | tail +2 | awk 'length { print $1 }'
```

### `scripts/adb-device-properties`

**Purpose**: Show key device properties (model, manufacturer, release, SDK).
**Dependencies**: `adb` **Usage**: `scripts/adb-device-properties` **Raw
Command**:

```bash
adb exec-out getprop ro.product.model
adb exec-out getprop ro.product.manufacturer
adb exec-out getprop ro.build.version.release
adb exec-out getprop ro.build.version.sdk
```

### `scripts/adb-api-level`

**Purpose**: Get the device API level. **Dependencies**: `adb` **Usage**:
`scripts/adb-api-level` **Raw Command**:

```bash
adb exec-out getprop ro.build.version.sdk
```

### `scripts/adb-keyevent-wakeup`

**Purpose**: Wake up the device. **Dependencies**: `adb` **Usage**:
`scripts/adb-keyevent-wakeup` **Raw Command**:

```bash
adb exec-out input keyevent KEYCODE_WAKEUP
```

### `scripts/adb-keyevent-sleep`

**Purpose**: Put the device to sleep. **Dependencies**: `adb` **Usage**:
`scripts/adb-keyevent-sleep` **Raw Command**:

```bash
adb exec-out input keyevent KEYCODE_SLEEP
```

## Media Capture

### `scripts/adb-screenshot`

**Purpose**: Take a screenshot. Applies circular mask if display is square (Wear
OS). **Dependencies**: `adb`, `magick` **Usage**:
`scripts/adb-screenshot [OUTPUT_FILE]` **Raw Command**:

```bash
# Standard
adb exec-out "screencap -p" > output.png

# Wear OS (Square display masked to circle)
adb exec-out "screencap -p" | magick - \
  -alpha set -background none -fill white \
  \( +clone -channel A -evaluate set 0 +channel \
     -draw "circle %[fx:(w-1)/2],%[fx:(h-1)/2] %[fx:(w-1)/2],0.5" \) \
  -compose dstin -composite output.png
```

### `scripts/adb-screenrecord`

**Purpose**: Record screen to video file. **Dependencies**: `adb` **Usage**:
`scripts/adb-screenrecord [OUTPUT_FILE]` **Raw Command**:

```bash
adb shell screenrecord /sdcard/screen.mp4
# (Then pull the file)
```

## Tile Management (Wear OS)

### `scripts/adb-tile-add`

**Purpose**: Add a tile component for debugging. **Dependencies**: `adb`
**Usage**: `scripts/adb-tile-add com.example/.MyTileService` **Raw Command**:

```bash
adb shell am broadcast \
  -a com.google.android.wearable.app.DEBUG_SURFACE \
  --es operation add-tile \
  --ecn component "com.example/.MyTileService"
```

### `scripts/adb-tile-show`

**Purpose**: Show an added tile by index. **Dependencies**: `adb` **Usage**:
`scripts/adb-tile-show INDEX` **Raw Command**:

```bash
adb shell am broadcast \
  -a com.google.android.wearable.app.DEBUG_SYSUI \
  --es operation show-tile \
  --ei index INDEX
```

### `scripts/adb-tile-remove`

**Purpose**: Remove a tile. **Dependencies**: `adb` **Usage**:
`scripts/adb-tile-remove INDEX` **Raw Command**:

```bash
adb shell am broadcast \
  -a com.google.android.wearable.app.DEBUG_SURFACE \
  --es operation remove-tile \
  --ei index INDEX
```

### `scripts/adb-tiles`

**Purpose**: List currently added tiles. **Dependencies**: `adb` **Usage**:
`scripts/adb-tiles` **Raw Command**:

```bash
adb shell dumpsys activity service com.google.android.wearable.app.tiles.TileService
# (Requires parsing output)
```

## Activity Discovery

### `scripts/adb-activities`

**Purpose**: List activities on the device, tagged by category. By default shows
only user-installed apps. **Dependencies**: `adb` **Usage**:

```bash
scripts/adb-activities [OPTIONS]
```

**Options**:

- `--launcher-only`: Show only launcher activities
- `--home-only`: Show only home/launcher app activities
- `--tv-only`: Show only TV/Leanback activities
- `--settings-only`: Show only settings/preference activities
- `--all`: Include system apps (default: user apps only)

**Category Tags** (in default output):

- `L` - Launcher (`android.intent.category.LAUNCHER`)
- `H` - Home (`android.intent.category.HOME`)
- `T` - TV/Leanback (`android.intent.category.LEANBACK_LAUNCHER`)
- `S` - Settings (`android.intent.category.PREFERENCE`)

**Examples**:

```bash
# List all activities from user apps with category tags
scripts/adb-activities

# Find launcher activities only
scripts/adb-activities --launcher-only

# Find TV/Leanback activities (useful for Android TV)
scripts/adb-activities --tv-only

# Include system apps
scripts/adb-activities --all
```

**Raw Command**:

```bash
# Query launcher activities
adb shell cmd package query-activities \
  -a android.intent.action.MAIN \
  -c android.intent.category.LAUNCHER

# Query TV/Leanback activities
adb shell cmd package query-activities \
  -a android.intent.action.MAIN \
  -c android.intent.category.LEANBACK_LAUNCHER

# Query settings activities
adb shell cmd package query-activities \
  -c android.intent.category.PREFERENCE

# List user-installed packages only
adb shell pm list packages -3
```

### `scripts/adb-uihierarchy`

**Purpose**: Dump the UI hierarchy to an XML file. **Dependencies**: `adb`,
`xmllint` (optional but recommended for formatting) **Usage**:
`scripts/adb-uihierarchy [OUTPUT_FILE]` **Raw Command**:

```bash
adb exec-out uiautomator dump /dev/stdout
# (Piped to xml format)
```

## Package Operations

### `scripts/packagename`

**Purpose**: Unified package management tool. **Dependencies**: `adb` **Usage**:
`scripts/packagename COMMAND PACKAGE` **Commands**: `launch`, `force-stop`,
`uninstall`, `clear-cache`, `permissions`, `services`, `version`, `pull`. **Raw
Commands**:

```bash
# launch
adb exec-out monkey --pct-syskeys 0 -p PACKAGE -c android.intent.category.LAUNCHER 1

# force-stop
adb exec-out am force-stop PACKAGE

# clear-cache
adb exec-out pm clear PACKAGE

# services
adb exec-out dumpsys activity service PACKAGE

# uninstall
    adb uninstall PACKAGE
```

### `scripts/adb-logcat-package`

**Purpose**: Show logcat filtered by a package's PID. **Dependencies**: `adb`
**Usage**: `scripts/adb-logcat-package PACKAGE` **Raw Command**:

```bash
pid=$(adb exec-out pidof PACKAGE)
adb logcat --pid="$pid"
```

### `scripts/apk-tiles`

**Purpose**: List tiles declared in an APK or ZIP. **Dependencies**:
`apk-cat-manifest`, `xpath` **Usage**: `scripts/apk-tiles APK_FILE` **Raw
Command**:

```bash
apk-cat-manifest APK_FILE | xpath -n -q -e \
  "//service[intent-filter/action[@android:name='androidx.wear.tiles.action.BIND_TILE_PROVIDER']]"
```

## Wear OS Data Layer

### `scripts/wearableservice-capabilities`

**Purpose**: Dump advertised capabilities. **Dependencies**: `adb` **Usage**:
`scripts/wearableservice-capabilities` **Raw Command**:

```bash
adb exec-out dumpsys activity service WearableService | sed -n '/CapabilityService/,/######/p'
```

### `scripts/wearableservice-nodes`

**Purpose**: List connected nodes. **Dependencies**: `adb` **Usage**:
`scripts/wearableservice-nodes` **Raw Command**:

```bash
adb exec-out dumpsys activity service WearableService | sed -n '/NodeService/,/######/p'
```

### `scripts/wearableservice-items`

**Purpose**: List data items. **Dependencies**: `adb` **Usage**:
`scripts/wearableservice-items` **Raw Command**:

```bash
adb exec-out dumpsys activity service WearableService | sed -n '/DataService/,/######/p'
```

## Display & Demo Mode

### `scripts/adb-demo-on`

**Purpose**: Enable demo mode (clean status bar, 100% battery, 16:20 time).
**Dependencies**: `adb` **Usage**: `scripts/adb-demo-on` **Raw Command**:

```bash
adb exec-out settings put global sysui_demo_allowed 1
adb exec-out am broadcast -a com.android.systemui.demo -e command enter
adb exec-out am broadcast -a com.android.systemui.demo -e command clock -e hhmm 1620
# ... (see script for full list of broadcasts)
```

### `scripts/adb-demo-off`

**Purpose**: Disable demo mode. **Dependencies**: `adb` **Usage**:
`scripts/adb-demo-off` **Raw Command**:

```bash
adb exec-out am broadcast -a com.android.systemui.demo -e command exit
```

### `scripts/adb-fontscale-default`

**Purpose**: Reset font scale to 1.0. **Dependencies**: `adb` **Usage**:
`scripts/adb-fontscale-default` **Raw Command**:

```bash
adb exec-out settings put system font_scale 1.0
```

### `scripts/adb-fontscale-large`

**Purpose**: Set font scale to large (e.g., 1.3 or 1.15). **Dependencies**:
`adb` **Usage**: `scripts/adb-fontscale-large` **Raw Command**:

```bash
# (Value may vary by script version)
adb exec-out settings put system font_scale 1.15
```

### `scripts/adb-theme`

**Purpose**: Get or set system theme customization (e.g., 'lemongrass', 'none').
**Requirements**: Wear OS device, API Level 36+ (Android 16) recommended.
**Dependencies**: `adb`, `jq` **Usage**: `scripts/adb-theme [get|set THEME]`
**Raw Command**:

```bash
# Get current theme
adb exec-out settings get secure theme_customization_overlay_packages | jq .

# Set theme (example)
adb exec-out settings put secure theme_customization_overlay_packages '{"android.theme.customization.theme_style":"EXPRESSIVE",...}'
```

### `scripts/adb-settings-theme`

**Purpose**: Open system theme settings (requires root/debuggable build).
**Dependencies**: `adb` **Usage**: `scripts/adb-settings-theme` **Raw Command**:

```bash
adb exec-out am start -a com.google.android.clockwork.sysui.ACTION_SYSTEM_THEME_SETTINGS
```

### `scripts/adb-touches-on`

**Purpose**: Show visual feedback for taps. **Dependencies**: `adb` **Usage**:
`scripts/adb-touches-on` **Raw Command**:

```bash
adb exec-out settings put system show_touches 1
```

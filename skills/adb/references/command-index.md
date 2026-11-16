# Command Index

<!-- markdownlint-disable MD013 -->

## Contents

- [Device Basics](#device-basics)
- [Media Capture](#media-capture)
- [Tile Management (Wear OS)](#tile-management-wear-os)
- [Activity Discovery](#activity-discovery)
- [Package Operations](#package-operations)
- [Raw ADB Commands](#raw-adb-commands)
- [System & Dumpsys](#system--dumpsys)
- [Display & Demo Mode](#display--demo-mode)

## Device Basics

### `scripts/adb-device-properties`

**Purpose**: Show key device properties (model, manufacturer, release, SDK,
display resolution and density). **Dependencies**: `adb`

<!-- generated: ../scripts/adb-device-properties --help -->

```text
Usage: adb-device-properties [OPTIONS]

Display device information and properties from an adb-connected Android device.

Shows hardware details, software versions, and display configuration including:
  - Device manufacturer, model, and serial number
  - Android version, API level, and security patch date
  - SoC/chipset information and CPU architecture
  - Display resolution, density, and calculated dp size

Options:
  -s, --serial SERIAL
                  Target device serial; must precede arguments or commands.
  --help      Display this help message and exit

Environment:
  ANDROID_SERIAL  Serial number of device to connect to (see 'adb devices -l').
                  The --serial option takes precedence when both are set.
```

<!-- /generated -->

**Raw Command**:

```bash
adb exec-out getprop ro.product.model
adb exec-out getprop ro.product.manufacturer
adb exec-out getprop ro.build.version.release
adb exec-out getprop ro.build.version.sdk
```

### `scripts/adb-log`

**Purpose**: Write a message to the Android system log. **Dependencies**: `adb`

<!-- generated: ../scripts/adb-log --help -->

```text
Usage: adb-log [OPTIONS] MESSAGE

Writes a message to the Android system log on an adb-connected device.

Arguments:
  MESSAGE     The message string to log.

Options:
  -s, --serial SERIAL
                  Target device serial; must precede arguments or commands.
  --help      Display this help message and exit

Environment:
  ANDROID_SERIAL  Serial number of device to connect to (see 'adb devices -l').
                  The --serial option takes precedence when both are set.

Examples:
  adb-log "Starting test sequence"
```

<!-- /generated -->

**Raw Command**:

```bash
adb exec-out log -p f -t TAG MESSAGE
```

## Media Capture

### `scripts/adb-screenshot`

**Purpose**: Take a screenshot (with optional `--no-wake` for ambient/AOD
captures). Applies circular mask if display is square (Wear OS).
**Dependencies**: `adb`, `magick`

<!-- generated: ../scripts/adb-screenshot --help -->

```text
Usage: adb-screenshot [OPTIONS] [FILE]

Takes a screenshot from an adb-connected device.

The screenshot is saved to the specified file, or to a timestamped file in the
current directory if no file is specified.

For square displays (e.g., Wear OS), a circular mask is applied to the screenshot.

Arguments:
  FILE              The path to save the screenshot to, or '-' for stdout.
                    (defaults to 'adb-screenshot-YYYYMMDDHHMMSS.png')

Options:
  -s, --serial SERIAL
                  Target device serial; must precede arguments or commands.
  -o, --output FILE The path to save the screenshot to.
  --wake            Wake the display before capture (default)
  --no-wake         Do not send KEYCODE_WAKEUP (preserves Wear OS ambient/AOD state)
  --preview         Display a preview of the image using chafa
  --no-preview      Disable preview (default)
  --copy            Copy the image to the clipboard (macOS only)
  --no-copy         Do not copy to clipboard (default)
  -h, --help        Display this help message and exit

Environment:
  ANDROID_SERIAL  Serial number of device to connect to (see 'adb devices -l').
                  The --serial option takes precedence when both are set.

Examples:
  # Save screenshot to a timestamped file in the current directory
  adb-screenshot

  # Save screenshot to a specific file
  adb-screenshot /tmp/my-screenshot.png

  # Capture Wear OS Always-On Display (ambient mode) without waking
  adb-screenshot --no-wake /tmp/ambient.png
```

<!-- /generated -->

**Raw Command**:

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

**Purpose**: Record screen to video file. Automatically detects devices that
require raw frame streaming (e.g., Samsung Wear OS watches) and uses ffmpeg for
capture, while defaulting to scrcpy for standard devices. **Dependencies**:
`adb`, `scrcpy` (for standard devices), `ffmpeg` (for raw capture)

<!-- generated: ../scripts/adb-screenrecord --help -->

```text
Usage: adb-screenrecord [OPTIONS] [FILE]

Records the screen of an adb-connected device. Automatically detects devices
that require raw frame streaming (e.g. Samsung Wear OS watches) and uses ffmpeg
for capture, while defaulting to scrcpy for standard devices.

The screen recording is saved to the specified file, or to a timestamped file
in the current directory if no file is specified. Touches are displayed during
the recording.

Arguments:
  FILE                    The path to save the screen recording to.
                          (defaults to 'adb-screenrecord-YYYYMMDDHHMMSS.mp4')

Options:
  -s, --serial SERIAL     Target device serial; must precede FILE.
  -o, --output FILE       The path to save the screen recording to.
  -t, --duration SECONDS  Max recording duration in seconds.
  --time-limit SECONDS    Alias for --duration.
  --raw                   Force raw frame capture using ffmpeg.
  --no-raw                Disable raw frame capture (force scrcpy).
  -h, --help              Display this help message and exit

Environment:
  ANDROID_SERIAL  Serial number of device to connect to (see 'adb devices -l').
                  The --serial option takes precedence when both are set.

Examples:
  # Save screen recording to a timestamped file in the current directory
  adb-screenrecord

  # Save screen recording for 10 seconds
  adb-screenrecord --duration 10 /tmp/my-screen-recording.mp4

  # Force raw frame capture on any device
  adb-screenrecord --raw --duration 10 /tmp/my-screen-recording.mp4

  # Record from one of several connected devices
  adb-screenrecord -s emulator-5554 /tmp/emulator.mp4
```

<!-- /generated -->

**Raw Command**:

```bash
# Standard devices (scrcpy)
scrcpy --no-audio --no-window -r output.mp4

# Raw frame streaming (Samsung Wear OS watches / fallback)
adb exec-out screenrecord --output-format=raw-frames --size SIZE --bit-rate BITRATE - | ffmpeg -f rawvideo -vcodec rawvideo -s SIZE -pix_fmt rgb24 -use_wallclock_as_timestamps 1 -vsync 0 -i - -an -c:v libx264 -pix_fmt yuv420p -y output.mp4
```

## Tile Management (Wear OS)

### `scripts/adb-tile-add`

**Purpose**: Add a tile or widget component for debugging (SysUI horizontal
carousel by default, or standalone renderer `WidgetTrayActivity` with
`--vertical`). **Dependencies**: `adb`

<!-- generated: ../scripts/adb-tile-add --help -->

```text
Usage: adb-tile-add [OPTIONS] COMPONENT_NAME

Adds a tile provided by COMPONENT_NAME to the carousel. The script automatically
shows the tile after it has been added (no separate call to adb-tile-switch is
needed).

Arguments:
  COMPONENT_NAME  A string composed of the package name and a class in that
                  package, for example:
                  com.example.wear.tiles/com.example.wear.tiles.PreviewTileService

Options:
  -s, --serial SERIAL
                  Target device serial; must precede arguments or commands.
  --vertical      Add the widget to the standalone renderer's vertical carousel
                  (WidgetTrayActivity) instead of the SysUI horizontal carousel.
                  Requires the .emu, .exp, or .dev renderer flavor.
  --type TYPE     Tile type: FULLSCREEN, LARGE (default), or SMALL. Only applies
                  to tiles supporting the BIND_WIDGET_PROVIDER intent (e.g.,
                  Glance-based tiles). With --vertical, only LARGE and SMALL are
                  supported.
  --no-show       Do not show the tile after adding it
  --wait          Wait for the tile to be visible (default); exit 1 if that is
                  not confirmed within 15 seconds
  --no-wait       Do not wait for visibility (return immediately)
  --help          Display this help message and exit

Environment:
  ANDROID_SERIAL  Serial number of device to connect to (see 'adb devices -l').
                  The --serial option takes precedence when both are set.

Examples:
  adb-tile-add com.google.android.wearable.shell/.weather.WeatherTileService
  adb-tile-add --type LARGE com.google.example.wear_widget/.HelloWidgetService
  adb-tile-add --vertical --type SMALL com.google.example.wear_widget/.HelloWidgetService
  adb-tile-add --no-show com.google.example.wear_widget/.HelloWidgetService

Note on Output:
  In default SysUI carousel mode, the script extracts the tile index from the
  system broadcast output (e.g., 'Index=[0]'). 'Index=[0]' means the tile was
  added to the first position in the carousel, pushing others down. It does not
  mean it overwrote previous tiles. Use 'adb-tiles' to list all installed tiles
  and see which are in the carousel.
  In --vertical mode, the script opens WidgetTrayActivity if needed, sends
  ADD_WIDGET to com.google.android.wearable.protolayout.renderer, and prints the
  assigned widgetId (e.g., 'Added/activated widget ID: 10001').
```

<!-- /generated -->

**Raw Command**:

```bash
# Default (SysUI horizontal carousel)
adb shell am broadcast \
  -a com.google.android.wearable.app.DEBUG_SURFACE \
  --es operation add-tile \
  --ecn component "com.example/.MyTileService" \
  --ei type 1

# Vertical carousel (--vertical, requires .emu/.exp/.dev renderer)
adb shell input keyevent KEYCODE_WAKEUP
adb shell am start -W -n com.google.android.wearable.protolayout.renderer/com.google.android.clockwork.prototiles.renderer.experimental.WidgetTrayActivity
adb shell am broadcast \
  -p com.google.android.wearable.protolayout.renderer \
  -a com.google.android.clockwork.prototiles.action.ADD_WIDGET \
  --es component "com.example/.MyWidgetService" \
  --es container_type "LARGE"
```

### `scripts/adb-tile-switch`

**Purpose**: Switch the active tile on the carousel by index. **Dependencies**:
`adb`

<!-- generated: ../scripts/adb-tile-switch --help -->

```text
Usage: adb-tile-switch [OPTIONS] TILE_INDEX

Activates a tile at the specified index. The tile must already have been added
to the carousel (e.g., via 'adb-tile-add').

Note: 'adb-tile-add' shows tiles immediately by default, making this command
primarily useful for switching between already added tiles.

Arguments:
  TILE_INDEX  The index of the tile to activate.

Options:
  -s, --serial SERIAL
                  Target device serial; must precede arguments or commands.
  --help      Display this help message and exit

Environment:
  ANDROID_SERIAL  Serial number of device to connect to (see 'adb devices -l').
                  The --serial option takes precedence when both are set.

Examples:
  adb-tile-switch 0
  adb-tile-switch 1
```

<!-- /generated -->

**Raw Command**:

```bash
adb shell am broadcast \
  -a com.google.android.wearable.app.DEBUG_SYSUI \
  --es operation show-tile \
  --ei index INDEX
```

### `scripts/adb-tile-remove`

**Purpose**: Remove a tile from the SysUI carousel, or widgets from
`WidgetTrayActivity` by ID, component, or all (`--vertical`). **Dependencies**:
`adb`; `jq` for `--vertical`

<!-- generated: ../scripts/adb-tile-remove --help -->

```text
Usage: adb-tile-remove [OPTIONS] COMPONENT_NAME
       adb-tile-remove --vertical WIDGET_ID
       adb-tile-remove --vertical --all

Removes a tile from the SysUI carousel, or widgets from the standalone
renderer's vertical carousel (--vertical).

Arguments:
  COMPONENT_NAME  A string composed of the package name and a class in that
                  package, for example:
                  com.example.wear.tiles/com.example.wear.tiles.PreviewTileService
                  Every instance of the component is removed. With --vertical, a
                  short class name (e.g. WeatherWidgetService) is matched
                  case-insensitively against installed providers.
  WIDGET_ID       A numeric tray widget ID, as printed by 'adb-tiles --vertical'
                  or 'adb-tile-add --vertical'. Use it to remove one instance
                  when a provider has several.

Options:
  -s, --serial SERIAL
                  Target device serial; must precede arguments or commands.
  --vertical      Remove from the standalone renderer's vertical carousel
                  (WidgetTrayActivity) instead of the SysUI horizontal carousel,
                  opening it if needed. Requires the .emu, .exp, or .dev renderer
                  flavor.
  --all           With --vertical, remove every widget in the tray. Requires a
                  recent renderer.
  --help          Display this help message and exit

Environment:
  ANDROID_SERIAL  Serial number of device to connect to (see 'adb devices -l').
                  The --serial option takes precedence when both are set.

Examples:
  adb-tile-remove com.google.android.wearable.shell/.weather.WeatherTileService
  adb-tile-remove --vertical com.google.example.wear_widget/.HelloWidgetService
  adb-tile-remove --vertical 10001
  adb-tile-remove --vertical --all

With --vertical, each removal is reported on stderr (e.g. 'Removed widget ID:
10001' or 'Removed 2 widgets: COMPONENT'), and the exit status is 1 if no tray
widget matched.
```

<!-- /generated -->

**Raw Command**:

```bash
# Default (SysUI horizontal carousel)
adb shell am broadcast \
  -a com.google.android.wearable.app.DEBUG_SURFACE \
  --es operation remove-tile \
  --ecn component "com.example/.MyTileService"

# Vertical carousel (--vertical, by component or widgetId)
adb shell am broadcast \
  -p com.google.android.wearable.protolayout.renderer \
  -a com.google.android.clockwork.prototiles.action.REMOVE_WIDGET \
  --es component "com.example/.MyWidgetService"

# --vertical --all: list the tray, then remove each widgetId
adb shell am broadcast \
  -p com.google.android.wearable.protolayout.renderer \
  -a com.google.android.clockwork.prototiles.action.GET_WIDGETS
adb shell am broadcast \
  -p com.google.android.wearable.protolayout.renderer \
  -a com.google.android.clockwork.prototiles.action.REMOVE_WIDGET \
  --ei widget_id 10001
```

### `scripts/adb-tile-dump`

**Purpose**: Export the Remote Compose document (`.rc`) that
`WidgetTrayActivity` is rendering for a tray widget, and print its rendering
context (screen, container, theme) as JSON. **Dependencies**: `adb`, `jq`

<!-- generated: ../scripts/adb-tile-dump --help -->

```text
Usage: adb-tile-dump [OPTIONS] WIDGET

Exports a tray widget's Remote Compose document (.rc) and prints its rendering
context as JSON.

Arguments:
  WIDGET          A widget in the standalone renderer's vertical carousel
                  (WidgetTrayActivity): a numeric widget ID (see
                  'adb-tiles --vertical') or a component name. A component must
                  match exactly one tray widget; otherwise the matching widget
                  IDs are listed.

Options:
  -s, --serial SERIAL
                  Target device serial; must precede arguments or commands.
  -o, --output FILE
                  Write the document to FILE (default: widget-WIDGET_ID.rc in
                  the current directory). Parent directories are created.
  --help          Display this help message and exit

Environment:
  ANDROID_SERIAL  Serial number of device to connect to (see 'adb devices -l').
                  The --serial option takes precedence when both are set.

Examples:
  adb-tile-dump 10001
  adb-tile-dump -o weather.rc com.google.example.wear_widget/.WeatherWidgetService > weather.meta.json
  adb-tile-dump -o /tmp/w.rc 10001 | jq '.theme["WearM3.primary"]'

The JSON on stdout describes how the document was rendered: screen size and
density, container and content box sizes in dp and px, corner radius, font
scale, time zone offset, the dynamic Material 3 theme colors (theme), and
doc_size_bytes, which the saved file is checked against.

Requires a recent .emu, .exp, or .dev renderer; the tray is opened if needed.
Reading the document off the device requires root: 'adb root' on emulator
images that allow it, or su on userdebug builds. User builds cannot export
documents.
```

<!-- /generated -->

**Raw Command**:

```bash
adb shell am broadcast \
  -p com.google.android.wearable.protolayout.renderer \
  -a com.google.android.clockwork.prototiles.action.DUMP_RC_DOC \
  --ei widget_id 10001
# Reading the file needs root: `adb root` (emulator) or `su 0` (userdebug)
adb exec-out su 0 cat \
  /data/user/0/com.google.android.wearable.protolayout.renderer/cache/10001_rc_doc.rc > widget-10001.rc
```

### `scripts/adb-tiles`

**Purpose**: List tile and widget services and mark those in the SysUI carousel,
or list the widgets in `WidgetTrayActivity` (`--vertical`). **Dependencies**:
`adb`; `jq` for `--vertical`

<!-- generated: ../scripts/adb-tiles --help -->

```text
Usage: adb-tiles [OPTIONS]

Lists the tile and widget services/receivers installed on the connected device,
or the widgets in the standalone renderer's vertical carousel (--vertical).

Options:
  -s, --serial SERIAL
                  Target device serial; must precede arguments or commands.
  --vertical       List widgets in the standalone renderer's vertical carousel
                   (WidgetTrayActivity) instead, opening it if needed. Requires
                   a recent .emu, .exp, or .dev renderer. Cannot be combined
                   with the filter options below.
  --tiles-only     List only tile services
  --widgets-only   List only widget services
  --user-only      List only services from user-installed apps
  --system-only    List only services from system apps
  --carousel-only  List only services currently in the carousel
  --help           Display this help message and exit

Environment:
  ANDROID_SERIAL  Serial number of device to connect to (see 'adb devices -l').
                  The --serial option takes precedence when both are set.

Examples:
  adb-tiles
  adb-tiles --tiles-only
  adb-tiles --carousel-only
  adb-tiles --vertical
  adb-tiles --vertical | awk '$2 == "SMALL" { print $1 }'

Output format:
  [Source][Tile][Widget][Carousel] Component

  Source:   S (System) or U (User)
  Tile:     T or space
  Widget:   W or space
  Carousel: C or space

Output format (--vertical):
  WIDGET_ID TYPE COMPONENT

  WIDGET_ID is the ID accepted by 'adb-tile-remove --vertical' and
  'adb-tile-dump'; TYPE is LARGE or SMALL. Documents uploaded as raw .rc
  files appear with the UploadedDocWidget component.
```

<!-- /generated -->

**Raw Command**:

```bash
adb shell dumpsys wear_service
# (Requires parsing output)

# Vertical carousel (--vertical)
adb shell am broadcast \
  -p com.google.android.wearable.protolayout.renderer \
  -a com.google.android.clockwork.prototiles.action.GET_WIDGETS
```

### `scripts/adb-watchface-set`

**Purpose**: Set the current watch face on a Wear OS device. **Dependencies**:
`adb`

<!-- generated: ../scripts/adb-watchface-set --help -->

```text
Usage: adb-watchface-set [OPTIONS] COMPONENT_NAME

Sets the current watch face on a Wear OS device.

This script is a convenient wrapper around 'adb shell am broadcast' to change
the active watch face. The argument should be the component name of the
watch face service.

Arguments:
  COMPONENT_NAME  Component name of the watch face service
                  (e.g., com.google.android.wearable.app/.watchfaces.GoogleWatchFace)

Options:
  -s, --serial SERIAL
                  Target device serial; must precede arguments or commands.
  --help          Display this help message and exit

Environment:
  ANDROID_SERIAL  Serial number of device to connect to (see 'adb devices -l').
                  The --serial option takes precedence when both are set.

Examples:
  # Set a specific watch face
  adb-watchface-set com.google.android.wearable.app/.watchfaces.GoogleWatchFace
```

<!-- /generated -->

**Raw Command**:

```bash
adb exec-out am broadcast -a com.google.android.wearable.app.DEBUG_SURFACE --es operation set-watchface --es watchFaceId COMPONENT_NAME
```

### `scripts/adb-complication-update`

**Purpose**: Trigger an update for a complication on a Wear OS device.
**Dependencies**: `adb`

<!-- generated: ../scripts/adb-complication-update --help -->

```text
Usage: adb-complication-update [OPTIONS] COMPLICATION_ID

Triggers an update for a specific complication on a Wear OS device.

This script is a convenient wrapper around 'adb shell am broadcast' to force
the system to update a complication's data feed via DEBUG_SYSUI.

Arguments:
  COMPLICATION_ID  Integer ID of the complication to update

Options:
  -s, --serial SERIAL
                  Target device serial; must precede arguments or commands.
  --help          Display this help message and exit

Environment:
  ANDROID_SERIAL  Serial number of device to connect to (see 'adb devices -l').
                  The --serial option takes precedence when both are set.

Examples:
  # Force update complication with ID 1
  adb-complication-update 1
```

<!-- /generated -->

**Raw Command**:

```bash
adb exec-out am broadcast -a com.google.android.wearable.app.DEBUG_SYSUI --es operation complication_update --ei complication_id COMPLICATION_ID
```

## Activity Discovery

### `scripts/adb-activities`

**Purpose**: List activities on the device, tagged by category. By default shows
only user-installed apps (or a specific package when `PACKAGE` is passed).
**Dependencies**: `adb`

<!-- generated: ../scripts/adb-activities --help -->

```text
Usage: adb-activities [OPTIONS] [PACKAGE]

Lists activities declared on the connected device, tagged by category.
By default, lists activities from user-installed (third-party) apps, or from
PACKAGE if specified.

Supported categories:
  L - Launcher (android.intent.category.LAUNCHER)
  H - Home/Launcher App (android.intent.category.HOME)
  T - TV/Leanback (android.intent.category.LEANBACK_LAUNCHER)
  S - Settings (android.intent.category.PREFERENCE)

Arguments:
  PACKAGE          Optional package name to filter activities to.

Options:
  -s, --serial SERIAL
                  Target device serial; must precede arguments or commands.
  --launcher-only  List only launcher activities
  --home-only      List only home/launcher app activities
  --tv-only        List only TV/Leanback activities
  --settings-only  List only settings activities
  --all            List activities from all packages (including system apps)
  -h, --help       Display this help message and exit

Environment:
  ANDROID_SERIAL  Serial number of device to connect to (see 'adb devices -l').
                  The --serial option takes precedence when both are set.

Examples:
  adb-activities
  adb-activities --launcher-only
  adb-activities com.example.app
```

<!-- /generated -->

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

**Purpose**: Dump the UI hierarchy to an XML file with timeout protection and
`--compressed` fallback. **Dependencies**: `adb`, `xmllint`

<!-- generated: ../scripts/adb-uihierarchy --help -->

```text
Usage: adb-uihierarchy [OPTIONS] [FILE]

Dumps the UI hierarchy from an adb-connected device.

The hierarchy is saved to the specified file, or to a timestamped file in the
current directory if no file is specified.

Arguments:
  FILE              The path to save the hierarchy to.
                    (defaults to 'adb-uihierarchy-YYYYMMDDHHMMSS.xml')
                    If '-', the hierarchy is written to stdout.

Options:
  -s, --serial SERIAL
                  Target device serial; must precede arguments or commands.
  -o, --output FILE The path to save the hierarchy to.
                    If '-', the hierarchy is written to stdout.
  --compressed      Skip non-important views during dump (faster on busy UIs).
  --timeout SECONDS Per-attempt timeout in seconds before falling back to
                    compressed mode or aborting (default: 10).
  -h, --help        Display this help message and exit

Environment:
  ANDROID_SERIAL  Serial number of device to connect to (see 'adb devices -l').
                  The --serial option takes precedence when both are set.

Examples:
  # Save hierarchy to a timestamped file in the current directory
  adb-uihierarchy

  # Save hierarchy to a specific file
  adb-uihierarchy /tmp/my-hierarchy.xml

  # Save hierarchy to a specific file using the --output flag
  adb-uihierarchy --output /tmp/my-hierarchy.xml

  # Save hierarchy to stdout
  adb-uihierarchy -
```

<!-- /generated -->

**Raw Command**:

```bash
timeout 10s adb exec-out uiautomator dump /dev/stdout
# (Fallback: uiautomator dump --compressed /dev/stdout; piped to xmllint --format -)
```

### `scripts/adb-currentfocus`

**Purpose**: Display the package name, activity, or UI toolkit of the
application that currently has focus. **Dependencies**: `adb`, `uv`

<!-- generated: ../scripts/adb-currentfocus --help -->

```text
usage: adb-currentfocus [-s SERIAL] [-h] [-p | -a | -t | -d | -j]

Display the package name, activity, or UI toolkit of the application that currently has focus on an adb-connected device.

options:
  -s, --serial SERIAL  Target device serial; specify before other arguments.
                       Overrides ANDROID_SERIAL
  -h, --help           Display this help message and exit
  -p, --packagename    Display the package name of the focused application
                       (default)
  -a, --activity       Display the package and activity name (e.g.
                       com.example/.MainActivity)
  -t, --toolkit        Display the detected UI toolkit (compose, views,
                       hybrid, flutter, react-native, webview, unknown)
  -d, --details        Display a detailed breakdown of the focused application
                       and UI layout
  -j, --json           Output all information as a JSON object

Environment:
  ANDROID_SERIAL  Serial number of device to connect to (see 'adb devices -l').
                  The --serial option takes precedence when both are set.

Examples:
  # Display the focused package name
  adb-currentfocus

  # Check if the current screen is using Jetpack Compose, Views, or Hybrid
  adb-currentfocus --toolkit

  # Display the focused package and activity
  adb-currentfocus --activity

  # Output detailed inspection as JSON
  adb-currentfocus --json
```

<!-- /generated -->

**Raw Commands**:

```bash
# Focused package
adb exec-out dumpsys window displays | grep mCurrentFocus | grep -oE '{.*?}' | awk -F '[{} ]+' '{ print $4 }' | awk -F '/' '{ print $1 }'

# Focused activity
adb exec-out dumpsys window displays | grep mCurrentFocus | grep -oE '{.*?}' | awk -F '[{} ]+' '{ print $4 }'
```

## Package Operations

### `scripts/packagename`

**Purpose**: Unified package management tool. **Dependencies**: `adb`

<!-- generated: ../scripts/packagename --help -->

```text
Usage: packagename [OPTIONS] <command> [arguments]

Android package management utilities via adb.

Commands:
  Process/Lifecycle:
    launch               Launch an application's main activity
    force-stop           Force stop an application
    pid                  Get the process ID of a running package
    logcat               Display logcat filtered by package's PID

  Information:
    dumpsys              Display dumpsys package information (manifest components)
    version              Get the version name and code
    permissions          List declared permissions
    services             List active/running services of a package
    services-dumpsys     Display detailed dumpsys for active services
    jobscheduler         Display jobscheduler information
    tiles                List tiles and widgets provided by a package (Wear OS)

  Profile/Optimization:
    profile-status       Display dex optimization status
    profile-generate     Trigger background dex optimization

  Package Management:
    pull                 Pull the base APK file from the device (-o, --output PATH)
    uninstall            Uninstall a package
    clear-cache          Clear the cache of a package
    reset-permissions    Reset all permissions

  Navigation:
    view                 Open a URL within a package (PACKAGE URL)
    playstore            Open the Play Store page
    settings             Open the settings page

Options:
  -s, --serial SERIAL
                  Target device serial; must precede arguments or commands.
  --help        Display this help message and exit
  --list        List available commands (names only)

Environment:
  ANDROID_SERIAL  Serial number of device to connect to (see 'adb devices -l').
                  The --serial option takes precedence when both are set.

Examples:
  packagename launch com.android.systemui
  packagename version com.google.android.apps.photos
  packagename view com.android.chrome https://www.google.com
  packagename profile-status com.example.app
```

<!-- /generated -->

**Raw Commands**:

```bash
# launch
adb exec-out monkey --pct-syskeys 0 -p PACKAGE -c android.intent.category.LAUNCHER 1

# force-stop
adb exec-out am force-stop PACKAGE

# clear-cache
adb exec-out pm clear PACKAGE

# active/running services
adb exec-out dumpsys activity service PACKAGE

# uninstall
adb uninstall PACKAGE
```

### `scripts/adb-packages`

**Purpose**: List installed packages on the connected device. **Dependencies**:
`adb`

<!-- generated: ../scripts/adb-packages --help -->

```text
Usage: adb-packages [OPTIONS]

Lists installed packages on the connected device.
By default, lists only user-installed (third-party) packages.

Options:
  -s, --serial SERIAL
                  Target device serial; must precede arguments or commands.
  --all       List all packages (including system apps)
  --help      Display this help message and exit

Environment:
  ANDROID_SERIAL  Serial number of device to connect to (see 'adb devices -l').
                  The --serial option takes precedence when both are set.
```

<!-- /generated -->

**Raw Command**:

```bash
adb exec-out pm list packages -3 | cut -b 9- | sort
```

## Raw ADB Commands

Instead of using wrapper scripts, you should use raw ADB commands for simple
one-shot operations. The commands below encode the non-obvious flags and
parsing; there are deliberately no wrapper scripts for them.

### Device & Input

- **List connected device serials** (for `ANDROID_SERIAL`):

  ```bash
  adb devices -l | tail +2 | awk 'length { print $1 }'
  ```

- **Get the device API level:** `adb exec-out getprop ro.build.version.sdk`

- **Wake up / sleep the device:**

  ```bash
  adb exec-out input keyevent KEYCODE_WAKEUP
  adb exec-out input keyevent KEYCODE_SLEEP
  ```

- **Show/hide visual feedback for taps:**

  ```bash
  adb exec-out settings put system show_touches 1   # on
  adb exec-out settings put system show_touches 0   # off
  ```

- **Open a deeplink with a VIEW intent** (use `packagename view PACKAGE URL` to
  target a specific package):

  ```bash
  adb exec-out am start -a android.intent.action.VIEW -c android.intent.category.BROWSABLE -d "https://example.com/deeplink"
  ```

- **Mirror the screen** (interactive; requires scrcpy): `scrcpy --always-on-top`

### Logging

- **Stream logcat filtered by tag:**

  ```bash
  adb logcat -v time "*:S MYTAG"
  ```

### Common System Dumpsys

- **Account information:** `adb exec-out dumpsys account`

- **Battery stats:** `adb exec-out dumpsys batterystats`

- **Power information:** `adb exec-out dumpsys power`

- **Process exit info:** `adb exec-out dumpsys activity exit-info`

- **Battery state simulation:**

  - Unplug charger: `adb exec-out dumpsys battery unplug`
  - Reset charging state: `adb exec-out dumpsys battery reset`

- **Health Tracking GmsModule version (Wear OS):**

  ```bash
  adb exec-out dumpsys activity provider com.google.android.gms.chimera.container.GmsModuleProvider | grep com.google.android.gms.health_tracking__wearable
  ```

### Useful Package and Service Names

When dumping specific services (`adb exec-out dumpsys activity service <NAME>`),
these specific packages/components are very useful to know:

- **Wear Health Services (WHS) Main Service:**
  `com.google.android.wearable.healthservices`
- **WHS RecordingService (for tracking exercises/logs):**
  `com.google.android.wearable.healthservices/.background.service.RecordingService`
- **WearableService (Data Layer):** `WearableService` (e.g.
  `adb exec-out dumpsys activity service WearableService`)
- **Standalone ProtoLayout Renderer / Widget Tray Activity:**
  `com.google.android.wearable.protolayout.renderer/com.google.android.clockwork.prototiles.renderer.experimental.WidgetTrayActivity`
  (renderer package `com.google.android.wearable.protolayout.renderer`,
  supporting vertical tray widgets and `GET_WIDGETS` queries)

## System & Dumpsys

### `scripts/adb-battery-stats`

**Purpose**: Display battery-related information and settings. **Dependencies**:
`adb`

<!-- generated: ../scripts/adb-battery-stats --help -->

```text
Usage: adb-battery-stats [OPTIONS]

Displays battery-related information and settings from an adb-connected device.

Options:
  -s, --serial SERIAL
                  Target device serial; must precede arguments or commands.
  --help      Display this help message and exit

Environment:
  ANDROID_SERIAL  Serial number of device to connect to (see 'adb devices -l').
                  The --serial option takes precedence when both are set.
```

<!-- /generated -->

**Raw Command**:

```bash
adb exec-out dumpsys battery
adb exec-out dumpsys settings | awk -v _match="match" '$2 ~ "name:(" _match ")"'
```

### `scripts/adb-wear-pair`

**Purpose**: Headlessly pair a running Android phone emulator with a Wear OS
watch emulator over TCP port `5601`, or query current pairing state
(`--status`). **Dependencies**: `adb`

<!-- generated: ../scripts/adb-wear-pair --help -->

```text
Usage: adb-wear-pair [OPTIONS]

Headlessly pairs a running Android phone emulator with a Wear OS watch emulator
over TCP, bridging the Wearable Data Layer API without requiring the companion
app.

By default, the script auto-detects one connected phone and one connected watch.
If multiple devices of the same form factor are connected, specify the serials
explicitly.

Options:
  -p, --phone SERIAL  Target phone emulator serial (requires userdebug image).
  -w, --watch SERIAL  Target Wear OS emulator serial.
  --port PORT         TCP port to bridge on the host (default: 5601).
  --status            Display current pairing status instead of pairing.
  -v, --verbose       Include verbose dumpsys output during status checks.
  -h, --help          Display this help message and exit.

Environment:
  ANDROID_PHONE_SERIAL  Serial number of the phone emulator.
  ANDROID_WATCH_SERIAL  Serial number of the watch emulator.
                        Command-line options take precedence when both are set.

Examples:
  adb-wear-pair
  adb-wear-pair --status
  adb-wear-pair -p emulator-5554 -w emulator-5556
```

<!-- /generated -->

**Raw Command**:

```bash
# Query pairing status on an emulator
adb -s SERIAL shell cmd activity broadcast \
  -a com.google.android.gms.wearable.EMULATOR --es operation get-pairing-status

# Refresh emulator TCP connection
adb -s WATCH_SERIAL shell cmd activity broadcast \
  -a com.google.android.gms.wearable.EMULATOR --es operation refresh-emulator-connection
```

## Display & Demo Mode

### `scripts/adb-demo`

**Purpose**: Enable or disable demo mode (clean status bar, 100% battery, 16:20
time, show touches, long screen timeout, DND). **Dependencies**: `adb`

<!-- generated: ../scripts/adb-demo --help -->

```text
Usage: adb-demo [OPTIONS] COMMAND

Enable or disable demo mode on an adb-connected Android device.

Commands:
  on          Enter demo mode:
                - Enables the SystemUI demo mode
                - Sets the clock to 16:20
                - Shows 4G and full mobile level
                - Sets battery to 100% and unplugged
                - Hides notifications and wifi
                - Enables the "Show touches" setting
                - Sets the screen-off timeout to 30 minutes
                - Blocks heads-up notification popups
                - Enables Do Not Disturb (Priority Only)
  off         Exit demo mode:
                - Disables the SystemUI demo mode
                - Disables the "Show touches" setting
                - Restores the screen-off timeout to 1 minute
                - Restores heads-up notification popups to enabled
                - Disables Do Not Disturb (Zen Mode: Off)

Options:
  -s, --serial SERIAL
                  Target device serial; must precede arguments or commands.
  --help      Display this help message and exit

Environment:
  ANDROID_SERIAL  Serial number of device to connect to (see 'adb devices -l').
                  The --serial option takes precedence when both are set.

Examples:
  adb-demo on
  adb-demo off
```

<!-- /generated -->

**Raw Command**:

```bash
# on
adb exec-out settings put global sysui_demo_allowed 1
adb exec-out am broadcast -a com.android.systemui.demo -e command enter
adb exec-out am broadcast -a com.android.systemui.demo -e command clock -e hhmm 1620
# ... (see script for full list of broadcasts and settings)

# off
adb exec-out am broadcast -a com.android.systemui.demo -e command exit
```

### `scripts/adb-fontscale`

**Purpose**: Get or set the system font scale (presets: `default` = 1.0, `large`
= 1.24, or any numeric value). **Dependencies**: `adb`

<!-- generated: ../scripts/adb-fontscale --help -->

```text
Usage: adb-fontscale [OPTIONS] COMMAND [SCALE]

Get or set the system font scale on an adb-connected Android device.

Commands:
  get         Print the current font scale
  set SCALE   Set the font scale to a preset or numeric value

Scales:
  default     Reset to the default scale (1.0)
  large       Large scale (1.24)
  NUMBER      Any numeric scale factor (e.g. 0.85, 1.5)

Options:
  -s, --serial SERIAL
                  Target device serial; must precede arguments or commands.
  --help      Display this help message and exit

Environment:
  ANDROID_SERIAL  Serial number of device to connect to (see 'adb devices -l').
                  The --serial option takes precedence when both are set.

Examples:
  adb-fontscale get
  adb-fontscale set large
  adb-fontscale set 1.5
  adb-fontscale set default
```

<!-- /generated -->

**Raw Command**:

```bash
adb exec-out settings get system font_scale
adb exec-out settings put system font_scale 1.24
```

### `scripts/adb-theme`

**Purpose**: Get or set system theme customization (e.g., 'lemongrass', 'none').
**Requirements**: Wear OS device, API Level 36+ (Android 16) recommended.
**Dependencies**: `adb`, `jq`

<!-- generated: ../scripts/adb-theme --help -->

```text
Usage: adb-theme [OPTIONS] COMMAND [THEME]

Get or set the Android system theme customization via ADB.

Requirements:
  - Wear OS device
  - API Level 36+ (Android 16) recommended (warns if lower)

Commands:
  get         Get the current theme configuration (JSON)
  set THEME   Set the theme to one of the presets

Themes:
  indigo      Vibrant blue
  iris        Expressive purple
  ivy         Spritz dark green
  jade        Tonal spot green
  lemongrass  Expressive yellow-green
  moonstone   Spritz grey-blue
  peony       Vibrant pink
  porcelain   Spritz beige
  watchface   Dynamic colors from home wallpaper
  none        Static grey (reset)

Options:
  -s, --serial SERIAL
                  Target device serial; must precede arguments or commands.
  --help      Display this help message and exit

Environment:
  ANDROID_SERIAL  Serial number of device to connect to (see 'adb devices -l').
                  The --serial option takes precedence when both are set.

Examples:
  adb-theme get
  adb-theme set lemongrass
  adb-theme set none
```

<!-- /generated -->

**Raw Command**:

```bash
# Get current theme
adb exec-out settings get secure theme_customization_overlay_packages | jq .

# Set theme (example)
adb exec-out settings put secure theme_customization_overlay_packages '{"android.theme.customization.theme_style":"EXPRESSIVE",...}'
```

### `scripts/adb-settings-theme`

**Purpose**: Open system theme settings (requires root/debuggable build).
**Dependencies**: `adb`

<!-- generated: ../scripts/adb-settings-theme --help -->

```text
Usage: adb-settings-theme [OPTIONS]

Opens the system theme settings on the connected Android device (Wear OS).
Requires a debuggable build (userdebug/eng) with adb root access.

Options:
  -s, --serial SERIAL
                  Target device serial; must precede arguments or commands.
  --help      Display this help message and exit

Environment:
  ANDROID_SERIAL  Serial number of device to connect to (see 'adb devices -l').
                  The --serial option takes precedence when both are set.
```

<!-- /generated -->

**Raw Command**:

```bash
adb exec-out am start -a com.google.android.clockwork.sysui.ACTION_SYSTEM_THEME_SETTINGS
```

<!-- markdownlint-restore MD013 -->

---
name: wear-widget
description: >-
  Workflows, checklists, and scripts for reverse-engineering, analyzing, and
  extracting Wear OS and Android widgets (Glance, AppWidget, ProtoLayout Tiles).
  Covers manifest declarations, XML configurations, preview asset extraction, and
  AVD rendering. Use when analyzing APK widget features, extracting widget layouts/drawables,
  auditing Wear OS tile services, or converting vector drawables to PNG previews.
compatibility: >-
  Requires apkanalyzer, apktool, and magick (ImageMagick). Optional: popper or adb
  for device automation.
---

# Wear Widget Skill

This skill provides specialized workflows, checklists, and tools for
reverse-engineering, analyzing, and extracting Wear OS and Android widgets.

Use this skill when:

- Analyzing an Android application package (APK) to identify its widget-related
  features.
- Inspecting widget manifest declarations, services, and XML configuration
  files.
- Extracting and rendering widget icons and preview images.
- Developing, testing, or auditing custom Wear OS widgets or tiles.

______________________________________________________________________

## Widget Analysis & Extraction Checklist

Follow this step-by-step methodology when analyzing an APK. Leverage binary
analysis and ADB device management tools where applicable.

### Decompile the APK

Decompile the APK to decode binary manifests, layouts, and resource values into
readable plain-text formats using binary decoding tools (such as `apktool` or
workspace APK helpers):

```bash
apktool d <app_name>.apk -o <output_dir>
```

### Identify Widget Services in the Manifest

Search the decompiled `AndroidManifest.xml` for services or receivers acting as
widget or tile providers:

- **Glance / Wear OS Widgets**:
  `<action android:name="androidx.glance.wear.action.BIND_WIDGET_PROVIDER" />`
- **Standard Android AppWidgets**:
  `<action android:name="android.appwidget.action.APPWIDGET_UPDATE" />`
- **Wear OS Tiles**:
  `<action android:name="androidx.wear.tiles.action.BIND_TILE_PROVIDER" />`
- **Locate Configuration XML**: Find the `<meta-data>` element pointing to the
  XML info file:
  - Glance: `name="androidx.glance.wear.widget.provider"`
  - AppWidget: `name="android.appwidget.provider"`
  - **Resource**: Note the xml resource path (e.g., `@xml/widget_info`, mapping
    to `res/xml/widget_info.xml`).

### Extract and Parse the Configuration XML

Open the resolved XML file in `res/xml/` to extract metadata:

- **Basic Attributes**: Note `label`, `description`, `icon`, and `preferredType`
  (e.g., `SMALL`, `LARGE`).
- **Containers**: Note all supported container sizes/types and their
  corresponding `previewImage` drawables.

### Resolve Resource Strings & Extract Preview Images

- Search `res/values/strings.xml` for any `@string/...` identifiers.
- For each referenced `previewImage` and `icon` drawable:
  - **If Raster (PNG, WebP, JPEG)**: Copy the highest density version (usually
    in `drawable-xxhdpi/` or `drawable-nodpi/`).
  - **If Vector (XML)**: Translate the Android Vector Drawable (AVD) to SVG and
    render it to PNG using the `avd-to-png` tool in `scripts/avd-to-png`.

### Install & Onboard the Corresponding Mobile App

Depending on the task (e.g., if auditing a companion feature requiring active
backend state), you may need the corresponding mobile app installed and
configured in a clean, logged-in state.

1. **Install the Mobile App**: Open the Play Store page directly on the phone
   using
   `adb shell am start -a android.intent.action.VIEW -d "market://details?id=<package_name>"`
   or navigate the Play Store using UI automation tools.
1. **Verify Wear OS Companion App**: Check if installed on the watch via
   `adb -s <watch_serial> shell pm list packages`. If missing, sideload the Wear
   OS APK directly.
1. **Onboard & Log In**: Launch the app and automate onboarding (e.g., using UI
   automation tools like `popper`). Prompt the user for manual help if
   2FA/CAPTCHAs block automation.

______________________________________________________________________

## On-Device APK Preview Metadata & Linking

When deploying Wear Widgets, the OS requires strict metadata declarations and
asset formatting inside the APK. Do not confuse these declaration requirements
with the mechanisms used to generate the asset files (see
[Developer Preview Generation Mechanisms](#developer-preview-generation-mechanisms)).

### Asset Requirements & Rules

- **The `nodpi` Folder Recommendation**: Static raster previews should be placed
  in `nodpi` directories (e.g., `res/drawable-nodpi/`) to ensure the system does
  not attempt density-based scaling at runtime.
- **Strict Qualifier Ordering (Conditional)**: If providing different preview
  resources for different display sizes, Android resource qualifier precedence
  rules apply. The screen width qualifier (`w<N>dp`) takes precedence over pixel
  density (`nodpi`), requiring directory names like
  `res/drawable-w225dp-nodpi/`. The **225dp** threshold is the official
  breakpoint between small and large watch displays.
- **Aspect Ratio & Dimensions**:
  - **Tile Carousel Preview**: Must have a perfect **1:1 (square) aspect ratio**
    at exactly **400x400px** (`res/drawable-nodpi/` declared in
    `AndroidManifest.xml`). The Android build system enforces the
    `TilePreviewImageFormat` lint rule.
  - **Widget Picker Previews (Glance / Provider XML)**: Generated via the
    Rectangular preview parameter suite (`RectangularSmallWidgetPreviewParams`
    and `RectangularLargeWidgetPreviewParams`) at standard watch density (**320
    dpi** / 2.0x scaling):
    - **Small Widget Container (`CONTAINER_TYPE_SMALL`)**: Inner content 192 x
      60 dp with 16 dp H / 12 dp V padding buffers -> Total canvas **224 x 84
      dp** (**448 x 168 px**).
    - **Large Widget Container (`CONTAINER_TYPE_LARGE`)**: Inner content 168 x
      112 dp with 32 dp H / 16 dp V padding buffers -> Total canvas **232 x 144
      dp** (**464 x 288 px**).
- **Full-Bleed & Masking**: Provide perfectly unmasked, rectangular images with
  square corners (`cornerRadius = 0dp`). Let the Wear OS system automatically
  clip the edges to the device's shape. Do not pre-mask background assets into a
  circle or squircle.

### Widget Picker Previews (Glance/AppWidget)

Shown in the native widget picker on devices supporting partial-height widgets
(Wear OS 7+). Previews are linked inside the provider XML configuration file
(`res/xml/my_widget_info.xml`):

```xml
<container
    type="SMALL"
    previewImage="@drawable/my_widget_preview_small" />
<container
    type="LARGE"
    previewImage="@drawable/my_widget_preview_large" />
```

### Tile Carousel Previews

Shown in the tile carousel editor (on-watch) and mobile companion app
(on-phone). On Wear OS 6 or lower, systems run in **compatibility mode** and
translate widgets into full-screen Tiles. Previews are declared in
`AndroidManifest.xml` under the service's `<meta-data>`:

```xml
<meta-data
    android:name="androidx.wear.tiles.PREVIEW"
    android:resource="@drawable/my_widget_tile_preview" />
```

______________________________________________________________________

## Developer Preview Generation Mechanisms

Developers use several mechanisms to preview widgets during development and
testing. Some of these mechanisms can also be used to generate the static
preview image assets embedded in the APK metadata.

### Method 1: Local Code-Based Rendering (Glance/Compose)

If you have a tool that can generate PNGs directly from `@Preview` annotations
without deploying to a device or emulator (such as `compose-preview`):

1. **Define Previews**: Use `@Preview` annotations. For Glance, use
   `RectangularAllWidgetPreviewParams` to generate renders for both sizes, or
   `RectangularSmallWidgetPreviewParams` / `RectangularLargeWidgetPreviewParams`
   for specific sizes.
1. **Workaround for `compose-preview` Bug**: The Gradle plugin currently
   overrides device-less previews in Wear modules to a default watch face canvas
   (227x227 dp), preventing intrinsic cropping.
   - Temporarily remove
     `<uses-feature android:name="android.hardware.type.watch" />` from
     `AndroidManifest.xml` (do not just comment it out).
   - Force re-execution:
     ```bash
     COMPOSE_AI_TOOLS=true ./gradlew :app:composePreviewDiscover
     COMPOSE_AI_TOOLS=true ./gradlew :app:composePreviewRender --rerun-tasks
     ```
   - Copy the generated cropped files from `build/compose-previews/renders/` to
     `res/drawable-nodpi/`.
   - Restore the manifest declaration.

### Method 2: Live Device Capture (Tile Carousel)

Capture the active Tile UI directly from a live emulator or physical device. Use
standard ADB broadcast commands or high-level ADB helper scripts if available in
your workspace:

```bash
# 1. Deploy component enforcing FULLSCREEN translation
adb shell am broadcast \
  -a com.google.android.wearable.app.DEBUG_SURFACE \
  --es operation add-tile \
  --ecn component "<PACKAGE>/<SERVICE_CLASS>" \
  --ei type 0

# 2. Switch active display to the tile index (e.g. index 0)
adb shell am broadcast \
  -a com.google.android.wearable.app.DEBUG_SYSUI \
  --es operation show-tile \
  --ei index 0
sleep 1

# If display is in ambient/dim mode, wake screen with a coordinate tap.
# (ONLY tap if display is currently ambient/dim; DO NOT tap if already active!)
adb shell input tap 227 227
sleep 1

# 3. Capture screenshot (or use workspace screenshot helpers if available)
adb shell screencap -p /sdcard/preview.png && adb pull /sdcard/preview.png preview.png
```

> [!WARNING] Avoid sending unneeded manual input taps to an active display
> during capture, as touches can interact with widget click handlers and trigger
> unexpected UI state reloads or loading spinners.

### Method 3: Standalone Developer Renderer (Widget Tray Viewer)

A preview helper app enabled exclusively on internal/developer builds of the
`com.google.android.wearable.protolayout.renderer` package.

- **Verify Capability**: Check if `versionName` ends in `.exp` (e.g.,
  `1.6.4.2.944934794.exp`) or verify activity presence via
  `adb shell pm resolve-activity -n com.google.android.wearable.protolayout.renderer/com.google.android.clockwork.prototiles.renderer.experimental.WidgetTrayActivity`.
- **Launch Command**:
  ```bash
  adb shell am start -n com.google.android.wearable.protolayout.renderer/com.google.android.clockwork.prototiles.renderer.experimental.WidgetTrayActivity
  ```
- Use UI automation tools for automated interaction inside the renderer list.

______________________________________________________________________

## Device & Emulator Guidelines

### Wear OS Emulator Constraints

- **ProtoLayout Renderer Deadlocks**: Emulators running
  `versionCode < 100051969` (e.g., Stock API 36) encounter IPC deadlocks
  resulting in `Tile was null`. Always target API 37+ or ensure the renderer is
  updated.
- **Package De-isolation**: On API 36 and lower, packages installed via
  `adb install` remain in a `FLAG_STOPPED` state, blocking Binder IPC. Clear
  this by explicitly launching a main activity before testing widgets.

### Samsung Galaxy Watch (One UI Watch) Rules

- **Vertically Scrollable Pages**: Galaxy Watches group multiple stacked widgets
  into a single carousel slot (e.g., the "Basic" page). Audit these metadata
  structures using `adb shell dumpsys wear_service`.
- **Doze Timeout**: Samsung devices transition to ambient mode in 5-10 seconds.
  Capture validation media immediately after rendering.
- **UI Automation for Pickers**: The Samsung picker activity
  (`SecTileComposeAddableActivity`) is private. You can automate the on-screen
  editing interface using UI automation tools (e.g., `popper`):
  - **Add Recipe**:
    1. Switch to target page (e.g., via ADB broadcast
       `DEBUG_SYSUI --es operation show-tile --ei index 3`).
    1. Automate the picker using a UI interaction tool (such as `popper` if
       available):
       ```bash
       popper "Long press the center of the screen, tap the Edit button, scroll down to the bottom of the widget list, tap the '+' Add button. In the Add tiles list, scroll down past 'Featured' and 'Samsung Health' to 'Optimized apps', tap '<App Name>' to expand the accordion, and click the '<Widget Preview Text>' preview widget to add it."
       ```
    1. Return to watch face: `adb shell input keyevent KEYCODE_HOME`
  - **Remove Recipe**:
    1. Switch to target page.
    1. Automate removal using a UI interaction tool:
       ```bash
       popper "Long press the center of the screen, tap the Edit button, scroll to the '<Widget Preview Text>' widget, and tap the red minus icon on its right side to delete it."
       ```
    1. Return to watch face: `adb shell input keyevent KEYCODE_HOME`

### Capturing End-to-End User Interaction Videos

- **UI-Driven Recording over Background Broadcasts**: When capturing video
  recordings for widget audits or deliverables, record the visual UI journey
  on-screen rather than relying solely on silent background broadcast commands.
- **Automating the Picker Journey**: Use UI automation tools (like `popper` or
  scriptable input touch gestures) with `adb-screenrecord` to perform natural
  gestures through the watch interface:
  1. Enable visual touch feedback:
     ```bash
     adb shell settings put system show_touches 1
     ```
  1. Wake screen and establish initial carousel context.
  1. Navigate to the `+ Add` tiles button.
  1. Scroll down the *Add tiles* list to *Optimized apps*, expand the accordion
     item, and tap the widget preview to add it.
  1. Show the widget active and rendered in its carousel slot, and swipe through
     adjacent tiles.

______________________________________________________________________

## Key Gotchas & Best Practices

- **Anti-Pattern: Force-Stopping System Services**: You do NOT need to
  force-stop `com.google.android.gms`, `com.google.android.wearable.app`, or
  `com.google.android.wearable.sysui` after installing a new widget APK. Tile
  bindings resolve identically with or without restarting these processes. Rely
  on standard broadcasts (`add-tile` / `show-tile`) to trigger updates.
- **Official Tile Preview Checklist**:
  - **Dimensions**: Use exactly **400x400px** for the Tile carousel preview
    (`AndroidManifest.xml`).
  - **State**: Show a fully functional, "loaded" or "logged-in" state, avoiding
    empty or placeholder content.
  - **Theme**: Use the tile's static color theme to ensure consistent rendering
    in the editor.

______________________________________________________________________

## Tooling Reference

### `scripts/avd-to-png`

Converts Android Vector Drawable (AVD) XML files to standard SVG and renders
them as high-quality PNG images. Automatically parses `colors.xml` to resolve
color resource references. References to `scripts/...` are relative to this
skill directory.

**Usage**:

```bash
scripts/avd-to-png [options] AVD_FILE RES_DIR
```

**Examples**:

```bash
# Convert vector drawable to PNG using color resources from res/
scripts/avd-to-png -o ./preview-small.png decompiled_app/res/drawable/ic_preview.xml decompiled_app/res
```

______________________________________________________________________

## Reference Material & Reporting

- **[Audit Template](references/audit-template.md)** — Standardized reporting
  template and authoring directives for Wear OS widget and tile integration
  audits.
  - **4-Level Sorting Hierarchy**:
    1. **Service Component**: Self-contained section per declared service (`ServiceClassName`).
    2. **Container Size / Variant**: `LARGE (2x1)` vs `SMALL (1x1)` (with explicit `[NOT DECLARED BY APK]` cards if unsupported).
    3. **Target Platform / Machine**: Organized across Samsung Galaxy Watch (One UI), Google Pixel Watch (Stock Wear OS), and Wear OS Reference Emulator (adaptive multi-column or stacked layout).
    4. **Surface Phase & Operational Mode**: Under each device, capture **(1) System Picker Image**, **(2a) Live In-Use Screenshot**, and **(2b) Live Screencast (Context Video)** across active modes.
  - **Structured Placeholders**: Render explicit `[Pending Capture]` cards with dashed borders for missing/pending slots rather than omitting columns.
  - **Formatted XML**: Format and pretty-print XML declarations with 4-space indentation and one attribute per line for multi-attribute tags.
  - **Media Preservation**: Keep static preview assets unmasked with native aspect ratios.

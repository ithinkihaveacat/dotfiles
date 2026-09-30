---
name: wear-widget
description: >-
  Workflows, checklists, and guides for reverse-engineering, analyzing, and
  developing Wear OS tiles and widgets (ProtoLayout Tiles, Glance for Wear OS,
  and AppWidgets). Covers manifest declarations, container dimensions, preview
  specifications, hosts (SysUI carousel, standalone renderer tray, Samsung
  pages), API gotchas, and audit reporting.
  Use when developing, testing, or reverse-engineering Wear OS tiles or widgets,
  inspecting tile/widget manifests, or auditing Wear OS surface integrations.
compatibility: >-
  Requires apkanalyzer and apktool. Optional: popper or adb for device automation.
---

# Wear OS Tiles & Widgets

This skill provides specialized workflows, checklists, and documentation for
analyzing, testing, and developing Wear OS tiles and widgets (ProtoLayout Tiles,
Glance for Wear OS, and standard AppWidgets).

Use this skill when:

- Analyzing an Android application package (APK) to identify tile or widget
  services and declarations.
- Inspecting tile and widget manifest declarations, configuration XML, and
  preview assets.
- Understanding Wear OS tile and widget host behaviors (SysUI carousel,
  standalone renderer tray, and Samsung One UI Watch pages).
- Developing, testing, or auditing custom Wear OS tiles or widgets.

______________________________________________________________________

## Widget Analysis & Extraction Checklist

Follow this step-by-step methodology when analyzing an APK. Leverage binary
analysis and ADB device management tools where applicable.

### Decompile the APK

Decompile the APK to decode binary manifests, layouts, and resource values into
readable plain-text formats using `apk-decode` (from the `apk` skill):

```bash
apk-decode <app_name>.apk
```

### Identify Tile & Widget Services in the Manifest

Discover tile and widget services or receivers declared in the manifest using
`apk-info tiles` (from the `apk` skill):

```bash
apk-info tiles <app_name>.apk
```

Or inspect the decompiled `AndroidManifest.xml` for specific action filters:

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
    render it to PNG using `avd-to-png` (from the `apk` skill):
    ```bash
    avd-to-png -o preview.png res/drawable/my_preview.xml res
    ```

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
1. **Render Previews**: Use the `compose-preview` skill to render the previews.
   `compose-preview` auto-detects Glance Wear widget previews (such as
   `RectangularSmallWidgetPreviewParams` and
   `RectangularLargeWidgetPreviewParams`) and crops them to the widget bounding
   box without watch canvas padding. If rendering a custom or non-standard
   widget preview that compose-preview does not auto-detect, disable canvas
   retargeting via `retargetWearPreviews = false` in the preview extension or
   pass `-PcomposePreview.retargetWearPreviews=false`.
1. **Copy Assets**: Copy the generated cropped files from
   `build/compose-previews/renders/` to `res/drawable-nodpi/`.

### Method 2: Live Device Capture (Tile Carousel)

Capture the active Tile UI directly from a live emulator or physical device. Use
the `adb` skill helpers (`adb-tile-add`, `adb-tile-switch`, and
`adb-screenshot`):

```bash
# 1. Deploy component enforcing FULLSCREEN translation (automatically shown)
adb-tile-add --type FULLSCREEN "<PACKAGE>/<SERVICE_CLASS>"

# (Optional: switch active display to a specific tile index if needed)
# adb-tile-switch 0

# If display is in ambient/dim mode, wake screen before capture.
# (Do NOT send coordinate taps to an active display; touches trigger click handlers!)
adb shell input keyevent KEYCODE_WAKEUP

# 2. Capture screenshot with circular masking and awake verification
adb-screenshot -o preview.png
```

> [!WARNING] Avoid sending unneeded manual input taps to an active display
> during capture, as touches can interact with widget click handlers and trigger
> unexpected UI state reloads or loading spinners.

### Method 3: Standalone Developer Renderer (Widget Tray Viewer)

`WidgetTrayActivity` is a vertical widget carousel ("tray") inside the
standalone renderer package `com.google.android.wearable.protolayout.renderer`.
While it runs, it registers `WidgetTrayReceiver`, which accepts ADB broadcasts
to add, update, remove, list, and export widgets. This removes the need for UI
automation.

- **Renderer flavors**: The tray ships only in the emulator (`.emu`),
  experimental (`.exp`), and developer (`.dev`) flavors (check the `versionName`
  suffix). Release and `.dogfood` renderers do not have it. Probe for it with:
  ```bash
  adb shell cmd package resolve-activity --brief \
    -n com.google.android.wearable.protolayout.renderer/com.google.android.clockwork.prototiles.renderer.experimental.WidgetTrayActivity
  # Prints the component name if present, or "No activity found"
  ```
- **List, add, remove, and export widgets**: Prefer the `adb` skill helpers when
  they are available in your workspace. They launch the tray if needed, check
  for the tray first, retry until the receiver registers, fail clearly on
  renderers that lack an action, and (for `adb-tile-add`) wait until the widget
  is rendered:
  ```bash
  adb-tile-add --vertical --type LARGE <PACKAGE>/<SERVICE_CLASS>
  # => Added/activated widget ID: 10001
  adb-tiles --vertical                        # list: WIDGET_ID TYPE COMPONENT
  adb-tile-remove --vertical 10001            # by widget ID
  adb-tile-remove --vertical <PACKAGE>/<SERVICE_CLASS>   # all instances
  adb-tile-remove --vertical --all            # empty the tray
  adb-tile-dump -o widget.rc 10001 > widget.meta.json    # export .rc
  ```
- **Raw broadcasts**: Use raw broadcasts for actions the helpers do not cover.
  Always scope them with `-p` to the renderer package. Results are compact JSON
  in the ordered-broadcast `data`: `result=-1` for success, `result=0` for
  errors. A broadcast sent right after `am start` can return `result=0` with no
  data because the receiver is not registered yet, so retry for a few seconds.
  ```bash
  R=com.google.android.wearable.protolayout.renderer
  A=com.google.android.clockwork.prototiles.action
  adb shell am start -W -n $R/com.google.android.clockwork.prototiles.renderer.experimental.WidgetTrayActivity

  # Request fresh content from a widget's provider (by ID or component)
  adb shell am broadcast -p $R -a $A.UPDATE_WIDGET --ei widget_id 10001

  # Render a raw .rc document without installing its app (base64 payload)
  adb shell am broadcast -p $R -a $A.UPLOAD_DOC_WIDGET \
    --es doc_b64 "$(base64 -w0 widget.rc)" --es container_type LARGE
  ```
  Pass widget IDs as integers (`--ei widget_id`). Component names with a `/`
  must match exactly. Short names such as `WeatherWidgetService` are matched
  case-insensitively against installed widget providers.
- **List tray widgets (`GET_WIDGETS`)**: `adb-tiles --vertical` returns every
  widget currently in the tray. Use it (or `adb-tile-remove --vertical --all`)
  to reset the tray before a capture instead of guessing which widgets are left
  over from earlier sessions. Older tray builds do not support `GET_WIDGETS` or
  `DUMP_RC_DOC`; they never answer, and the helpers report that the installed
  renderer needs updating.
- **Export a rendered widget as `.rc` (`DUMP_RC_DOC`)**: `adb-tile-dump` saves
  the Remote Compose document that the tray is currently rendering and prints
  the rendering context as JSON: screen size and density, container and content
  box sizes in dp and px, corner radius, font scale, time zone, and the dynamic
  Material 3 theme colors (`theme`, a map of `WearM3.*` to `#AARRGGBB`). Use it
  to replay a widget exactly as the device rendered it, or to diff documents
  between app versions.
  - A component that matches several tray widgets is rejected with the list of
    matching widget IDs. Pick one and pass the ID.
  - Documents added with `UPLOAD_DOC_WIDGET` show up in `adb-tiles --vertical`
    as
    `.../com.google.android.clockwork.prototiles.renderer.experimental.UploadedDocWidget`
    and can be exported by ID. An exported `.rc` file re-uploads and exports
    back byte-identical, so a document captured on one device can be replayed on
    another.
  - `No active widget found for widgetId N` means the ID is not in the tray.
    `Tile N is not a Remote Compose tile.` also appears while the provider has
    not delivered content yet.
  - **Exporting requires root.** The renderer is a privileged app, so the file
    cannot be read with `run-as`. `adb-tile-dump` uses `adb root` when adbd runs
    as root (emulator images that allow it) or `su` on userdebug devices, and
    checks the byte count against `doc_size_bytes`. User builds cannot export.
- **Logs**: `adb logcat -s WidgetTrayReceiver`. Emulator (`.emu`) builds strip
  info and debug logs, so read results from the broadcast `data` instead.
- **Widget centering**: A single widget at the top of the tray sits above the
  circular center and its top corners can clip against the bezel. Before
  capturing, either swipe down slightly
  (`adb shell input swipe 204 150 204 250 300` on a 408x408 display) or add a
  spacer widget above the target.
- **Screenshot invariant**: Always use `adb-screenshot` (which verifies awake
  state and applies circular masking) rather than raw `screencap` when capturing
  assets for reports or audits.

______________________________________________________________________

## Device & Emulator Guidelines

### Wear OS Emulator Constraints

- **ProtoLayout Renderer Deadlocks**: Emulators running
  `versionCode < 100051969` (e.g., Stock API 36) encounter IPC deadlocks
  resulting in `Tile was null`. Always target API 37+ or ensure the renderer is
  updated.

### Samsung Galaxy Watch (One UI Watch) Rules

- **Vertically Scrollable Pages**: Galaxy Watches group multiple stacked widgets
  into a single carousel slot (e.g., the "Basic" page). Audit these metadata
  structures using `adb shell dumpsys wear_service`.
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

______________________________________________________________________

## Key Gotchas & Best Practices

- **Anti-Pattern: Force-Stopping System Services**: You do NOT need to
  force-stop `com.google.android.gms`, `com.google.android.wearable.app`, or
  `com.google.android.wearable.sysui` after installing a new widget APK; tile
  and widget bindings resolve without restarting these processes. Force-stopping
  these packages is solely a recovery step when System UI fails to sync
  capabilities with GMS Core and renders a default watch face instead of binding
  your service.
- **Mandatory `@AssociateWithGlanceWearWidget` Service Annotation**:
  - Always annotate your `GlanceWearWidgetService` with
    `@AssociateWithGlanceWearWidget(MyWidget::class)`:
    ```kotlin
    @AssociateWithGlanceWearWidget(MyWidget::class)
    class MyWidgetService : GlanceWearWidgetService() {
        override val widget: GlanceWearWidget = MyWidget()
    }
    ```
  - **Why Required**: Glance uses static class analysis to resolve the widget
    provider mapping without instantiating the service. When apps use Dependency
    Injection frameworks (such as Hilt or Dagger) where the `widget` property is
    injected or initialized during service lifecycle attachment, reflective
    service instantiation fails or leaves `widget` uninitialized. The annotation
    guarantees static resolution across build tools, linters, and runtime
    resolvers (`GlanceWearWidgetManager.getProviderForWidget`).
- **Debugging & Updates: `triggerUpdateAll()` vs `fetchActiveWidgets()`**:
  - When triggering updates programmatically (e.g., from broadcast receivers,
    background workers, or interactive debug buttons), prefer
    `myWidget.triggerUpdateAll(context)` over manually iterating over
    `fetchActiveWidgets(widget::class)`.
  - **Why It Matters for Emulators and Testbeds**: `fetchActiveWidgets()`
    queries the platform `TilesManager.getActiveTiles()`. On development
    testbeds or emulators where widgets/tiles are injected via ADB broadcast
    commands (`com.google.android.wearable.app.DEBUG_SURFACE add-tile`),
    `TilesManager` does not register the tile under the app package's UID.
    Consequently, `fetchActiveWidgets()` returns an empty list
    (`Update triggered for 0 active widgets.`), silently dropping updates.
  - `triggerUpdateAll(context)` includes an explicit debug-mode fallback: when
    debugging is detected, it directly queries
    `GlanceWearWidgetManager.getProviderForWidget()` and issues a pull update to
    SysUI (`triggerPullUpdate()`), ensuring dynamic state updates render
    immediately during development and testing.
- **Official Tile Preview Checklist**:
  - **Dimensions**: Use exactly **400x400px** for the Tile carousel preview
    (`AndroidManifest.xml`).
  - **State**: Show a fully functional, "loaded" or "logged-in" state, avoiding
    empty or placeholder content.
  - **Theme**: Use the tile's static color theme to ensure consistent rendering
    in the editor.

______________________________________________________________________

## Reference Material & Reporting

- **[Audit Template](references/audit-template.md)** — Standardized reporting
  template and authoring directives for Wear OS widget and tile integration
  audits.
  - **4-Level Sorting Hierarchy**:
    1. **Service Component**: Self-contained section per declared service
       (`ServiceClassName`).
    1. **Container Size / Variant**: `LARGE (2x1)` vs `SMALL (1x1)` (with
       explicit `[NOT DECLARED BY APK]` cards if unsupported).
    1. **Target Platform / Machine**: Organized across Samsung Galaxy Watch (One
       UI), Google Pixel Watch (Stock Wear OS), and Wear OS Reference Emulator
       (adaptive multi-column or stacked layout).
    1. **Surface Phase & Operational Mode**: Under each device, capture **(1)
       System Picker Image**, **(2a) Live In-Use Screenshot**, and **(2b) Live
       Screencast (Context Video)** across active modes.
  - **Structured Placeholders**: Render explicit `[Pending Capture]` cards with
    dashed borders for missing/pending slots rather than omitting columns.
  - **Formatted XML**: Format and pretty-print XML declarations with 4-space
    indentation and one attribute per line for multi-attribute tags.
  - **Media Preservation**: Keep static preview assets unmasked with native
    aspect ratios.

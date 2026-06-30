---
name: wear-widget
description: Workflows, checklists, and scripts for reverse-engineering, analyzing, and extracting Wear OS and Android widgets, including manifest declarations, XML configurations, and rendering preview assets.
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
- Developing or testing custom Wear OS widgets or tiles.

______________________________________________________________________

## 📋 Widget Analysis & Extraction Checklist

Follow this step-by-step methodology when analyzing an APK:

### 1. Decompile the APK

Decompile the APK to decode binary manifests, layouts, and resource values into
readable plain-text formats:

```bash
apktool d <app_name>.apk -o <output_dir>
```

### 2. Identify Widget Services in the Manifest

Search the decompiled `AndroidManifest.xml` for services or receivers acting as
widget or tile providers:

- **Glance / Wear OS Widgets**: Search for the intent filter action:
  ```xml
  <action android:name="androidx.glance.wear.action.BIND_WIDGET_PROVIDER" />
  ```
- **Standard Android AppWidgets**: Search for the intent filter action:
  ```xml
  <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
  ```
- **Wear OS Tiles**: Search for the intent filter action:
  ```xml
  <action android:name="androidx.wear.tiles.action.BIND_TILE_PROVIDER" />
  ```
- **Locate Configuration XML**: Find the `<meta-data>` element pointing to the
  XML info file:
  - Glance: `name="androidx.glance.wear.widget.provider"`
  - AppWidget: `name="android.appwidget.provider"`
  - **Resource**: Note the xml resource path (e.g., `@xml/widget_info`, mapping
    to `res/xml/widget_info.xml`).

### 3. Extract and Parse the Configuration XML

Open the resolved XML file in `res/xml/` to extract metadata:

- **Basic Attributes**: Note `label`, `description`, `icon`, and `preferredType`
  (e.g., `SMALL`, `LARGE`).
- **Containers**: Note all supported container sizes/types and their
  corresponding `previewImage` drawables.

### 4. Resolve Resource Strings

Search `res/values/strings.xml` for any `@string/...` identifiers found in the
configuration XML to obtain user-visible text (e.g. widget labels,
descriptions).

### 5. Extract and Render Preview Images

For each referenced `previewImage` and `icon` drawable:

- **If Raster (PNG, WebP, JPEG)**: Search the `res/` directory for the file and
  copy the highest density version (usually in `drawable-xxhdpi/` or
  `drawable-nodpi/`).
- **If Vector (XML)**: Translate the Android Vector Drawable (AVD) to SVG and
  render it to PNG using the `avd-to-png` tool.

### 6. Install the Corresponding Mobile App

For features to function correctly in a companion environment (such as Wear OS),
the corresponding mobile app must be installed and configured in a clean,
logged-in state.

1. **Install the Mobile App**:
   - Install the application on the phone **exclusively using the Google Play
     Store** (do not sideload the phone app unless specifically instructed):
     ```bash
     # Launch Play Store on the phone and search/install
     popper --launch com.android.vending "search for '<App Name>', click on the app, click install, and wait for it to finish"
     ```
1. **Verify Wear OS Companion App**:
   - Check if the companion app automatically appears/installs on the connected
     watch:
     ```bash
     adb -s <watch_serial> shell pm list packages | grep <package_name>
     ```
   - **If not found on the watch**, manually sideload the Wear OS companion APK
     (if available) to the watch:
     ```bash
     adb -s <watch_serial> install -g -t -r <wear_os_companion_apk>
     ```
1. **Onboard & Log In**:
   - Launch the app on the phone and complete sign-in to reach the main home
     screen (homepage) in a clean initial state:
     ```bash
     # Launch and automate onboarding/login
     popper --launch <package_name> "use Google sign in or sign up, accept terms, skip onboarding, dismiss popups, and reach the homepage"
     ```
   - **Manual Intervention Guard**: If you encounter authentication barriers
     (like 2FA, password entry, or CAPTCHAs), take a screenshot and prompt the
     user for manual help.

______________________________________________________________________

## 🛠️ Tooling: `avd-to-png`

The `avd-to-png` tool converts Android Vector Drawable (AVD) XML files to
standard SVG and renders them as high-quality PNG images. It automatically
parses `colors.xml` to resolve color resource references and handles 8-digit hex
values.

### Usage

```text
Usage: avd-to-png [options] AVD_FILE RES_DIR

Converts an Android Vector Drawable (AVD) XML file to a standard SVG and renders it to a high-quality PNG.

Arguments:
  AVD_FILE            Path to the Android Vector Drawable (.xml).
  RES_DIR             Path to the Android resource directory (used to resolve @color references).

Options:
  -o, --output PATH   Path to the output PNG file. If not specified, outputs to the current directory with the same basename.
  --help              Display this help message and exit
```

### Examples

1. **Render a vector preview to a specific path**:

   ```bash
   avd-to-png -o ./preview-small.png my_app_decompiled/res/drawable/ic_preview.xml my_app_decompiled/res
   ```

1. **Render a vector preview with default output path** (creates
   `./ic_preview.png`):

   ```bash
   avd-to-png my_app_decompiled/res/drawable/ic_preview.xml my_app_decompiled/res
   ```

______________________________________________________________________

## 🛠️ Developer Workflow: Previews & Screenshots

When developing Wear Widgets, you must provide preview assets for two distinct
surfaces, depending on the device's capabilities and OS version:

1. **Widget Picker (`previewImage` in `widget_info.xml`)**: Shown in the native
   widget picker on devices supporting partial-height widgets (Wear OS 7+).
   Previews must be provided for each supported container size (typically
   `SMALL` and `LARGE`). See the official
   [Get Started with Widgets](https://developer.android.com/training/wearables/widgets/get_started)
   guide for layout details.
1. **Tile Carousel (`androidx.wear.tiles.PREVIEW` in `AndroidManifest.xml`)**:
   Shown in the tile carousel editor (on-watch) and the mobile companion app
   (on-phone). On devices running Wear OS 6 or lower (or Wear OS 7 devices
   without partial-height support), the system runs in **compatibility mode**
   and automatically translates your widget into a full-screen Tile. This
   metadata provides the preview for that translated Tile. See the official
   [Migrate from Tiles to Widgets](https://developer.android.com/training/wearables/widgets/migration)
   guide for service configuration details.

______________________________________________________________________

### 1. Generating Widget Picker Previews (Local)

Use your project's preview rendering tools to generate static assets directly
from your code layout.

#### Step A: Define the Previews in Code

Depending on your framework, define the preview state:

- **Glance (Compose)**: Use standard `@Preview` and `@Composable` annotations.
- **ProtoLayout (Tiles API)**: Use `@Preview` alongside `TilePreviewData` to
  construct layout snapshots.

#### Step B: Render and Export the Previews

Extract the rendered layouts using your IDE's built-in snapshot tools or custom
command-line preview extractors. Export these assets as **WebP** files to
minimize APK bloat.

#### Step C: Register in Widget Info

1. Copy the generated assets to your project's `nodpi` drawable directory (e.g.,
   `res/drawable-nodpi/my_widget_preview_small.webp`). **Do not use default
   density-dependent drawable folders.**
1. Reference them in your widget provider XML (e.g.,
   `res/xml/my_widget_info.xml`):
   ```xml
   <container
       type="SMALL"
       previewImage="@drawable/my_widget_preview_small" />
   <container
       type="LARGE"
       previewImage="@drawable/my_widget_preview_large" />
   ```

______________________________________________________________________

### 2. Capturing Tile Previews (Live Device)

The tile preview shown in the carousel should represent the live rendering of
the tile. Use device interaction tools (like ADB or screenshot helper scripts)
to capture the UI.

> [!NOTE] **Why Tile Commands?** Because Wear Widgets leverage the underlying
> Tile infrastructure for compatibility and debugging, you use the system's Tile
> debugging broadcasts (like `add-tile` and `show-tile`) to deploy and display
> your widget on the device during development.

#### Recommended Workflow:

1. **Deploy the Widget/Tile**: Add the widget to the device's carousel using
   your tool's tile-addition command (specifying the container type if
   necessary).
1. **Switch the Active Display**: Switch the watch screen to display the newly
   added tile.
1. **Capture the Screenshot**: Execute a raw screen capture. Prefer tools that
   automatically handle device wake states and apply a circular mask with a
   transparent background for round watches.
1. **Resize and Register the Asset**:
   - **Resize to 400x400 pixels**: The official recommended size for the Tile
     preview asset is **400x400px** to ensure the best display quality in the
     carousel editor on both watches and phones.
   - Save the screenshot to `res/drawable-nodpi/my_widget_tile_preview.webp`.
   - Register it in `AndroidManifest.xml` under your service's `<meta-data>`:
     ```xml
     <meta-data
         android:name="androidx.wear.tiles.PREVIEW"
         android:resource="@drawable/my_widget_tile_preview" />
     ```

______________________________________________________________________

### 3. Key Gotchas & Best Practices

- **The `nodpi` Requirement**: Always place static raster previews (both widget
  picker and tile previews) in `res/drawable-nodpi/`. Images placed in standard
  density folders (like `drawable/` or `drawable-xxhdpi/`) will be scaled up by
  the system at runtime. For Wear OS displays, scaling a `360x360` image up can
  instantly exceed RemoteViews and Binder IPC memory limits, resulting in a
  rendering crash (often showing a blank background with a warning icon).
- **Strict 1:1 Aspect Ratio**: The Android build system enforces the
  `TilePreviewImageFormat` lint rule. Your registered Tile carousel preview
  image must have a perfect 1:1 (square) aspect ratio, or your build will flag
  an error.
- **Official Tile Preview Checklist**: Follow the guidelines in the official
  [Tile Preview Image Checklist](https://developer.android.com/training/wearables/tiles/get_started#preview-checklist):
  - **Dimensions**: Use exactly **400x400px** for the Tile carousel preview
    (`AndroidManifest.xml`).
  - **State**: Show a fully functional, "loaded" or "logged-in" state, avoiding
    empty or placeholder content.
  - **Theme**: Use the tile's static color theme, not a dynamic one, to ensure
    consistent rendering in the editor.
- **Full-Bleed Backgrounds & Masking**: For full-bleed backgrounds, provide a
  perfectly square image and let the Wear OS system automatically clip the edges
  to the device's shape. Avoid pre-masking background assets into a circle in
  the asset itself, as this introduces edge artifacts across different watch
  shapes.
- **Dark Theme Contrast**: Wear OS operates strictly in a dark theme
  environment. When generating local previews, ensure your layout is explicitly
  rendering against a dark background, and utilize high-contrast text colors
  (e.g., `Color.White.rc`) to match the live watch environment.

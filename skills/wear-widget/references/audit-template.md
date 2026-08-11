# Wear Widget Audit Template

When generating integration reports for Wear OS tiles or widgets, use this
template as a guide. The structure is loose and should be modified as
appropriate for the specific application's features, but you should strive to
capture the core platform specifications, configuration metadata, live device
outputs, and bugs.

### General Presentation Guidelines

- **Folder and Asset Structure**: Each integration audit must be self-contained
  within its own dedicated directory (e.g. `[app_name]/` or `sample/`) organized
  as follows:
  - `index.html`: The HTML version of the report.
  - `index.md`: The Markdown equivalent of the report.
  - `images/`: Subdirectory containing all screenshot and visual assets.
  - `videos/`: Subdirectory containing all video captures and recordings. All
    links inside the HTML and Markdown documents must be relative to ensure
    portability.
- **No Image Masking or Clipping**: All images embedded in the report—both the
  extracted static preview drawables from the APK and the live watch screen
  captures—must be displayed exactly as they are. Do not apply circular viewport
  clipping, `border-radius: 50%`, overlay frames, or black background masks.
  They must appear in their raw aspect ratios and formats as they exist on disk.

### 1. Title & Executive Summary

Start with a descriptive title and a setup summary card containing the
environment specifications.

#### Sample Setup Specifications Table

| Parameter           | Value / Details                                                                                            |
| ------------------- | ---------------------------------------------------------------------------------------------------------- |
| **Package Name**    | `com.example.watch_companion`                                                                              |
| **Phone**           | Google Pixel 7 (panther) / Android 16 (API 36)                                                             |
| **Watch**           | Samsung Galaxy Watch (SM-L340) / Android 17 (API 37)                                                       |
| **Renderer**        | `1.6.4.1.944661784.dogfood` (via watch `dumpsys package com.google.android.wearable.protolayout.renderer`) |
| **Deployment Type** | Play Store install (Phone) / Sideloaded debug build (Watch)                                                |

#### Sample Jetpack Library Dependencies Table

Group relevant Jetpack libraries compiled in the APK under a separate sub-table
(only list libraries that are present in the APK, extracting their versions from
`.version` files under `META-INF/`):

| Jetpack Library Coordinate                   | Bundled Version | Latest Version  |
| -------------------------------------------- | --------------- | --------------- |
| `androidx.glance:glance-wear-tiles`          | `1.0.0-alpha14` | `1.0.0-alpha14` |
| `androidx.wear.tiles:tiles`                  | `1.6.0`         | `1.6.1`         |
| `androidx.wear.protolayout:protolayout`      | `1.4.0`         | `1.4.1`         |
| `androidx.compose.remote:remote-creation`    | `1.0.0-alpha02` | `1.0.0-alpha15` |
| `androidx.compose.remote:remote-player-core` | `1.0.0-alpha02` | `1.0.0-alpha15` |
| `androidx.wear.compose:compose-material3`    | `1.0.0-alpha24` | `1.7.0-alpha06` |
| `androidx.wear.compose:compose-foundation`   | `1.4.0`         | `1.7.0-alpha06` |

### 2. Decompiled Manifest Declarations

Inspect the watch's decompiled `AndroidManifest.xml` and list the registered
widget/tile providers (see Section 2 of the main `SKILL.md` for complete search
details):

- **Component service/receiver name**
- **Layout container type** (Glance Widget, Wear OS Tile, or AppWidget)
- **Intent filter action** (e.g.
  `androidx.glance.wear.action.BIND_WIDGET_PROVIDER`,
  `androidx.wear.tiles.action.BIND_TILE_PROVIDER`, or
  `android.appwidget.action.APPWIDGET_UPDATE`)
- **Associated XML resource metadata configuration** (e.g. `@xml/widget_info`)

### 3. Component Metadata & Resource Analysis

Organize this section **component-by-component**, creating a dedicated
sub-section for each declared component service (e.g. `3.1 ComponentServiceA`,
`3.2 ComponentServiceB`). Do not split previews, XML, or strings out into
separate global sections.

For each component service sub-section, include:

1. **Declared Configuration XML**: Display the preformatted code block of the
   component's manifest `<service>` block and any associated Glance provider XML
   (e.g., `res/xml/widget_info.xml`).
1. **Dereferenced String Resources**: Include a table resolving all referenced
   string resource identifiers (`@string/...`) back to their literal string
   values.
1. **Explicit 3-Slot Static Previews**: Audit and document each of the **3
   potential preview slots** for the component:
   - **Tile Carousel Preview** (`androidx.wear.tiles.PREVIEW`): Declared in
     `AndroidManifest.xml`.
   - **Widget Container Preview (SMALL)**: Declared in provider XML
     (`<container type="SMALL" previewImage="..." />`).
   - **Widget Container Preview (LARGE)**: Declared in provider XML
     (`<container type="LARGE" previewImage="..." />`).

> [!NOTE] If a preview slot is not applicable or not declared (e.g. widget
> containers for standard tiles, or carousel preview omitted for Glance
> widgets), explicitly state `N/A` or `Not Declared`. If an image file is reused
> across multiple slots (e.g. pointing both `SMALL` and `LARGE` container slots
> to the same preview bitmap), explicitly note the asset duplication.

#### Sample Component Sub-Section Layout Structure:

```markdown
#### 3.1 `com.example.service.MyWidgetService` (Glance Wear OS Widget)

##### Component Configuration XML
<pre>
&lt;service android:name="com.example.service.MyWidgetService" ...&gt;
    &lt;intent-filter&gt;
        &lt;action android:name="androidx.glance.wear.action.BIND_WIDGET_PROVIDER"/&gt;
    &lt;/intent-filter&gt;
    &lt;meta-data android:name="androidx.glance.wear.widget.provider" android:resource="@xml/my_widget_info"/&gt;
&lt;/service&gt;
</pre>

##### Dereferenced String Resources

| String Resource Identifier | Resolved Value | Surface Context |
| :--- | :--- | :--- |
| `@string/widget_title` | `"My Widget"` | Widget Title / Header |
| `@string/widget_description` | `"Shows quick summary."` | Widget Description |

##### Declared Static Previews

| Preview Slot | Status | Asset Resource / Details |
| :--- | :--- | :--- |
| **Tile Carousel Preview** (`androidx.wear.tiles.PREVIEW`) | **Not Declared** | None (Omitted from Manifest) |
| **Widget Container (SMALL)** | **Declared & Present** | `@drawable/widget_preview_small` (`400x400 px`) |
| **Widget Container (LARGE)** | **Declared & Present** | `@drawable/widget_preview_small` *(Duplicated Asset)* |
```

### 4. Live Device Screen Captures

Present actual live screenshots and recordings of the tiles/widgets running on
the watch face. Label each capture with the service name that rendered it.

To ensure robust layout validation, **it is highly recommended to collect and
compare media from multiple device environments** (e.g., standard emulators vs.
physical hardware, varying Wear OS API levels, or different OEM system
renderers). If certain environments are unavailable during the initial pass,
structure the report's layout to make space for these additions to be appended
later.

#### Recommended Structure for Multi-Device Layouts:

Group captures under sub-sections corresponding to each test environment, for
example:

- **4.1 Environment A (e.g., Physical Samsung Galaxy Watch SM-L340)**
  - Specify the device model, Wear OS API level, and system renderer.
  - Include successful synced states, logged-out states, and video walkthroughs.
- **4.2 Environment B (e.g., Wear OS API 37 Emulator)**
  - Include corresponding states and interaction loops to highlight any visual
    layout/rendering differences compared to physical hardware.

#### Required Verification Media:

- **Multiple Layout States:** Capture the widget/tile across different runtime
  contexts, including unauthenticated/logged-out states, empty/loading states,
  custom configuration panels, and successful synced states.
- **End-to-End Carousel & Addition Walkthrough Video:** Include a clean MP4
  video (20–60s) capturing the complete user journey of adding and using widgets
  on the watch. To ensure the recording clearly communicates the user experience
  to stakeholders:
  - **Visual Touch Feedback:** Ensure system touch indicators are enabled
    (`settings put system show_touches 1`) so all on-screen taps, long-presses,
    and swipes produce visible touch ripples.
  - **Initial Carousel Context:** Start the recording on the watch face or an
    existing tile page to establish initial context.
  - **On-Screen Picker Navigation:** Record navigating the native device UI to
    add the widget (e.g. tapping `+ Add tiles`, scrolling through the picker
    categories, expanding the app entry under *Optimized apps*, and selecting
    the target widget preview).
  - **Live Render & Carousel Fit:** Show the newly added widget rendered live
    within its slot in the carousel or stacked page layout.
  - **Interactive Navigation:** Perform swipe interactions demonstrating how the
    widget functions and fits among surrounding tiles.
  - **(Optional) Layout Customization:** Demonstrate entering Edit mode
    (long-pressing the page) to reorder or rearrange stacked widgets within a
    multi-widget page layout.
- **Dynamic Interaction Walkthroughs:** Include trimmed MP4 videos demonstrating
  active interaction flows. Highlight specific actions, such as:
  - Tapping a button to launch the main watch application activity.
  - Tapping a button/icon to trigger in-place state mutation (e.g. refreshing
    weather sync data).
  - Transitioning between different page counts or carousel panels.

### 5. Platform & Application Bugs (Optional)

Log any bugs discovered. For each bug:

- Describe the defect and steps to reproduce.
- Embed comparison media (e.g. side-by-side screenshots, trimmed video clips).
- Detail the recommended resolution and assign responsibility (e.g., "Wear
  Widget product team", "App developer engineering").

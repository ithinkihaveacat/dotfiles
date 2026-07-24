# Wear Widget Audit Template

When generating integration reports for Wear OS tiles or widgets, use this
template as a guide. The structure is loose and should be modified as
appropriate for the specific application's features, but you should strive to
capture the core platform specifications, configuration metadata, live device
outputs, and bugs.

### General Presentation Guidelines

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

### 3. Metadata & Resource Analysis

For each widget/tile component, perform a deep analysis of its configuration and
resources:

- **XML Configuration Content:** Display the preformatted code block of the
  configuration XML (e.g. content of `res/xml/widget_info.xml` or manifest
  `<service>` block).
- **String Dereferencing:** Resolve all referenced string resource identifiers
  (e.g. `@string/widget_label` and `@string/widget_description`) back to their
  actual string values defined in `res/values/strings.xml` and document them.
- **Static Preview Extraction:** Locate and copy the static preview images
  (e.g., container-specific layouts or tile fullscreen preview files) from the
  APK layout resource folders (such as `drawable-nodpi/` or
  `drawable-w225dp-nodpi/`). Present these previews side-by-side or alongside
  the configuration code blocks.

### 4. Live Device Screen Captures

Present actual live screenshots and recordings of the tiles/widgets running on
the watch face. Label each capture with the service name that rendered it. To
provide a comprehensive verification of layout states and interactive flows,
strive to include:

- **Multiple Layout States:** Capture the widget/tile across different runtime
  contexts, including unauthenticated/logged-out states, empty/loading states,
  custom configuration panels, and successful synced states.
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

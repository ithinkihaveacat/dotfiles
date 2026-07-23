# Wear Widget Integration Report Template & Sample

When generating integration reports for Wear OS tiles or widgets, use this
template as a guide. The structure is loose and should be modified as
appropriate for the specific application's features, but you should strive to
capture the core platform specifications, configuration metadata, live device
outputs, and bugs.

### 1. Title & Executive Summary

Start with a descriptive title and a setup summary card containing the
environment specifications.

#### Sample Setup Specifications Table

| Parameter                       | Value / Details                                                                                            |
| ------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| **Package Name**                | `com.example.watch_companion`                                                                              |
| **Host Phone**                  | Google Pixel 7 (panther) / Android 16 (API 36)                                                             |
| **Watch Device**                | Samsung Galaxy Watch (SM-L340) / Android 17 (API 37)                                                       |
| **Active Protolayout Renderer** | `1.6.4.1.944661784.dogfood` (via watch `dumpsys package com.google.android.wearable.protolayout.renderer`) |
| **Companion Connection**        | Bluetooth RFCOMM / synced Google Play Services session                                                     |
| **Deployment Type**             | Play Store install (Phone) / Sideloaded debug build (Watch)                                                |

#### Sample Jetpack Library Dependencies Table

Group relevant Jetpack libraries compiled in the APK under a separate sub-table
(only list libraries that are present in the APK, extracting their versions from
`.version` files under `META-INF/`):

| Jetpack Library Coordinate              | Bundled Version |
| --------------------------------------- | --------------- |
| `androidx.glance:glance-wear-tiles`     | `1.0.0-alpha14` |
| `androidx.wear.tiles:tiles`             | `1.6.0`         |
| `androidx.wear.protolayout:protolayout` | `1.4.0`         |

### 2. Decompiled Manifest Declarations

Inspect the watch's decompiled `AndroidManifest.xml` and list the registered
widget/tile providers:

- Component service/receiver name
- Layout container type (Glance Widget, Wear OS Tile)
- Intent filter action and permissions
- Associated XML resource metadata configuration

### 3. Metadata & Resource Analysis

Analyze each configuration XML (e.g. `res/xml/widget_info.xml`) and map out the
supported container size details next to their corresponding static preview
assets (using a side-by-side card layout if possible).

### 4. Live Device Screen Captures

Present actual live screenshots of the tiles/widgets running on the watch face.
Label each capture with the service that rendered it. The captures should
ideally include both screenshots and trimmed videos showing the interaction
flows.

### 5. Platform & Application Bugs (Optional)

Log any bugs discovered. For each bug:

- Describe the defect and steps to reproduce.
- Embed comparison media (e.g. side-by-side screenshots, trimmed video clips).
- Detail the recommended resolution and assign responsibility (e.g., "Wear
  Widget product team", "App developer engineering").

# <App Name> Wear OS Widget & Tile Audit

> [!IMPORTANT] **Raw Source File Required for Complete Instructions**: This
> template embeds extensive authoring guidelines, platform lint rules, and
> section directives formatted as inline HTML comments
> (`<!-- GUIDANCE: ... -->`). Markdown preview renderers (such as GitHub
> preview, IDE viewer tabs, or document exporters) automatically strip these
> comments out. **Be sure to inspect and edit this template in raw source mode**
> so you do not miss critical audit guidance.

> [!NOTE] **Core Reporting Architecture & Sorting Hierarchy** Reports are
> organized following a strict 4-level sorting hierarchy:
>
> 1. **Dimension 1 (Service Component):** Group by Service Class Name
>    (Service-First architecture).
> 1. **Dimension 2 (Container Size / Variant):** Iterate through `LARGE (2x1)`
>    and `SMALL (1x1)` (with explicit `[NOT DECLARED BY APK]` cards if
>    unsupported).
> 1. **Dimension 3 (Target Machine / Device):** Organize targets across Samsung
>    Galaxy Watch, Google Pixel Watch, and Wear OS Reference Emulator (flexible
>    grid or stacked cards).
> 1. **Dimension 4 (Surface Phase & Mode):** Under each device, capture **(1)
>    System Picker Image**, **(2a) Live In-Use Screenshot**, and **(2b) Live
>    Screencast** across all active operational modes (with structured
>    `[Pending Capture]` placeholders for uncaptured slots).

<!-- GUIDANCE: 
  This template is a structured guide and adaptable baseline for Wear OS tile and widget integration audits. 
  It is NOT a rigid straitjacket—feel free to adapt, expand, rearrange, or modify sections where appropriate to accurately capture the specific features, architecture, and bugs of the app under audit.
  
  Report Scope:
  - Focus strictly on glanceable surfaces: Glance Wear Widgets, ProtoLayout Tiles, and AppWidgets.
  - Omit background Watch Face Complication services unless specifically requested.
  - Section headers for component services use a simple descriptive format: {SECTION_NUM}: {SERVICE_NAME} ({SURFACE_TYPE}).
  
  Outcome Terms:
  - For service audit tables, use clear standard status codes such as PASS, FAIL, WARN, or INFO.
-->

**Date:** \<Exact Date, e.g., 12 August 2026>

\<Brief paragraph introducing the app being audited (`<package.name>` version
`<version_string>`), the scope of surfaces analyzed, and what the report
covers.>

______________________________________________________________________

## Executive Summary & Build Metadata

### Executive Summary

<!-- GUIDANCE: 
  Provide a concise summary of the outcome of the audit. Address overall quality, primary issues or spec failures, test environment constraints, and recommended developer action items.
  Pair technical findings directly with their corresponding remediation steps where applicable.
-->

- **Overall Implementation Rating:** **Functional Implementation (Grade
  \<Rating, e.g. B+>)** — Summary of dynamic rendering quality, theme
  consistency, and multi-surface compliance.
- **Key Findings & Developer Action Items:**
  1. **<Issue Title> (\<FAIL|WARN|INFO>):** Description of the issue or
     specification gap identified during analysis.
     - *Action Required:* Recommended fix or developer remediation step.
  1. **\<Test Environment / Architecture Note> (\<FAIL|WARN|INFO>):**
     Description of device or build limitations (e.g. ABI architecture
     dependencies blocking automated testing).
     - *Action Required:* Recommended engineering or build fix.

______________________________________________________________________

### Setup Specifications & Build Metadata

<!-- GUIDANCE: Fill in environment details and package metadata extracted from the APK. -->

- **Package Name:** `<package.name>`
- **Application Version:** `<version_name>` (Version Code: `<version_code>`)
- **SDK Target & Range:**
  - **`minSdkVersion`:** `<api_level>`
  - **`targetSdkVersion`:** `<api_level>`
  - **`compileSdkVersion`:** `<api_level>`
- **Watch Operating Mode:** Standalone Wear OS Companion
  (`com.google.android.wearable.standalone = true|false`)
- **Target APK Path:** `apks/<filename>.apk`
- **Verified Hardware Device:** `<Device Model>` (Android `<OS_Ver>` / API
  `<API_Ver>`, serial `<serial>`)
- **Main Launch Activity:** `<main.activity.ClassName>`
- **Media & Sync Services:**
  <List companion playback or synchronization services if relevant>

### Resource Dimensions & Localization Overview

<!-- GUIDANCE: 
  Provide an overview comparing the language/locale distribution of strings against localized static preview images.
  This allows readers to immediately see whether localized preview assets match string localization coverage or rely on base English fallback resources across non-English locales.
  Sample data is shown below—adjust columns and sample output appropriately for the package under audit.
-->

| Resource Type              | Locales / Directories Supported                                                                                     | Coverage & Asset Distribution Summary                                                                    |
| :------------------------- | :------------------------------------------------------------------------------------------------------------------ | :------------------------------------------------------------------------------------------------------- |
| **String Localization**    | Base English (`res/values/strings.xml`) + 12 Locales (`values-es/`, `values-de/`, `values-fr/`, `values-ja/`, etc.) | Full string translation coverage across 13 total locale trees.                                           |
| **Glance Widget Previews** | Base Default (`res/drawable/shortcut_preview.png`)                                                                  | Single default graphic asset; no language-specific preview drawables provided across translated locales. |
| **Tile Static Previews**   | Shape Qualifiers Only (`drawable-round-v23/`, `drawable-notround-v23/`)                                             | Circular vs square display geometry branching only; previews do not vary by language/locale.             |

### Bundled Jetpack Library Stack

<!-- GUIDANCE: Group relevant Jetpack libraries present in the APK, extracting exact version markers from META-INF/ directories. -->

| Jetpack Library Coordinate                | Bundled Version | Functional Pipeline Role                       |
| :---------------------------------------- | :-------------- | :--------------------------------------------- |
| `androidx.glance.wear:wear`               | `<version>`     | Glance Wear widget framework core              |
| `androidx.wear.tiles:tiles`               | `<version>`     | Full-screen Wear OS Tile service integration   |
| `androidx.wear.protolayout:protolayout`   | `<version>`     | ProtoLayout layout and expression engine       |
| `androidx.wear.compose:compose-material3` | `<version>`     | Native Wear Compose Material design components |

### Surface Catalog

<!-- GUIDANCE: List each distinct glanceable service cataloged from AndroidManifest.xml -->

1. **Glance Wear Widget:** `<ServiceClassName>` (`@xml/<info_xml>`)
1. **ProtoLayout Tile:** `<ServiceClassName>` (`@drawable/<preview_resource>`)

______________________________________________________________________

## Tile & Widget Services

<!-- GUIDANCE: 
  Create a self-contained section per declared service component. 
  Adapt the sub-sections below as appropriate for the component type (Glance Widget vs Tile vs AppWidget).
-->

______________________________________________________________________

### `<Service Simple Name>` (\<Glance Widget | Tile | AppWidget>)

#### Component Identity & Service Purpose

- **Service Class Name:** `com.package.path.<ServiceClassName>`
- **Surface Classification:** \<Glance Wear Widget / Full-Screen Wear OS Tile /
  AppWidget>
- **User Functional Purpose:**
  <Brief explanation of what the surface presents to the user on the watch.>

#### APK Extraction & Manifest Declarations

<!-- GUIDANCE: 
  Display the exact code block as decompiled from AndroidManifest.xml without simplifying attributes, but always pretty-print and format for readability (e.g. 4-space indentation and one attribute per line for multi-attribute tags). Never emit raw single-line XML. Syntax highlighting is not required—prioritize clean formatting and indentation over manual markup.
-->

##### AndroidManifest.xml Service Declaration:

```xml
<service 
    android:enabled="true" 
    android:exported="true" 
    android:label="@string/widget_label" 
    android:name="com.package.path.MyWidgetService" 
    android:permission="com.google.android.wearable.permission.BIND_TILE_PROVIDER">
    <intent-filter>
        <action android:name="androidx.glance.wear.action.BIND_WIDGET_PROVIDER" />
    </intent-filter>
    <meta-data 
        android:name="androidx.glance.wear.widget.provider" 
        android:resource="@xml/my_widget_info" />
    <!-- OPTIONAL: Special Clockwork metadata attribute linking multi-instance stacked page support -->
    <meta-data 
        android:name="com.google.android.clockwork.tiles.MULTI_INSTANCES_SUPPORTED" 
        android:value="true" />
</service>
```

<!-- GUIDANCE: 
  For Glance widgets or AppWidgets, show the exact decompiled XML configuration file from res/xml/. 
  Note the `group="..."` XML attribute if present—this links the Glance capsule widget to its companion full-screen ProtoLayout tile so system pickers group them under the same app accordion item.
  For ProtoLayout Tiles (which declare preview metadata inline in AndroidManifest.xml and do not have a separate res/xml file), note that preview declarations live directly on <meta-data android:name="androidx.wear.tiles.PREVIEW" ... />.
  Format multi-attribute container tags cleanly with one attribute per line.
-->

##### Provider XML Configuration (`res/xml/<info_file>.xml`):

```xml
<?xml version="1.0" encoding="utf-8"?>
<wearwidget-provider 
    xmlns:android="http://schemas.android.com/apk/res/android"
    description="@string/widget_description" 
    group="com.package.path.CompanionTileService"
    icon="@drawable/ic_widget_icon" 
    label="@string/widget_label" 
    preferredType="SMALL">
    <container
        type="SMALL"
        previewImage="@drawable/widget_preview" />
</wearwidget-provider>
```

##### String & Resource Registry:

<!-- GUIDANCE: Dereference referenced string identifiers (@string/...) to their literal values extracted from strings.xml, and include special Clockwork service metadata flags extracted from manifest tags. -->

| Resource / Attribute Identifier                                | Extracted Value / Attribute Metadata |
| :------------------------------------------------------------- | :----------------------------------- |
| `@string/<label_res>`                                          | `"Literal String Value"`             |
| `@string/<description_res>`                                    | `"Literal Description String Value"` |
| `preferredType` / Tile Metadata                                | `[SMALL, LARGE]`                     |
| `com.google.android.clockwork.tiles.MULTI_INSTANCES_SUPPORTED` | `true`                               |

#### Surface Matrix & Multi-Device Verification

<!-- GUIDANCE:
  ========================================================================================
  CORE REPORTING ARCHITECTURE & SORTING HIERARCHY (KEY DIMENSIONS TO SORT ON FIRST)
  ========================================================================================
  Structure all widget audits using this strict 4-level hierarchical breakdown:

  1. Top-Level Dimension (Service Component):
     Group first by Service Class Name (Service-First grouping).
  
  2. Second-Level Dimension (Container Size / Variant):
     For Widget services, iterate through each container variant:
     - LARGE (2x1)
     - SMALL (1x1)
     If a container size is NOT declared in the provider XML, do NOT omit it silently; 
     render an explicit `[NOT DECLARED BY APK]` card so readers know it was audited.

  3. Third-Level Dimension (Source Asset vs Target Machine / Device):
     - First: Source of Truth (APK Declared Static Preview Asset from res/drawable-nodpi/).
     - Next: Multi-Target Device Matrix across all target environments:
       * Samsung Galaxy Watch (One UI Watch)
       * Google Pixel Watch (Stock Wear OS)
       * Wear OS Reference Emulator (AOSP Baseline)
       * (Adaptable: Use a multi-column grid for 2-3 devices, or stacked device cards if >3 devices).

  4. Fourth-Level Dimension (Surface Phase & In-Use Operational Modes):
     Under each device target, provide:
       * (1) System Widget Picker Image: As rendered by that OS's native picker 
             (e.g. SecTileComposeAddableActivity on Samsung, System UI Picker on Pixel). 
             Demonstrates scaling, squashing, letterboxing, or distortion.
       * (2) Widget In Use (Active Mode):
             If multiple operational modes exist (e.g. Authenticated / Logged In, Logged Out / Fallback, 
             Active State, Dark / Light theme), provide:
             - (a) Live In-Use Screenshot: Active widget in carousel on watch face.
             - (b) Live Screencast (Context Video): Screen recording showing interaction, scrolling context, or border behavior.

  5. Placeholders & Missing Media Invariant:
     - If a specific capture is missing or pending (e.g. Pixel Watch Picker, Emulator Live), 
       render an explicit `[Pending Capture]` placeholder card rather than omitting the slot.
     - If an asset is shared/reused across sizes, explicitly display the shared asset in both slots.
-->

##### Container Variant: LARGE (2x1)

- **Container Status:** Declared in XML (`preferredType="LARGE"`)
- **APK Declared Static Preview:**
  `res/drawable-nodpi/my_widget_preview_large.png` (609×378 px, 1.61:1
  rectangular)

###### Source of Truth • APK Declared Static Preview:

![LARGE APK Preview](resources/my_widget_preview_large.png) *Raw static preview
image extracted from `res/drawable-nodpi/`.*

###### Multi-Target Device Matrix:

| Surface / Media Stage                          | Samsung Galaxy Watch (One UI)                                                                                                     | Google Pixel Watch (Wear OS 5.1)                                                        | Wear OS Emulator (API 37)                                   |
| :--------------------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------- | :-------------------------------------------------------------------------------------- | :---------------------------------------------------------- |
| **(1) System Picker Image**                    | ![Samsung Picker](resources/samsung_picker_large.png)<br>*Rendered in `SecTileComposeAddableActivity` (Note squashing/letterbox)* | `[Pending Capture]`<br>*Pixel Watch SysUI Picker*                                       | `[Pending Capture]`<br>*Emulator SysUI Picker*              |
| **(2a) Live Screenshot (Mode: Authenticated)** | ![Samsung Live](resources/samsung_live_large.png)<br>*Boxy card vs native pill styling*                                           | ![Pixel Live](resources/pixel_live_large.png)<br>*Clean single-border rectangular card* | `[Pending Capture]`<br>*AOSP Glance container verification* |
| **(2b) Live Screencast (Context Video)**       | `<video src="resources/samsung_video.mp4" controls />`<br>*Vertical carousel scrolling*                                           | `[Pending Capture]`<br>*Pixel Watch interaction recording*                              | `[Pending Capture]`<br>*Emulator interaction recording*     |

*(Optional: Repeat 2a/2b rows for additional operational modes such as
Unauthenticated / Zero State if applicable.)*

______________________________________________________________________

##### Container Variant: SMALL (1x1)

<!-- GUIDANCE: If declared, repeat the matrix above for SMALL (1x1). If NOT declared in XML, use the block below: -->

- **Container Status:** `[NOT DECLARED BY APK]`
- **Manifest / Provider Analysis:** `res/xml/my_widget_info.xml` only declares
  `<container android:type="LARGE" ... />`. The application does not support or
  provide assets for the `SMALL (1x1)` container variant.

______________________________________________________________________

#### Service Review & Observations

<!-- GUIDANCE: 
  Evaluate the service against relevant platform guidelines, preview formats, container dimensions, visual themes, fallback states, and device behavior. 
  Investigate platform lint requirements (e.g. preview aspect ratios, shape qualifiers, container variants) independently and document findings here.
-->

| Review Dimension                    | Status                 | Specification Audit & Dynamic Hardware Observations                                                                                  |
| :---------------------------------- | :--------------------- | :----------------------------------------------------------------------------------------------------------------------------------- |
| **Container & Size Support**        | **PASS / WARN / FAIL** | Detail container compliance (e.g. missing SMALL container or invalid preferredType).                                                 |
| **Static Preview Compliance**       | **PASS / WARN / FAIL** | Detail APK preview resolution, aspect ratio (1.61:1 vs square), and unmasked full-bleed format.                                      |
| **System Picker Rendering**         | **PASS / WARN / FAIL** | Detail how the preview scales on hardware pickers (e.g. Samsung SecTileComposeAddableActivity squashing / letterboxing b/553584867). |
| **Container & Shape Styling**       | **PASS / WARN / FAIL** | Detail border stroke modifiers, double borders, or shape mismatches vs native OEM container pills.                                   |
| **UI Contrast & Visual Hierarchy**  | **PASS / WARN / FAIL** | Detail text readability, theme contrast, and typography.                                                                             |
| **Multi-Instance & Stack Behavior** | **PASS / WARN / FAIL** | Detail multi-widget stacking behavior and carousel routing.                                                                          |

______________________________________________________________________

<!-- GUIDANCE: Duplicate Section block above for each additional glanceable service provided by the application. -->

*Audit report generated as part of Wear OS Widget Audit Deliverables
(`<app_name>/index.md`).*

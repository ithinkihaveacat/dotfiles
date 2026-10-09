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
> 1. **Dimension 2 (Surface Form & Container Size):** Iterate through all
>    supported surface forms and container sizes:
>    - **Full-Screen Widget (Tile Compatibility Mode):** Standalone full-screen
>      tile translation (on Wear OS $\\le$ 6 or via a FULLSCREEN `DEBUG_SURFACE`
>      `add-tile` broadcast, such as `adb-tile-add --type FULLSCREEN` if
>      available).
>    - **Modular "Real" Widgets:** Partial-height modular containers on Wear OS
>      7+, iterating through `LARGE (2x1)` and `SMALL (1x1)` (with explicit
>      `[NOT DECLARED BY APK]` cards if unsupported).
> 1. **Dimension 3 (Target Machine / Device):** Organize targets across Samsung
>    Galaxy Watch, Google Pixel Watch, and Wear OS Reference Emulator (flexible
>    grid or stacked cards).
> 1. **Dimension 4 (Surface Phase & Operational Mode Permutations):** Under each
>    device, capture **(1) System Picker Image**, **(2a) Live In-Use
>    Screenshot**, and **(2b) Live Screencast** across all active operational
>    modes:
>    - **Logged Out / Onboarding Mode** (unauthenticated fallback state).
>    - **Logged In / Populated Mode** (authenticated content state).
>    - Structured `[Pending Capture]` placeholders for uncaptured slots.

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

<!-- GUIDANCE:
  Fill in environment details and descriptive architectural attributes (D01–D13) extracted from the APK or split-APK bundle.
  Descriptive data is strictly factual/informational rather than pass/fail.
-->

- **Package Name & Version (`D01`):** `<package.name>` | `<version_name>`
  (`versionCode`: `<version_code>`)
- **SDK Version Tuple (`D02`):** `minSdk <api_level>` / `targetSdk <api_level>`
  / `compileSdk <api_level>`
- **Standalone Operating Mode (`D03`):**
  `com.google.android.wearable.standalone = true|false` (`true` = standalone
  watch app; `false` = requires paired phone companion)
- **Packaging Architecture (`D04`):**
  `<Monolithic standalone APK | Modular Split-APK Bundle (base.apk + config.*.apk splits)>`
- **Adaptive Layout Strategy (`D10`):**
  `<Container-size branching (SMALL/LARGE), dynamic WearWidgetParams width/height flexing, w225dp qualifiers, or fixed single-size layout>`
- **Color Palette & Theme Strategy (`D11`):**
  `<Dynamic system tokens (WearM3 / remoteColorScheme), static app brand colors, or hybrid (system surface container + brand accents)>`
- **Target APK / Bundle Path:** `apks/<filename>.apk`
- **Verified Hardware Device(s):** `<Device Model>` (Android `<OS_Ver>` / API
  `<API_Ver>`, serial `<serial>`)
- **Main Launch Activity:** `<main.activity.ClassName>`
- **Media & Sync Services:**
  `<List companion playback or synchronization services if relevant>`
- **Remote Compose Payload Archival (`D13`):**
  `<Status and relative paths of exported binary .rc / .rcdoc payloads captured via DUMP_RC_DOC (or adb-tile-dump if available) for deterministic replay and regression diffing>`

### Resource Dimensions & Localization Overview (`D12`)

<!-- GUIDANCE: 
  Provide an overview comparing string translation coverage (res/values-<locale>/ directories or language split APKs) against localized static preview image directories (D12).
  Note whether widget body copy or labels contain hardcoded strings in bytecode that bypass resource localization.
  Sample data is shown below—adjust columns and sample output appropriately for the package under audit.
-->

| Resource Type              | Locales / Directories Supported                                                                                     | Coverage & Asset Distribution Summary                                                                    |
| :------------------------- | :------------------------------------------------------------------------------------------------------------------ | :------------------------------------------------------------------------------------------------------- |
| **String Localization**    | Base English (`res/values/strings.xml`) + 12 Locales (`values-es/`, `values-de/`, `values-fr/`, `values-ja/`, etc.) | Full string translation coverage across 13 total locale trees.                                           |
| **Glance Widget Previews** | Base Default (`res/drawable-nodpi/shortcut_preview.png`)                                                            | Single default graphic asset; no language-specific preview drawables provided across translated locales. |
| **Tile Static Previews**   | Shape Qualifiers Only (`drawable-round-v23/`, `drawable-notround-v23/`)                                             | Circular vs square display geometry branching only; previews do not vary by language/locale.             |

### Bundled Jetpack Library Stack (`D05–D06`)

<!-- GUIDANCE:
  Extract exact library version markers from META-INF/*.version files across the APK or split bundle (note if obfuscated or stripped):
  - D05: Glance Wear, Remote Compose, Compose UI, and Wear Compose Material 3 versions.
  - D06: Wear Tiles and ProtoLayout engine versions.
-->

| Jetpack Library Coordinate                | Bundled Version | Functional Pipeline Role                        |
| :---------------------------------------- | :-------------- | :---------------------------------------------- |
| `androidx.glance.wear:wear`               | `<version>`     | Glance Wear widget framework core (`D05`)       |
| `androidx.compose.remote:*`               | `<version>`     | Remote Compose creation & player stack (`D05`)  |
| `androidx.compose.ui:ui`                  | `<version>`     | Jetpack Compose UI foundation (`D05`)           |
| `androidx.wear.compose:compose-material3` | `<version>`     | Native Wear Compose Material components (`D05`) |
| `androidx.wear.tiles:tiles`               | `<version>`     | Full-screen Wear OS Tile integration (`D06`)    |
| `androidx.wear.protolayout:protolayout`   | `<version>`     | ProtoLayout layout & expression engine (`D06`)  |

### Surface Catalog & Multi-Instance Architecture (`D07–D09`)

<!-- GUIDANCE:
  Catalog all glanceable services declared in AndroidManifest.xml and their provider XML configurations:
  - D07: GlanceWearWidgetService components (androidx.glance.wear.action.BIND_WIDGET_PROVIDER) with supported container sizes (marking preferredType as default).
  - D08: ProtoLayout TileService components (androidx.wear.tiles.action.BIND_TILE_PROVIDER) and surface support.
  - D09: Whether com.google.android.clockwork.tiles.MULTI_INSTANCES_SUPPORTED is set to true per service.
-->

1. **Glance Wear Widget (`D07`):** `com.package.path.<WidgetService>`
   (`@xml/<info_xml>` — Supported sizes: `LARGE (default), SMALL`;
   Multi-instance `D09`: `true|false`)
1. **ProtoLayout Tile (`D08`):** `com.package.path.<TileService>`
   (`@drawable/<preview_resource>` — Supported sizes: `FULLSCREEN (default)`;
   Multi-instance `D09`: `true|false`)

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
  
  2. Second-Level Dimension (Surface Form & Container Size Permutations):
     Widgets can appear across multiple distinct presentation forms, and audits must capture all permutations:
     - Form A: Full-Screen Standalone Tile (Tile Compatibility Mode)
       Enforced on Wear OS <= 6 or verified on Wear OS 7+ via a FULLSCREEN (type 0) `DEBUG_SURFACE` `add-tile` broadcast (or `adb-tile-add --type FULLSCREEN` if available).
       Audits whether the glanceable layout gracefully scales to a full display canvas.
     - Form B: Modular "Real" Widgets
       On Wear OS 7+, iterate across every supported container size declared in the provider XML:
       * LARGE (2x1)
       * SMALL (1x1)
       If a container size is NOT declared in the provider XML, do NOT omit it silently; 
       render an explicit `[NOT DECLARED BY APK]` card so readers know it was audited.
     Capture ALL permutations across full-screen tile compat and modular containers.

  3. Third-Level Dimension (Source Asset vs Target Machine / Device):
     - First: Source of Truth (APK Declared Static Preview Asset from res/drawable-nodpi/).
     - Next: Multi-Target Device Matrix across all target environments.
     - Mandatory Device Header Rule: Always state the explicit device model, OS/skin version, AND API level 
       (e.g., `Samsung Galaxy Watch (One UI Watch 7 / API 37)`, `Google Pixel Watch 4 (Wear OS 5.1 / API 37)`).
       This prevents ambiguity between Wear OS <= 6 compatibility mode (full tiles) and Wear OS >= 7 modular widgets.

  4. Fourth-Level Dimension (Surface Phase & Operational Mode Permutations):
     Under each device target, capture:
       * (1) System Widget Picker Image: As rendered by that OS's native picker 
             (e.g. SecTileComposeAddableActivity on Samsung, System UI Picker on Pixel). 
             Demonstrates scaling, squashing, letterboxing, or distortion.
       * (2) Widget In Use (Active Mode):
             Capture ALL operational mode permutations:
             - Mode A: Unauthenticated / Logged Out / Fallback (empty onboarding state).
             - Mode B: Authenticated / Logged In / Content (active data state).
             For each mode, provide:
             - (a) Live In-Use Screenshot: Active widget in carousel on watch face (captured with awake verification and circular display masking, e.g., via `adb-screenshot` if available).
             - (b) Live Screencast (Context Video): Screen recording showing interaction, scrolling context, or border behavior.

  5. Layout Adaptability & Centering Invariant (WidgetTrayActivity Spacer Pattern):
     - When capturing modular widgets within the developer testbed (`WidgetTrayActivity`), widget cards at the
       top of the list are pushed into the top half of the display above the circular center line.
     - Centering Technique: Add a separate "spacer" widget (e.g., from `wear-os-samples/WearWidget`, such as
       `SampleWidgetService`) above the target widget to shift it down into the vertical center slot of the
       round screen before taking a circular-masked screenshot (e.g., with `adb-screenshot` if available).
     - Alternatively, deploy the surface directly to the carousel via a `DEBUG_SURFACE` `add-tile` broadcast (or `adb-tile-add --type LARGE` if available) to capture
       the native OEM presentation.

  6. Placeholders & Missing Media Invariant:
     - If a specific capture is missing or pending (e.g. Pixel Watch Picker, Emulator Live), 
       render an explicit `[Pending Capture]` placeholder card rather than omitting the slot.
     - If an asset is shared/reused across sizes, explicitly display the shared asset in both slots.
-->

##### Surface Form: Full-Screen Standalone Tile (Tile Compatibility Mode)

<!-- GUIDANCE: 
  Audit the full-screen presentation mode enforced on Wear OS <= 6 or tested via a FULLSCREEN (type 0) `DEBUG_SURFACE` `add-tile` broadcast (or `adb-tile-add --type FULLSCREEN` if available).
  Verify whether glanceable layouts, margins, and curved text elements adapt properly to the full 400x400 / 408x408 canvas.
-->

- **Compatibility Mode Status:** Supported via Tile Provider Binding
  (`BIND_TILE_PROVIDER`)
- **APK Declared Static Tile Preview:**
  `res/drawable-nodpi/my_widget_tile_preview.png` (400×400 px, 1:1 square)

###### Source of Truth • APK Declared Tile Preview:

![Tile APK Preview](resources/my_widget_tile_preview.png) *Raw static preview
image extracted from `res/drawable-nodpi/`.*

###### Multi-Target Device Matrix (Full-Screen Compat):

| Surface / Media Stage                  | Samsung Galaxy Watch (One UI 7 / API 37) | Google Pixel Watch 4 (Wear OS 5.1 / API 37) | Wear OS Emulator (AOSP / API 37) |
| :------------------------------------- | :--------------------------------------- | :------------------------------------------ | :------------------------------- |
| **(1) Tile Editor Picker**             | `[Pending Capture]`                      | `[Pending Capture]`                         | `[Pending Capture]`              |
| **(2a) Full-Screen Live (Logged Out)** | `[Pending Capture]`                      | `[Pending Capture]`                         | `[Pending Capture]`              |
| **(2b) Full-Screen Live (Logged In)**  | `[Pending Capture]`                      | `[Pending Capture]`                         | `[Pending Capture]`              |

______________________________________________________________________

##### Container Variant: LARGE (2x1)

- **Container Status:** Declared in XML (`preferredType="LARGE"`)
- **APK Declared Static Preview:**
  `res/drawable-nodpi/my_widget_preview_large.png` (609×378 px, 1.61:1
  rectangular)

###### Source of Truth • APK Declared Static Preview:

![LARGE APK Preview](resources/my_widget_preview_large.png) *Raw static preview
image extracted from `res/drawable-nodpi/`.*

###### Multi-Target Device Matrix (Standard 2–3 Device Table Format):

| Surface / Media Stage                          | Samsung Galaxy Watch (One UI 7 / API 37)                                                                                          | Google Pixel Watch 4 (Wear OS 5.1 / API 37)                                             | Wear OS Emulator (AOSP / API 37)                            |
| :--------------------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------- | :-------------------------------------------------------------------------------------- | :---------------------------------------------------------- |
| **(1) System Picker Image**                    | ![Samsung Picker](resources/samsung_picker_large.png)<br>*Rendered in `SecTileComposeAddableActivity` (Note squashing/letterbox)* | `[Pending Capture]`<br>*Pixel Watch SysUI Picker*                                       | `[Pending Capture]`<br>*Emulator SysUI Picker*              |
| **(2a) Live Screenshot (Mode: Authenticated)** | ![Samsung Live](resources/samsung_live_large.png)<br>*Boxy card vs native pill styling*                                           | ![Pixel Live](resources/pixel_live_large.png)<br>*Clean single-border rectangular card* | `[Pending Capture]`<br>*AOSP Glance container verification* |
| **(2b) Live Screencast (Context Video)**       | `<video src="resources/samsung_video.mp4" controls />`<br>*Vertical carousel scrolling*                                           | `[Pending Capture]`<br>*Pixel Watch interaction recording*                              | `[Pending Capture]`<br>*Emulator interaction recording*     |

###### Alternative: Stacked Device Card Format (Recommended for >3 Target Devices):

<!-- GUIDANCE: If auditing >3 devices, use this stacked card layout instead of a wide table: -->

> **1. Samsung Galaxy Watch (One UI Watch 7 / API 37 - SM-L340)**
>
> - **(1) System Picker Image:**
>   ![Samsung Picker](resources/samsung_picker_large.png) *(Squashed /
>   letterboxed in `SecTileComposeAddableActivity`)*
> - **(2a) Live In-Use Screenshot (Authenticated):**
>   ![Samsung Live](resources/samsung_live_large.png) *(Boxy card vs native pill
>   styling)*
> - **(2b) Live Screencast:**
>   `<video src="resources/samsung_video.mp4" controls />`
>
> **2. Google Pixel Watch 4 (Wear OS 5.1 / API 37)**
>
> - **(1) System Picker Image:** `[Pending Capture: Pixel Watch SysUI Picker]`
> - **(2a) Live In-Use Screenshot (Authenticated):**
>   ![Pixel Live](resources/pixel_live_large.png) *(Clean single-border card)*
> - **(2b) Live Screencast:** `[Pending Capture: Pixel Watch Screencast]`
>
> **3. Wear OS Reference Emulator (AOSP API 37 Baseline)**
>
> - **(1) System Picker Image:** `[Pending Capture: Emulator SysUI Picker]`
> - **(2a) Live In-Use Screenshot (Authenticated):**
>   `[Pending Capture: Emulator Live]`
> - **(2b) Live Screencast:** `[Pending Capture: Emulator Screencast]`

______________________________________________________________________

##### Container Variant: SMALL (1x1)

<!-- GUIDANCE: If declared, repeat the matrix above for SMALL (1x1). If NOT declared in XML, use the block below: -->

- **Container Status:** `[NOT DECLARED BY APK]`
- **Manifest / Provider Analysis:** `res/xml/my_widget_info.xml` only declares
  `<container android:type="LARGE" ... />`. The application does not support or
  provide assets for the `SMALL (1x1)` container variant.

______________________________________________________________________

#### Launch-Readiness Evaluation Checklist (`C01–C19`)

<!-- GUIDANCE: 
  Evaluate the application and service across all 19 standardized launch-readiness quality gates (C01–C19).
  Use status prefixes `PASS`, `WARN`, `FAIL`, or `N/A` alongside concise, evidence-backed observations.
  Verification sources combine static APK/DEX inspection (`apkanalyzer`, `aapt2`, `dexdump -d -a`, image header/pixel inspection, or a unified static audit script if available) with live device testing (`DEBUG_SURFACE add-tile` / `WidgetTrayActivity`, `pm clear`, and masked screenshots).
-->

| ID        | Category               | Criterion                                        | Allowed Status         | Evaluation Rule & Evidence                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| :-------- | :--------------------- | :----------------------------------------------- | :--------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **`C01`** | **Build & ABI Gates**  | **Target SDK >= 34**                             | **PASS / FAIL**        | `PASS` if `targetSdkVersion >= 34` in `AndroidManifest.xml` (Wear OS 5+ ready).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| **`C02`** | **Build & ABI Gates**  | **64-Bit ABI Support**                           | **PASS / FAIL**        | `PASS` if pure Kotlin/Java or bundles `arm64-v8a` native libraries in `lib/`; `FAIL` if 32-bit `armeabi-v7a` only (blocks installation on API 37+ `arm64` emulators).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| **`C03`** | **Build & ABI Gates**  | **Glance Wear Library**                          | **PASS / WARN**        | `PASS` if `androidx.glance.wear:wear >= 1.0.0-alpha14` in `META-INF/*.version` (includes modern preview and Remote Compose fixes); `WARN` if older alpha.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| **`C04`** | **Manifest & Config**  | **`BIND_TILE_PROVIDER` Permission**              | **PASS / FAIL**        | `PASS` if `<service>` declares `android:exported="true"` AND `android:permission="com.google.android.wearable.permission.BIND_TILE_PROVIDER"`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| **`C05`** | **Manifest & Config**  | **No Redundant Tile Metadata**                   | **PASS / WARN**        | `PASS` if Glance widget declares `androidx.glance.wear.widget.provider` without a redundant or conflicting `androidx.wear.tiles.PREVIEW` `<meta-data>` tag.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| **`C06`** | **Manifest & Config**  | **`@AssociateWithGlanceWearWidget` & R8 Safety** | **PASS / WARN / FAIL** | Inspect `<service>` class blocks via `dexdump -d -a`: `PASS` if (a) each `GlanceWearWidgetService` subclass retains a `VISIBILITY_RUNTIME` class annotation referencing its `GlanceWearWidget` subclass without R8 horizontal class merging across distinct widgets, or (b) the app never calls programmatic update APIs (`triggerUpdate`, `triggerUpdateAll`, `fetchActiveWidgets`), allowing R8 dead-code elimination to strip the unused mapping safely; `WARN` if programmatic updates are called without the annotation in DEX but no-arg reflective `<init>()` instantiation succeeds without field injection; `FAIL` if programmatic updates are called and either reflective `<init>()` throws due to uninitialized DI fields (e.g., Hilt/Dagger/Koin) or R8 horizontally merges distinct `GlanceWearWidget` classes into one class descriptor. |
| **`C07`** | **Manifest & Config**  | **Config Activity Categories**                   | **PASS / FAIL / N/A**  | If `configIntentAction` is declared, `PASS` if the target `<activity>` declares BOTH `androidx.wear.tiles.category.PROVIDER_CONFIG` and `com.google.android.clockwork.tiles.category.PROVIDER_CONFIG` intent-filter categories to prevent System UI launch failures (`N/A` if no custom configuration activity is used).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| **`C08`** | **Manifest & Config**  | **Provider Group Deduplication**                 | **PASS / WARN**        | `PASS` if `<wearwidget-provider>` in `res/xml/<info>.xml` declares `group="..."` linking its companion `TileService` so system pickers group them under one app accordion without duplicate entries.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| **`C09`** | **Manifest & Config**  | **`SMALL` & `LARGE` Containers**                 | **PASS / WARN / FAIL** | `PASS` if both `SMALL` (`1x1`) and `LARGE` (`2x1`) `<container>` elements are declared in `res/xml/<info>.xml`; `WARN` if single container size only; `FAIL` if primary widget omits `LARGE`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| **`C10`** | **Static Previews**    | **Preview Density Qualifier (`nodpi`)**          | **PASS / FAIL**        | `PASS` if static raster preview assets reside in `res/drawable-nodpi/` (or `res/drawable-w225dp-nodpi/`) to prevent runtime density scaling overhead or out-of-memory failures.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| **`C11`** | **Static Previews**    | **Tile Preview (`400x400 px`)**                  | **PASS / WARN**        | `PASS` if full-screen Tile preview (`androidx.wear.tiles.PREVIEW`) is an exact 1:1 square at `400x400 px` (`TilePreviewImageFormat` lint rule).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| **`C12`** | **Static Previews**    | **`SMALL` Preview Aspect Ratio (`~2.67:1`)**     | **PASS / FAIL / N/A**  | `PASS` if `SMALL` preview matches the `~2.67:1` rectangular target (e.g., `448x168 px`); `FAIL` if a 1:1 square image is reused (`N/A` if `SMALL` is undeclared).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| **`C13`** | **Static Previews**    | **`LARGE` Preview Aspect Ratio (`~1.61:1`)**     | **PASS / FAIL / N/A**  | `PASS` if `LARGE` preview matches the `~1.61:1` rectangular target (e.g., `464x288 px` or `609x378 px`); `FAIL` if a 1:1 square image is reused (`N/A` if `LARGE` is undeclared).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| **`C14`** | **Static Previews**    | **Preview Asset Uniqueness**                     | **PASS / FAIL**        | `PASS` if distinct preview bitmaps (verified by SHA-256 hash) are provided per service and declared container size without duplicate picker previews.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| **`C15`** | **Static Previews**    | **Unmasked Full-Bleed Corners**                  | **PASS / WARN**        | `PASS` if preview image is an unmasked full-bleed rectangle with opaque corners (`cornerRadius = 0dp`) so host OS pickers mask edges cleanly; `WARN` if pre-masked into a circular disc or pill capsule with transparent corners.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| **`C16`** | **Runtime UI Quality** | **Broadcast Bind & Render**                      | **PASS / FAIL**        | `PASS` if service binds and renders non-empty UI within 3s of a `DEBUG_SURFACE add-tile` broadcast (or `adb-tile-add` if available) without returning a null tile or crashing.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| **`C17`** | **Runtime UI Quality** | **No Custom Outer Border**                       | **PASS / FAIL**        | `PASS` if widget does not draw a custom Composable outer border stroke (avoiding double outlines on squircle/rectangular hosts and boxy framing clashes inside pill-shaped OEM containers).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| **`C18`** | **Runtime UI Quality** | **No Text or Button Clipping**                   | **PASS / FAIL**        | `PASS` if text and action buttons fit cleanly without ellipsis truncation (e.g., `'. .'`) in `SMALL` slots or vertical bottom clipping inside multi-widget stacks and narrow round displays.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| **`C19`** | **Runtime UI Quality** | **Logged-Out Fallback UI**                       | **PASS / FAIL**        | `PASS` if widget displays a clear, actionable unauthenticated fallback prompt (e.g., `'Log in'` / `'Set up'`) after clearing app storage (`adb shell pm clear`) without rendering a blank card or crashing.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |

______________________________________________________________________

<!-- GUIDANCE: Duplicate Section block above for each additional glanceable service provided by the application. -->

*Audit report generated using the Wear OS Widget & Tile Audit Template
(`<app_name>/index.md`).*

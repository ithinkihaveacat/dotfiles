# <App Name> Wear OS Widget & Tile Audit

> [!IMPORTANT] **Raw Source File Required for Complete Instructions**: This
> template embeds extensive authoring guidelines, platform lint rules, and
> section directives formatted as inline HTML comments
> (`<!-- GUIDANCE: ... -->`). Markdown preview renderers (such as GitHub
> preview, IDE viewer tabs, or document exporters) automatically strip these
> comments out. **Be sure to inspect and edit this template in raw source mode**
> so you do not miss critical audit guidance.

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
  Display the exact code block as decompiled from AndroidManifest.xml. 
  Do not simplify or generalize the XML—show the actual manifest attributes present in the APK.
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
    <container previewImage="@drawable/widget_preview" type="SMALL" />
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

#### Static Preview Assets

<!-- GUIDANCE: 
  Present the raw extracted static preview drawable assets from the APK. 
  State the exact directory qualifier path (e.g. res/drawable/ or res/drawable-round-v23/), dimensions, and asset format.
  Do not clip or mask static previews artificially.
-->

- **APK Qualifier Directory:** `res/<drawable_directory>/<preview_file>`
- **Resolution & Asset Format:** `<width>×<height>` px (\<PNG|WebP>)
- **Extracted Static Asset:**

![ Static Preview](resources/%3Cpreview_filename%3E.png) *Static preview image
(`<preview_filename>.png`) extracted from `res/<directory>/`.*

#### Live Hardware Screen Captures

<!-- GUIDANCE: 
  Embed physical device or emulator screen captures of the service active on watch displays.
  Where applicable, attempt to capture BOTH multi-state representations:
  1. Active Dynamic / Synced State (showing dynamic artwork, playlist title, or rich media metadata).
  2. Unauthenticated / Zero-Feed Fallback State (e.g. logged-out text or zero-item feed with search/login CTA button).
-->

- **Verified Device:** `<Device Name & API Level>`
- **Screenshot:**

![ Hardware Capture](resources/%3Clive_screenshot%3E.png) *Live device capture
on <Device Model>.*

#### Service Review & Observations

<!-- GUIDANCE: 
  Evaluate the service against relevant platform guidelines, preview formats, container dimensions, visual themes, fallback states, and device behavior. 
  Investigate platform lint requirements (e.g. preview aspect ratios, shape qualifiers, container variants) independently and document findings here.
-->

| Review Dimension                    | Status   | Specification Audit & Dynamic Hardware Observations |
| :---------------------------------- | :------- | :-------------------------------------------------- |
| **Container & Size Support**        | \*\*PASS | FAIL                                                |
| **Static Preview Compliance**       | \*\*PASS | FAIL                                                |
| **UI Contrast & Visual Hierarchy**  | \*\*PASS | FAIL                                                |
| **Multi-Instance & Stack Behavior** | \*\*PASS | FAIL                                                |

______________________________________________________________________

<!-- GUIDANCE: Duplicate Section 2.x block above for each additional glanceable service provided by the application. -->

*Audit report generated as part of Wear OS Widget Audit Deliverables
(`<app_name>/index.md`).*

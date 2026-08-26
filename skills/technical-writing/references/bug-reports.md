# Bug Report Guidelines

This document outlines the standard operating procedure for documenting bugs.

## Intent and Audience

A bug report captures actionable information that allows engineers to isolate
the specific timeframe of a defect and identify the root cause.

- **Goal:** Request a fix or investigation from library/tool maintainers with
  complete, factual reproduction evidence.
- **Audience:** Library and tool maintainers.
- **Tone:** Objective, factual, and assertive. Omit speculation from the primary
  description (reserve hypotheses for the optional Analysis section).

## Recommended Structure

To ensure clarity and reproducibility, bug reports (e.g., `BUG.md`) should
generally adhere to the following structure. While this is the ideal format,
adapt it as necessary based on the available information (e.g., if only a code
fragment is available rather than a full reproduction).

### Description

This section should be factual and grounded in the attachments provided. It
should describe:

- What the bug is.
- The observable symptoms (e.g., crash, UI glitch).
- The context in which it occurs.
- **Triggering Code:** Include the specific application source code fragment
  that initiates the failing sequence.
  - If the source is public (e.g., GitHub), include a **persistent link** (using
    a specific commit hash, not `main` or `master`) to the file and line number.
- **Log Correlation:** Explicitly link the triggering code line to the
  corresponding timestamped entry in the error log.

### Environment

Precise versioning allows for accurate reproduction and source code validation.

- **Device:** Device model and API level (e.g., "Pixel Watch 2, API 33" or
  "Emulator, Wear OS 4").
- **Build:** App version code, commit hash, or the specific APK artifact name
  used (e.g., `app-debug.apk`).
- **Libraries:** Key library versions involved in the bug (e.g.,
  `androidx.glance:glance-wear-tiles:1.0.0-alpha05`). **Do not use "latest";**
  provide the exact version, including SNAPSHOT IDs or commit SHAs if running
  against a dev build.

### Impact

Briefly explain the implications of this defect to motivate the fix. Focus on
factual outcomes rather than emotional appeals.

- **Developer Experience:** Does this cause inconsistencies that reduce
  development velocity? Does it render automated tooling unreliable or difficult
  to maintain?
- **User Experience:** Is there a tangible performance degradation or functional
  blocker?

### Reproduction Statistics (Optional)

If the bug is intermittent, provide statistics on how often it occurs (e.g., "5
out of 10 times"). Note any patterns (e.g., alternating success/failure).

### Reproduction Steps

Detailed, step-by-step instructions to reproduce the bug.

- Include specific shell commands or scripts where applicable.
- Mention any necessary conditions (e.g., specific device state, timing).

#### Expected Behavior

What should have happened if the system were working correctly.

#### Actual Behavior

What actually happened. This should align with the "Description" but can be more
specific about the immediate outcome of the reproduction steps.

### Error Log

Include the specific exception or error message identified in the logs.

If a full bug report archive is available, provide:

- **The Extraction Command:** The exact shell command required to extract the
  relevant log section from the ZIP.
- **Relevant Log Extracts:** Key lines from the output that demonstrate the
  defect, including full timestamps and error messages.

#### Example Inclusion

<!-- markdownlint-disable MD013 -->

> **Log Extraction Command:**
>
> ```bash
> # Extracting the reproduction window from bugreport-20260106.zip
> unzip -p "bugreport-20260106.zip" $(unzip -l "bugreport-20260106.zip" | grep -E "bugreport-|dumpstate-" | grep ".txt" | awk '{print $NF}' | head -n 1) | perl -ne 'print if /START_REPRO/ .. /END_REPRO/'
> ```
>
> **Relevant Log Extract:**
>
> ```text
> 01-06 11:13:46.066 10043 32234 32234 E ProtoTilesTileRendererImpl: Failed to render and attach the tile:  com.google.example.wear_widget/.WidgetCatalogService
> 01-06 11:13:46.066 10043 32234 32234 E ProtoTilesTileRendererImpl: java.lang.RuntimeException: Failed to read the given Remote Compose document: The `224` operation is unknown
> ```

<!-- markdownlint-enable MD013 -->

### Workaround (If available)

Any known methods to avoid or mitigate the bug.

### Analysis (Optional)

This is the only section where **speculation** and **technical investigation**
are permitted.

- Hypothesize about root causes (e.g., race conditions, memory leaks).
- **Library Investigation:** Reference specific library source code fragments or
  internal implementation details that explain _why_ the factual sequence
  described above led to a failure.
- Discuss potential fixes or architectural implications.

## Attachments

Evidence validates findings. Ideally, a bug report should include the following,
though availability may vary. These files should be placed in the same directory
as the bug report document.

### Required Files

- `bugreport.zip` (or similar): The captured system bug report containing logs,
  thread dumps, and system properties.

### Recommended Files

- **APK**: The specific build artifact used to reproduce the bug. Explicitly
  listing the filename (e.g., `app/build/outputs/apk/debug/app-debug.apk`)
  ensures the exact binary is identified.
- **Code Fragments**: If a full APK or bug report isn't available, include
  relevant source code snippets.
  - **Completeness:** Ensure snippets are copy-pasteable and substantially
    complete (e.g., include the full function body). Avoid excessive omission
    (...) that makes the logic hard to follow or requires the reader to guess
    context. You do not need to include all imports/dependencies unless critical
    to the bug.

### Visual Evidence (Recommended for UI/Interaction Bugs)

- `repro.png`: A screenshot showing the bug (e.g., visual glitch, error screen).
- `repro.mp4`: A screen recording showing the interaction leading up to the bug.

### Naming Conventions

- Filenames should be descriptive but concise.
- Avoid adding a separate textual description for an attachment unless the
  filename is ambiguous.
- **Ambiguity Rule:** If multiple files of the same type are attached (e.g.,
  multiple screenshots), ensure their filenames clearly distinguish them (e.g.,
  `repro_step1.png`, `repro_step2.png`). Only add a brief description (max 40
  chars) in the bug report if strictly necessary to clarify the difference.

## Summary Checklist

Before finalizing a bug report, verify that:

- [ ] All claims in Description, Actual Behavior, and Error Log are strictly
  factual and grounded in logs.
- [ ] Environment specifications list exact versions, commit SHAs, or APK names
  (no "latest").
- [ ] Triggering code includes persistent links (pinned commits) or
  copy-pasteable snippets.
- [ ] Reproduction steps are step-by-step and include any required device states
  or timing conditions.
- [ ] Hypotheses and root-cause speculations are strictly isolated to the
  optional `## Analysis` section.

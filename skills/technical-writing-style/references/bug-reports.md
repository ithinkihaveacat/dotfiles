# Bug Report Guidelines

This document outlines the standard operating procedure for documenting Android
bugs. The goal is to capture actionable information that allows engineers to
isolate the specific timeframe of a defect and identify the root cause.

## Bug Report Structure

To ensure clarity and reproducibility, bug reports (e.g., `BUG.md`) should
generally adhere to the following structure. While this is the ideal format,
adapt it as necessary based on the available information (e.g., if only a code
fragment is available rather than a full reproduction).

### Description

This section must be **completely factual** and backed up by the attachments
provided. It should describe:

- What the bug is.
- The observable symptoms (e.g., crash, UI glitch).
- The context in which it occurs.
- **Triggering Code:** Include the specific application source code fragment
  that initiates the failing sequence.
  - If the source is public (e.g., GitHub), include a **persistent link** (using
    a specific commit hash, not `main` or `master`) to the file and line number.
- **Log Correlation:** Explicitly link the triggering code line to the
  corresponding timestamped entry in the error log.

**Strict Prohibition on Speculation:**

- **Do not** use "because" clauses that explain the _why_ (e.g., "Crashes
  because the variable is null").
- **Do not** interpret the intent or attach qualitative judgment to the behavior
  (e.g., instead of "This undermines the caching strategy," write "This causes
  the cache to be bypassed.").
- **Do not** reference internal code logic, specific functions, or race
  conditions.
- **Do not** propose fixes here.

Save all technical reasoning and root cause analysis for the "Analysis" section.

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

- Include specific `adb` commands or scripts where applicable.
- Mention any necessary conditions (e.g., specific device state, timing).

#### Expected Behavior

What should have happened if the system were working correctly.

#### Actual Behavior

What actually happened. This should align with the "Description" but can be more
specific about the immediate outcome of the reproduction steps.

### Error Log

Include the specific exception or error message identified in the logs.

If a full bug report is available (see
[Capturing Actionable Bug Reports](#capturing-actionable-bug-reports)), provide:

- **The Extraction Command:** The exact shell command required to extract the
  relevant log section from the ZIP (see "Verifying the Captured Report").
- **Relevant Log Extracts:** Key lines from the output that demonstrate the
  defect, including full timestamps and error messages.

#### Example Inclusion

> **Log Extraction Command:**
>
> <!-- markdownlint-disable MD013 -->

```bash
# Extracting the reproduction window from bugreport-20260106.zip
unzip -p "bugreport-20260106.zip" $(unzip -l "bugreport-20260106.zip" | grep -E "bugreport-|dumpstate-" | grep ".txt" | awk '{print $NF}' | head -n 1) | perl -ne 'print if /START_REPRO/ .. /END_REPRO/'
```

> **Relevant Log Extract:**
>
> ```text
> 01-06 11:13:46.066 10043 32234 32234 E ProtoTilesTileRendererImpl: Failed to render and attach the tile:  com.google.example.wear_widget/.WidgetCatalogService
> 01-06 11:13:46.066 10043 32234 32234 E ProtoTilesTileRendererImpl: java.lang.RuntimeException: Failed to read the given Remote Compose document: The `224` operation is unknown
> ```
>
> <!-- markdownlint-enable MD013 -->

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

- `bugreport.zip` (or similar): The captured Android bug report containing
  system logs. Use `adb bugreport` to capture this even if you have analyzed
  logs via `logcat`, as it contains critical system state (properties, thread
  dumps, etc.).

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
- **Do not** add a separate textual description for an attachment unless the
  filename is ambiguous.
- **Ambiguity Rule:** If multiple files of the same type are attached (e.g.,
  multiple screenshots), ensure their filenames clearly distinguish them (e.g.,
  `repro_step1.png`, `repro_step2.png`). Only add a brief description (max 40
  chars) in the bug report if strictly necessary to clarify the difference.

## Capturing Actionable Bug Reports

When you have access to a device and can reproduce the issue, follow this
procedure to generate the artifacts (logs, markers, videos) required for the
"Error Log" and "Attachments" sections above.

### The Log Marker Technique

To assist in log analysis, inject "markers" into the system log to delimit the
reproduction window.

#### The Command

Use the following command to inject a high-priority log message into the
device's main log buffer:

```bash
adb exec-out log -p f -t "BugReportMarker" "$1"
```

- `-p f`: Sets priority to **Fatal** (ensuring high visibility).
- `-t "BugReportMarker"`: Sets a consistent tag for easy filtering.
- `"$1"`: The message content.

### Optional: Continuous Background Logging

In high-volume or long-running tests, the device's internal log buffer may
rotate, causing earlier markers or error logs to be lost before `adb bugreport`
is run. To mitigate this, capture logs continuously to a file on the host
machine.

#### Workflow

1. **Start Logging in Background:** Clear the buffer, then stream logs to a
   file, saving the process ID (PID).

   ```bash
   adb logcat -c && adb logcat > continuous_log.txt & LOGCAT_PID=$!
   ```

2. **Run Reproduction Steps:** Execute your test case, including injecting
   `BugReportMarker` tags as usual.

3. **Stop Logging:** Kill the background process once the test is complete.

   ```bash
   kill $LOGCAT_PID
   ```

4. **Verify & Attach:** Inspect `continuous_log.txt` to ensure the markers and
   errors were captured. Attach this file to the bug report if the standard
   `bugreport.zip` is missing the relevant data.

### Execution Workflow

Follow this sequence to ensure a clean capture:

#### 1. Mark the Start

Inject a start marker before beginning the reproduction steps.

**Critical:** Log buffers persist. To avoid confusing this run with previous
attempts, clear the buffer first or use a unique message.

<!-- markdownlint-disable MD013 -->

```bash
# Optional: Clear previous logs
adb logcat -c

# Mark start with a unique timestamp to distinguish from prior runs
adb exec-out log -p f -t "BugReportMarker" "START_REPRO: <Bug Description> $(date +%H%M%S)"
```

<!-- markdownlint-enable MD013 -->

#### 2. Reproduce the Defect

Perform the steps to trigger the bug.

- **Optional:** If the reproduction is complex, inject intermediate "progress"
  logs to mark specific steps (e.g., "Step 1 complete").

#### 3. Mark the End

Immediately after the bug occurs, inject an end marker.

```bash
adb exec-out log -p f -t "BugReportMarker" "END_REPRO"
```

#### 4. Capture the Report

Generate the zipped bug report.

```bash
adb bugreport
```

### Capturing Visual Evidence

For UI glitches or complex interaction bugs, logs alone may be insufficient.
Complement the bug report with a screen recording or screenshot.

You can use any available tool to capture this evidence. Specialized agent
skills (e.g., `adb` skill) often provide enhanced capture scripts that handle
device-specifics like Wear OS masking or touch visualization automatically.

#### Basic Method (Standard ADB)

If no specialized tools are available, you can use standard `adb` commands:

**Screen Recording:**

```bash
# Start recording on device (press Ctrl+C to stop)
adb shell screenrecord /sdcard/repro.mp4

# Pull the file to your host machine
adb pull /sdcard/repro.mp4
```

**Screenshots:**

```bash
# Capture screenshot to device storage
adb shell screencap -p /sdcard/repro.png

# Pull the file to your host machine
adb pull /sdcard/repro.png
```

### Verifying the Captured Report

**Crucial Step:** Before submitting, verify that your markers and the error
itself are actually present in the capture.

- **Check Timestamps:** Ensure the logs correspond to the time of your _latest_
  run. Old logs from previous attempts can persist and mislead analysis.
- **Verify Unique Tags:** If you used unique session IDs in your markers (e.g.,
  `START_REPRO_12345`), confirm they match.
- **Check for Rotation:** If your markers are missing, the log buffer likely
  rotated. In this case, use the **Continuous Background Logging** technique
  described above.

To inspect the relevant log window without extracting the entire archive, you
can use the following snippet. **This snippet is also what you should include in
the "Error Log" section of your report.**

Note that file naming conventions for the internal log vary by manufacturer; for
instance, Samsung devices typically use `dumpstate-*.txt` instead of the
standard `bugreport-*.txt`.

<!-- markdownlint-disable MD013 -->

```bash
# Extract and display only the marked "interesting" period.
# CAUTION: Check timestamps! If previous runs weren't cleared, multiple blocks may appear.
unzip -p "bugreport.zip" $(unzip -l "bugreport.zip" | grep -E "bugreport-|dumpstate-" | grep ".txt" | awk '{print $NF}' | head -n 1) | perl -ne 'print if /START_REPRO/ .. /END_REPRO/'
```

<!-- markdownlint-enable MD013 -->

### Benefits

- **Searchability:** Analysts can `grep` for `BugReportMarker` to instantly find
  the relevant start and end timestamps.
- **Context:** Intermediate logs provide ground truth for what the user
  _intended_ to do versus what the system actually did.

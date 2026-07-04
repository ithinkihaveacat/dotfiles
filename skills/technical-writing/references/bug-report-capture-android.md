# Capturing Android Bug Reports

When you have access to an Android device and can reproduce the issue, follow
this procedure to generate the artifacts (logs, markers, videos) required for
the "Error Log" and "Attachments" sections of a bug report (see
[bug-reports.md](bug-reports.md)).

## The Log Marker Technique

To assist in log analysis, inject "markers" into the system log to delimit the
reproduction window.

### The Command

Use the following command to inject a high-priority log message into the
device's main log buffer:

```bash
adb exec-out log -p f -t "BugReportMarker" "$1"
```

- `-p f`: Sets priority to **Fatal** (ensuring high visibility).
- `-t "BugReportMarker"`: Sets a consistent tag for easy filtering.
- `"$1"`: The message content.

## Optional: Continuous Background Logging

In high-volume or long-running tests, the device's internal log buffer may
rotate, causing earlier markers or error logs to be lost before `adb bugreport`
is run. To mitigate this, capture logs continuously to a file on the host
machine.

> **Note for agents:** Shell state does not persist between separate tool
> invocations — a `$LOGCAT_PID` saved in one command will not exist in the next.
> Run this workflow as a single script, or stop logging with
> `pkill -f 'adb logcat'` instead of a saved PID.

### Workflow

1. **Start Logging in Background:** Clear the buffer, then stream logs to a
   file, saving the process ID (PID).

   ```bash
   adb logcat -c && adb logcat > continuous_log.txt & LOGCAT_PID=$!
   ```

1. **Run Reproduction Steps:** Execute your test case, including injecting
   `BugReportMarker` tags as usual.

1. **Stop Logging:** Kill the background process once the test is complete.

   ```bash
   kill $LOGCAT_PID
   ```

1. **Verify & Attach:** Inspect `continuous_log.txt` to ensure the markers and
   errors were captured. Attach this file to the bug report if the standard
   `bugreport.zip` is missing the relevant data.

## Execution Workflow

Follow this sequence to ensure a clean capture:

### 1. Mark the Start

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

### 2. Reproduce the Defect

Perform the steps to trigger the bug.

- **Optional:** If the reproduction is complex, inject intermediate "progress"
  logs to mark specific steps (e.g., "Step 1 complete").

### 3. Mark the End

Immediately after the bug occurs, inject an end marker.

```bash
adb exec-out log -p f -t "BugReportMarker" "END_REPRO"
```

### 4. Capture the Report

Generate the zipped bug report.

```bash
adb bugreport
```

## Capturing Visual Evidence

For UI glitches or complex interaction bugs, logs alone may be insufficient.
Complement the bug report with a screen recording or screenshot.

You can use any available tool to capture this evidence. Specialized agent
skills (e.g., `adb` skill) often provide enhanced capture scripts that handle
device-specifics like Wear OS masking or touch visualization automatically.

### Basic Method (Standard ADB)

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

## Verifying the Captured Report

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

## Benefits

- **Searchability:** Analysts can `grep` for `BugReportMarker` to instantly find
  the relevant start and end timestamps.
- **Context:** Intermediate logs provide ground truth for what the user
  _intended_ to do versus what the system actually did.

# Android Bug Report Capture Guidelines

Guidelines for capturing diagnostic artifacts (logs, log markers, and screen
recordings) on Android devices to accompany bug reports.

## The Log Marker Technique

When reproducing an issue, inject "markers" into the system log to delimit the
exact reproduction window.

### Injecting Markers

Use `scripts/adb-log` to inject high-priority log markers into the device's main
buffer:

```bash
# Mark start of reproduction
scripts/adb-log "START_REPRO: <Bug Description> $(date +%H%M%S)"

# (Or raw fallback if scripts/ is unavailable)
adb exec-out log -p f -t "BugReportMarker" "START_REPRO"
```

## Continuous Background Logging

For long-running reproductions where the device's log buffer might rotate,
stream logs continuously to the host:

```bash
# 1. Clear buffer and start background capture
adb logcat -c && adb logcat > continuous_log.txt & LOGCAT_PID=$!

# 2. Execute reproduction steps with markers
scripts/adb-log "START_REPRO"
# ... perform test actions ...
scripts/adb-log "END_REPRO"

# 3. Stop background capture
kill $LOGCAT_PID
```

## Execution Workflow

1. **Mark Start:** Clear logcat (`adb logcat -c`) and inject start marker.
1. **Reproduce Defect:** Perform the exact steps causing the failure.
1. **Mark End:** Inject end marker (`scripts/adb-log "END_REPRO"`).
1. **Capture Report:** Generate the bug report archive:
   ```bash
   adb bugreport
   ```

## Capturing Visual Evidence

Complement logs with visual captures:

- **Screenshot:** `scripts/adb-screenshot` (auto-masks circular Wear OS
  displays).
- **Screen Recording:** `scripts/adb-screenrecord /sdcard/repro.mp4` (handles
  raw frame streaming).

## Verifying the Capture

Extract and inspect the marked reproduction window from the generated archive:

<!-- markdownlint-disable MD013 -->

```bash
unzip -p "bugreport.zip" $(unzip -l "bugreport.zip" | grep -E "bugreport-|dumpstate-" | grep ".txt" | awk '{print $NF}' | head -n 1) | perl -ne 'print if /START_REPRO/ .. /END_REPRO/'
```

<!-- markdownlint-enable MD013 -->

<!-- markdownlint-disable MD013 -->

# Troubleshooting

## Contents

- [ADB Connection Issues](#adb-connection-issues)
- [Targeting Specific Devices](#targeting-specific-devices)
- [Missing Dependencies](#missing-dependencies)
- [Wear OS Specifics](#wear-os-specifics)
- [Common Errors](#common-errors)

## ADB Connection Issues

### No Device Found

**Symptom**: `error: no device connected` or `List of devices attached` is
empty. **Solution**:

1. Check USB connection.
2. Ensure "USB Debugging" is enabled in Developer Options on the device.
3. Run `adb devices`.
4. If unauthorized, check device screen for the "Allow USB debugging?" prompt.

### Unauthorized

**Symptom**:
`device unauthorized. Please check the confirmation dialog on your device.`
**Solution**:

1. Unlock the device.
2. Check for the RSA key fingerprint prompt.
3. Tap "Allow".
4. Run `adb devices` again to verify state changes from `unauthorized` to
   `device`.

### Offline

**Symptom**: Device status is `offline`. **Solution**:

1. Reconnect USB cable.
2. Restart ADB server: `adb kill-server && adb start-server`.
3. Reboot device if persistent.

## Targeting Specific Devices

### Multiple Devices Connected

**Symptom**: `error: more than one device/emulator` **Solution**: Use the
`ANDROID_SERIAL` environment variable to specify the target device.

1. List devices:

   ```bash
   adb devices -l
   ```

   Output example:

   ```text
   List of devices attached
   emulator-5554          device product:sdk_gphone_x86_64 model:sdk_gphone_x86_64 device:generic_x86_64
   1A2B3C4D               device product:pixel_6 model:Pixel_6 device:oriole
   ```

2. Run script with variable:

   ```bash
   ANDROID_SERIAL=1A2B3C4D scripts/adb-screenshot
   ```

## Missing Dependencies

### `magick` not found

**Context**: `adb-screenshot` requires ImageMagick for processing Wear OS
screenshots. **Solution**:

- macOS: `brew install imagemagick`
- Debian/Ubuntu: `sudo apt-get install imagemagick`

### `apkanalyzer` not found

**Context**: `apk-cat-manifest` requires Android command-line tools.
**Solution**:

- Install Android Command Line Tools via Android Studio or SDK Manager.
- Ensure `cmdline-tools/bin` is in your PATH.

### `xpath` not found

**Context**: `apk-tiles` uses `xpath` to parse manifests. **Solution**:

- macOS: Comes with Perl, but if missing: `brew install libxml2` (includes
  xmllint) or check perl modules.
- Debian/Ubuntu: `sudo apt-get install libxml-xpath-perl`

## Wear OS Specifics

### Debug Broadcasts Not Working

**Symptom**: `adb-tile-add` or `adb-tile-show` does nothing. **Cause**: The
system image might be a "User" build (production) which sometimes disables debug
broadcasts, or Developer Options are not fully enabled. **Solution**:

1. Ensure Developer Options are enabled on the watch.
2. Some features require "wear-user-debug" or emulator images.

### Square vs Round Screenshots

**Context**: `adb-screenshot` attempts to auto-detect square displays and apply
a circular mask.

**Override**: If masking is incorrect, use the raw command:

```bash
adb exec-out "screencap -p" > raw_screenshot.png
```

## Common Errors

### `command not found`

**Cause**: The script is not executable or not in the expected path.
**Solution**:

- Ensure you are running from the skill root: `scripts/script-name`.
- Check `ls -l scripts/` to verify the script exists and is executable.

### `Permission denied`

**Cause**: Missing executable permission. **Solution**:

- `chmod +x scripts/script-name`.

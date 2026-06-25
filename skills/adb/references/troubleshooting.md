# Troubleshooting

<!-- markdownlint-disable MD013 -->

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
1. Ensure "USB Debugging" is enabled in Developer Options on the device.
1. Run `adb devices`.
1. If unauthorized, check device screen for the "Allow USB debugging?" prompt.

### Unauthorized

**Symptom**:
`device unauthorized. Please check the confirmation dialog on your device.`
**Solution**:

1. Unlock the device.
1. Check for the RSA key fingerprint prompt.
1. Tap "Allow".
1. Run `adb devices` again to verify state changes from `unauthorized` to
   `device`.

### Offline

**Symptom**: Device status is `offline`. **Solution**:

1. Reconnect USB cable.
1. Restart ADB server: `adb kill-server && adb start-server`.
1. Reboot device if persistent.

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

1. Run script with variable:

   ```bash
   ANDROID_SERIAL=1A2B3C4D scripts/adb-screenshot
   ```

## Missing Dependencies

### `magick` not found

**Context**: `adb-screenshot` requires ImageMagick for processing Wear OS
screenshots. **Solution**:

- macOS: `brew install imagemagick`
- Debian/Ubuntu: `sudo apt-get install imagemagick`

## Wear OS Specifics

### Debug Broadcasts Not Working

**Symptom**: `adb-tile-add` or `adb-tile-switch` does nothing. **Cause**: The
system image might be a "User" build (production) which sometimes disables debug
broadcasts, or Developer Options are not fully enabled. **Solution**:

1. Ensure Developer Options are enabled on the watch.
1. Some features require "wear-user-debug" or emulator images.

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

<!-- markdownlint-restore MD013 -->

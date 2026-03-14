# System States & Edge Cases

Testing Wear OS apps requires simulating states that users frequently encounter
but are tedious to trigger manually.

## Network & Data Layer Isolation

Wear OS apps must handle phone disconnection gracefully. When the phone
disconnects, data layer messages are queued.

- **Isolate Device (Disable all radios)**: Use the bundled script to disable
  Wi-Fi and Bluetooth.

  ```bash
  scripts/wear-network-isolate
  ```

- **Restore Connectivity (Enable radios)**:

  ```bash
  scripts/wear-network-isolate --restore
  ```

## Power & Doze Mode

Wear apps must respect battery constraints and handle Doze mode cleanly.

- **Force device into Doze (Idle) mode**:

  ```bash
  adb shell dumpsys deviceidle force-idle
  ```

- **Exit Doze mode**:

  ```bash
  adb shell dumpsys deviceidle unforce
  ```

- **Simulate low battery (e.g., 5%)**:

  ```bash
  adb shell dumpsys battery unplug
  adb shell dumpsys battery set level 5
  ```

- **Reset battery state to default**:

  ```bash
  adb shell dumpsys battery reset
  ```

## Global Location Permission (Wear 4+)

Wear OS 4 introduced a global toggle for location, separate from individual app
permissions. Apps should handle this disabled state gracefully.

- **Disable Global Location**:

  ```bash
  adb shell settings put secure location_mode 0
  ```

- **Enable Global Location (High Accuracy)**:

  ```bash
  adb shell settings put secure location_mode 3
  ```

## App Standby Buckets & Hibernation

Test how an app behaves when the system heavily restricts its background work or
when the user hasn't interacted with it for months (hibernation).

- **Put app in 'Rare' bucket** (highly restricted):

  ```bash
  adb shell am set-standby-bucket <your.package.name> rare
  ```

- **Check current bucket**:

  ```bash
  adb shell am get-standby-bucket <your.package.name>
  ```

- **Force App into Hibernation (Android 12+)**: Revokes permissions and clears
  cache to simulate months of inactivity.

  ```bash
  adb shell cmd app_hibernation set-state <your.package.name> true
  ```

## UI, Accessibility & Display

Ensure apps handle different screen densities, font sizes, modes, and dynamic
system colors.

- **Change System Theme / Dynamic Color (API 36+)**: Use the bundled script to
  test how your app's UI adapts to different Material 3 system palettes (e.g.,
  indigo, lemongrass, porcelain).

  ```bash
  scripts/adb-theme set lemongrass
  ```

- **Increase font scale (e.g., 1.3x)**:

  ```bash
  adb shell settings put system font_scale 1.3
  ```

- **Reset font scale**:

  ```bash
  adb shell settings put system font_scale 1.0
  ```

- **Change display density (DPI)**:

  ```bash
  adb shell wm density 250
  ```

- **Reset display density**:

  ```bash
  adb shell wm density reset
  ```

- **Enable Always-on Display (AOD)**:

  ```bash
  adb shell settings put secure doze_enabled 1
  ```

- **Toggle Theater Mode on (Screen Off, No Waking)**:

  ```bash
  adb shell settings put global theater_mode_on 1
  ```

## Physical Inputs & Gestures

Wear OS offers unique navigation methods. Simulate them using `keyevent`.

- **Rotary Crown / Bezel Scroll**: Simulate scrolling up or down.

  ```bash
  adb shell input keyevent 260 # Scroll Up
  adb shell input keyevent 261 # Scroll Down
  ```

- **Wrist Gestures**: Simulate flicking the wrist out or in (useful for
  accessibility testing or system navigation).

  ```bash
  adb shell input keyevent 264 # Flick Out
  adb shell input keyevent 265 # Flick In
  ```

- **Hardware Buttons**:

  ```bash
  adb shell input keyevent KEYCODE_HOME # (3) Home Button
  adb shell input keyevent KEYCODE_BACK # (4) Back Swipe / Button
  ```

## Language & Localization

Test localized strings without diving into the UI settings.

- **Change Language (e.g., French)**: _(Note: The device UI will briefly restart
  to apply the locale change)_

  ```bash
  adb shell setprop persist.sys.locale fr-FR
  adb shell setprop ctl.restart zygote
  ```

## Authentication & Identity

Wear OS standalone apps rely heavily on the Credential Manager API and device
lock capabilities. Ensure your testing accounts for Wear OS limitations.

- **Credential Manager Fallbacks**: Credentials _cannot_ be created on Wear OS,
  and neither "restore credentials" nor hybrid flows are supported. Test the
  flow where no credentials exist on the device or the user dismisses the
  prompt. The app must catch `NoCredentialException` or
  `GetCredentialCancellationException` and present a fallback (e.g., Data Layer
  Token Sharing or Device Authorization Grant).
- **Simulate Device Lock (Wrist Detection)**: If wrist detection auto-locking is
  disabled and the device is taken off the wrist, it stays unlocked longer. Apps
  with sensitive data must verify `isDeviceSecure` and the
  `PIXEL_WRIST_AUTOLOCK_SETTING_STATE`. Test this locked state by forcing the
  device to sleep.

  ```bash
  adb shell input keyevent KEYCODE_SLEEP
  ```

- **Test RemoteAuthClient & OAuth**: If using PKCE or Device Authorization
  Grant, verify the `RemoteActivityHelper` successfully opens the authorization
  web page on the paired mobile phone. Test this by ensuring the phone is
  unlocked and active during the flow.
- **Offline Token Sharing**: Use `scripts/wear-network-isolate` to disable
  Wi-Fi/Bluetooth while initiating Data Layer Token Sharing from the phone
  companion app to verify the watch handles offline token failures gracefully.

## Cloud Backup & Restore (Wear 4+)

Wear OS 4+ supports cloud backup and restore (up to 25 MB per app). If the
backup exceeds 25 MB, **no data** is backed up. Tiles, Complications, and
Watchfaces are also backed up automatically.

- **Simulate Backup**: Force a backup using the local transport to test what
  gets saved.

  ```bash
  adb shell bmgr backupnow <your.package.name>
  ```

- **Simulate Restore**:

  ```bash
  adb shell bmgr restore <your.package.name>
  ```

- **Wipe Data to Test Restore Flow**: Clear the app's data before restoring to
  verify the fresh install + restore experience.

  ```bash
  adb shell pm clear <your.package.name>
  ```

**Important Notes for Wear OS**:

- Do **not** call Wearable Data Layer APIs inside a custom `BackupAgent`, as
  they may fail during the backup/restore process.
- Automatic backups only happen when the device is: charging, on Wi-Fi, signed
  into a Google Account, and 24 hours have passed since the last backup (devices
  do not need to be idle).

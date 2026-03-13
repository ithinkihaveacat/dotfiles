# System States & Edge Cases

Testing Wear OS apps requires simulating states that users frequently encounter
but are tedious to trigger manually.

## Network & Data Layer Isolation

Wear OS apps must handle phone disconnection gracefully. When the phone
disconnects, data layer messages are queued.

- **Isolate Device (Disable all radios)**: Use the bundled script to disable
  Wi-Fi and Bluetooth. `bash scripts/wear-network-isolate`
- **Restore Connectivity (Enable radios)**:
  `bash scripts/wear-network-isolate --restore`

## Power & Doze Mode

Wear apps must respect battery constraints and handle Doze mode cleanly.

- **Force device into Doze (Idle) mode**:
  `adb shell dumpsys deviceidle force-idle`
- **Exit Doze mode**: `adb shell dumpsys deviceidle unforce`
- **Simulate low battery (e.g., 5%)**: `adb shell dumpsys battery unplug`
  `adb shell dumpsys battery set level 5`
- **Reset battery state to default**: `adb shell dumpsys battery reset`

## Global Location Permission (Wear 4+)

Wear OS 4 introduced a global toggle for location, separate from individual app
permissions. Apps should handle this disabled state gracefully.

- **Disable Global Location**: `adb shell settings put secure location_mode 0`
- **Enable Global Location (High Accuracy)**:
  `adb shell settings put secure location_mode 3`

## App Standby Buckets

Test how an app behaves when the system heavily restricts its background work.

- **Put app in 'Rare' bucket** (highly restricted):
  `adb shell am set-standby-bucket <your.package.name> rare`
- **Check current bucket**:
  `adb shell am get-standby-bucket <your.package.name>`

## UI, Accessibility & Display

Ensure apps handle different screen densities, font sizes, modes, and dynamic
system colors.

- **Change System Theme / Dynamic Color (API 36+)**: Use the bundled script to
  test how your app's UI adapts to different Material 3 system palettes (e.g.,
  indigo, lemongrass, porcelain). `bash scripts/adb-theme set lemongrass`
- **Increase font scale (e.g., 1.3x)**:
  `adb shell settings put system font_scale 1.3`
- **Reset font scale**: `adb shell settings put system font_scale 1.0`
- **Change display density (DPI)**: `adb shell wm density 250`
- **Reset display density**: `adb shell wm density reset`
- **Enable Always-on Display (AOD)**:
  `adb shell settings put secure doze_enabled 1`
- **Toggle Theater Mode on (Screen Off, No Waking)**:
  `adb shell settings put global theater_mode_on 1`

## Language & Localization

Test localized strings without diving into the UI settings.

- **Change Language (e.g., French)**:
  `adb shell setprop persist.sys.locale fr-FR; adb shell setprop ctl.restart zygote`
  _(Note: The device UI will briefly restart to apply the locale change)_

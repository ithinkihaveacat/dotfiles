# Wear OS Surfaces

Testing Wear OS applications requires validating interactions with Wear-specific
UI surfaces that live outside the main application container, such as **Tiles**,
**Complications**, and **Watch Faces**.

______________________________________________________________________

## Active Tiles Carousel

Tiles provide quick, swipeable access to information and actions. Testing Tiles
requires simulating how the system adds, removes, and brings them to the
foreground.

### General Tile Capabilities

- **Deploying a Tile**: Test how your Tile renders and initializes when added to
  the active carousel.
- **Removing a Tile**: Validate that the app cleans up Tile-specific resources
  when removed.
- **Tapping/Launching from a Tile**: Verify that tapping a Tile action
  successfully launches the correct activity or Foreground Service.

### Automation Tooling (Leverage Active Skills)

To automate Tile testing, do not write custom scripts or send raw SysUI intents.

- **Guideline**: Search your active skills for pre-approved automation scripts
  capable of:
  - Deploying or refreshing a specific Tile on the device.
  - Removing a Tile from the active carousel.
  - Bringing a specific Tile to the foreground.
  - Listing all currently active Tiles on the device.

______________________________________________________________________

## Complications & Watch Faces

Complications are modular data fields on a Watch Face. Testing complications
involves simulating data updates and tapping actions.

### Triggering Complication Updates (DEBUG_SYSUI)

You can force the system to update a complication's data feed or simulate
various complication types (e.g. RANGED_VALUE, LONG_TEXT) via ADB intents:

- **Force Complication Update**:
  ```bash
  adb shell am broadcast \
    -a "com.google.android.wearable.app.DEBUG_SYSUI" \
    --es "operation" "complication_update" \
    --ei "complication_id" <ID>
  ```

### Simulating Watch Face Environments (Wear OS 4+)

Test how complications and watch faces render across different system states
(such as ambient mode, low-power mode, and screen-off states).

- **Force Ambient Mode (Low Power / Screen Dimmed)**:
  ```bash
  adb shell cmd wearable_sensing set-ambient-mode true
  ```
- **Exit Ambient Mode**:
  ```bash
  adb shell cmd wearable_sensing set-ambient-mode false
  ```
- **Query Active Complication Providers**:
  ```bash
  adb shell dumpsys package | grep -A 10 "complication"
  ```

______________________________________________________________________

## Standalone Watch Bootstrapping & Setup Bypass

When running automated UI or visual tests on a headless Wear OS emulator or a
physical watch (e.g. on isolated networks where companion phone pairing is
unavailable), the device can be transitioned directly into a standalone
development state without phone pairing. This requires `adb root` on
userdebug/eng firmware or an emulator.

### 1. Mark AOSP Platform Provisioning Complete

Set standard AOSP flags to inform system services (`ActivityManagerService` and
`KeyguardViewMediator`) that initial provisioning is complete, enabling standard
`CATEGORY_HOME` launcher activities:

```bash
adb shell settings put global device_provisioned 1
adb shell settings put secure user_setup_complete 1
```

*(Reference: AOSP
[`Settings.Global.DEVICE_PROVISIONED`](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/core/java/android/provider/Settings.java)
and
[`Settings.Secure.USER_SETUP_COMPLETE`](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/core/java/android/provider/Settings.java)).*

### 2. Disable OEM Setup Wizard

The OEM setup wizard intercepts the home intent to enforce phone pairing.
Disabling the package allows the launcher (`SysUiActivity`) to render the watch
face:

```bash
# Stock Wear OS / Pixel Watch:
adb shell pm disable com.google.android.wearable.setupwizard

# Samsung Galaxy Watch (One UI Watch):
adb shell pm disable com.samsung.android.wearable.setupwizard
```

### 3. Waking Up and Unlocking the Device

```bash
adb shell input keyevent KEYCODE_WAKEUP
adb shell wm dismiss-keyguard
```

### 4. Dismissing Charging Overlay

If the emulator or watch is simulating a charging state (locking the screen with
a charging animation), unplug the battery to dismiss it:

```bash
adb shell dumpsys battery unplug
```

### 5. Dismiss Wear OS Tutorial & Return to Home

Send debug broadcasts (standard intents handled by Wear OS System UI and CTS
test harnesses) to bypass the introductory tutorial, then send `KEYCODE_HOME`:

```bash
adb shell am broadcast -a com.google.android.clockwork.action.TEST_MODE
adb shell am broadcast -a com.google.android.clockwork.action.TUTORIAL_SKIP
adb shell input keyevent KEYCODE_HOME
```

*(If a "Skip" dialog remains on screen, send
`adb shell input keyevent KEYCODE_BACK` or tap the screen coordinate to dismiss
it).*

### GMS Core Capability Sync Workaround (for Tiles/Widgets)

If the System UI fails to sync capabilities with GMS Core, it may assume
widgets/tiles are unsupported and render a default watch face instead of binding
your service. Force a sync by restarting GMS Core, WearServices, and System UI:

```bash
adb shell am force-stop com.google.android.gms
adb shell am force-stop com.google.android.wearable.app
adb shell am force-stop com.google.android.wearable.sysui
# Allow 15-20 seconds for the System UI to reboot and re-query capabilities.
```

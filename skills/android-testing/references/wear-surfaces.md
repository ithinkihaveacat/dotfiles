# Wear OS Surfaces

Testing Wear OS applications requires validating interactions with Wear-specific
UI surfaces that live outside the main application container, such as **Tiles**,
**Complications**, and **Watch Faces**.

______________________________________________________________________

## 1. Active Tiles Carousel

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

## 2. Complications & Watch Faces

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

## 3. Headless Emulator Bootstrapping & Setup Bypass

When running automated UI or visual tests on a headless Wear OS emulator, the
system may boot into a locked or setup state with tutorial overlays, and GMS
Core capability sync issues can prevent widget tiles from loading.

### 1. Waking up and Unlocking the Device

```bash
adb shell input keyevent KEYCODE_WAKEUP
adb shell wm dismiss-keyguard
```

### 2. Dismissing Charging Overlay

If the emulator is simulating a charging state (locking the screen with a
charging animation), unplug the battery to dismiss it:

```bash
adb shell dumpsys battery unplug
```

### 3. Wear OS OOBE and Tutorial Bypass

Send debug broadcasts to bypass the Wear OS setup tutorial overlays and start in
active test mode:

```bash
adb shell am broadcast -a com.google.android.clockwork.action.TEST_MODE
adb shell am broadcast -a com.google.android.clockwork.action.TUTORIAL_SKIP
```

### 4. GMS Core Capability Sync Workaround (for Tiles/Widgets)

If the System UI fails to sync capabilities with GMS Core, it may assume
widgets/tiles are unsupported and render a default watch face instead of binding
your service. Force a sync by restarting GMS Core, WearServices, and System UI:

```bash
adb shell am force-stop com.google.android.gms
adb shell am force-stop com.google.android.wearable.app
adb shell am force-stop com.google.android.wearable.sysui
# Allow 15-20 seconds for the System UI to reboot and re-query capabilities.
```

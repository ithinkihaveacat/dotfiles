# UI, Display & Physical Inputs

Validating Android and Wear OS user interfaces requires testing across varied
display configurations (themes, font scales, screen densities) and simulating
hardware input mechanisms (rotary crowns, wrist flicks, and Wear OS 7+
one-handed gestures).

______________________________________________________________________

## UI, Accessibility & Display

Ensure your application's layouts and text scale gracefully across different
form factors and configurations.

- **Dynamic Color Themes (API 36+)**: Test how your app's UI adapts to different
  Material 3 system color palettes (e.g., indigo, lemongrass, porcelain) via the
  `theme_customization_overlay_packages` secure setting (or a workspace helper
  such as `adb-theme set lemongrass` if available):
  ```bash
  adb shell settings put secure theme_customization_overlay_packages \
    '{"android.theme.customization.color_source":"preset","android.theme.customization.system_palette":"#DDEB78","android.theme.customization.theme_style":"EXPRESSIVE"}'
  ```
- **Increase Font Scale (e.g., 1.3x)** (or via `adb-fontscale set 1.3` if
  available):
  ```bash
  adb shell settings put system font_scale 1.3
  ```
- **Reset Font Scale**:
  ```bash
  adb shell settings put system font_scale 1.0
  ```
- **Change Display Density (DPI)**:
  ```bash
  adb shell wm density 250
  ```
- **Reset Display Density**:
  ```bash
  adb shell wm density reset
  ```
- **Toggle Theater Mode On (Screen Off, No Waking)**:
  ```bash
  adb shell settings put global theater_mode_on 1
  ```

______________________________________________________________________

## Physical Inputs & Keyevents

Simulate physical Wear OS hardware controls and wrist flicks using `keyevent`:

- **Rotary Crown / Bezel Scroll**:
  ```bash
  adb shell input keyevent 260 # Scroll Up
  adb shell input keyevent 261 # Scroll Down
  ```
- **Wrist Gestures**:
  ```bash
  adb shell input keyevent 264 # Flick Out (Accessibility/System navigation)
  adb shell input keyevent 265 # Flick In
  ```
- **Hardware Buttons**:
  ```bash
  adb shell input keyevent KEYCODE_HOME # (3) Home Button
  adb shell input keyevent KEYCODE_BACK # (4) Back Swipe / Button
  ```

______________________________________________________________________

## Wear OS One-Handed Gestures (Wear OS 7+)

Testing Wear OS 7+ applications that utilize one-handed gestures (specifically
the Double Pinch / Primary action and Wrist Turn / Dismiss action) requires
understanding how the gesture framework registers subscribers, how to simulate
these gestures via ADB, and how to bypass hardware constraints (like the
off-body sensor) during development.

### Prerequisites for Gesture Testing

For any gesture interaction to be active and testable (either physically or via
ADB simulation), the following conditions must be met on the Wear OS device:

1. **Feature Support**: The device must declare support for gesture detection.
   Verify this via ADB:

   ```bash
   adb shell pm list features | grep -i gesture
   ```

   *Expected Output*: `feature:com.google.wear.feature.GESTURE_DETECTION`

1. **Gestures Enabled in Settings**:

   - On the watch: Go to **Settings** -> **Gestures** -> **Hand gestures** and
     ensure they are turned **ON**.
   - Verify via ADB:
     ```bash
     adb shell settings list secure | grep -E "gesture_primary_action_user_preference|gesture_dismiss_action_user_preference"
     ```
     *Expected Output*:
     ```text
     gesture_primary_action_user_preference=1
     gesture_dismiss_action_user_preference=1
     ```

1. **Screen State & Foreground Window Focus**:

   - The watch screen must be awake and turned **ON** (`mWakefulness=Awake`).
     The gesture framework does not dispatch gestures to applications while the
     screen is off or in ambient/AOD mode. Wake the screen via ADB if needed:
     ```bash
     adb shell input keyevent KEYCODE_WAKEUP
     ```
   - The target application must be in the foreground and its window must hold
     focus (`mCurrentFocus`).

### Simulating Gestures via ADB

Applications subscribe to semantic **gesture actions** (`PrimaryAction`,
`DismissAction`), while `cmd IWearGestureService gesture <gesture>` injects a
physical **raw gesture** (such as `DoublePinch` or `WristTurn`). Because the
action-to-gesture mapping can vary across OEMs (such as Pixel Watch vs. Samsung)
and emulator system images, first query the device's active mapping before
injecting gestures:

```bash
adb shell cmd IWearGestureService get-supported-actions -readable
```

*Example Output*:

```json
{
  "remote": {
    "PrimaryAction": "DoublePinch",
    "DismissAction": "WristTurn"
  },
  "local": {
    "PrimaryAction": "DoublePinch",
    "DismissAction": "WristTurn"
  }
}
```

- `"local"` (`GESTURE_SUBSCRIBER_TYPE_LOCAL`): Action-to-gesture mappings for
  on-watch apps and features.
- `"remote"` (`GESTURE_SUBSCRIBER_TYPE_REMOTE`): Action-to-gesture mappings for
  connected external devices (such as a paired TV or smart glasses) controlled
  by gestures performed on the watch.

Use the raw gesture name listed under `"local"` to inject simulated gesture
events into the active foreground watch application:

- **Simulate Primary Action (e.g., Double Pinch)**:

  ```bash
  adb shell cmd IWearGestureService gesture DoublePinch
  ```

  *Alternative (using integer ID)*:

  ```bash
  adb shell cmd IWearGestureService gesture 1
  ```

- **Simulate Dismiss Action (e.g., Wrist Turn)**:

  ```bash
  adb shell cmd IWearGestureService gesture WristTurn
  ```

  *Alternative (using integer ID)*:

  ```bash
  adb shell cmd IWearGestureService gesture 2
  ```

#### Gesture ID Reference Table

The gesture service accepts standard PascalCase string names or integer IDs:

| Gesture Name             | CLI String Name     | Integer ID | Default Pixel Watch / Emulator Action Mapping          |
| :----------------------- | :------------------ | :--------- | :----------------------------------------------------- |
| **Double Pinch**         | `DoublePinch`       | `1`        | `PrimaryAction` (Select, Play/Pause, Answer Call)      |
| **Wrist Turn**           | `WristTurn`         | `2`        | `DismissAction` (Back, Silence/Dismiss Alarm, Hang Up) |
| **Single Pinch**         | `SinglePinch`       | `3`        | Custom / OEM-configured                                |
| **Palm Up Single Pinch** | `PalmUpSinglePinch` | `4`        | Custom / OEM-configured                                |
| **Palm Up Double Pinch** | `PalmUpDoublePinch` | `5`        | Custom / OEM-configured                                |
| **Double Wrist Turn**    | `DoubleWristTurn`   | `6`        | Custom / OEM-configured                                |

### Developer Overrides (Bypassing Constraints)

The gesture service enforces strict environmental constraints before it
activates gesture detection. In a development or test automation environment,
these constraints often block testing.

#### The Off-Body Constraint (Watch on Desk/Dock)

When the watch is sitting on a desk or connected to a charging dock, it detects
it is off-body (`mIsOffBody=true`). The system automatically disables gesture
detection to save power. When this happens, all gestures become inactive, and
ADB injection will fail.

#### Bypassing Constraints via ADB

You can temporarily override these constraints for development, manual testing,
or test automation:

- **Override Off-Body Constraint** (Allows testing while watch is docked/on
  desk):
  ```bash
  adb shell cmd IWearGestureService override-constraints offbody-state
  ```
- **Override Foreground/Focus Constraint** (Allows injecting gestures even if
  the app is not in focus):
  ```bash
  adb shell cmd IWearGestureService override-constraints foreground-state
  ```
- **Override Screen-State Constraint** (Allows injecting gestures when the
  screen is off or in Ambient/AOD mode):
  ```bash
  adb shell cmd IWearGestureService override-constraints screen-state
  ```
- **Reset Constraints to Default**:
  ```bash
  adb shell cmd IWearGestureService override-constraints reset
  ```

### Diagnostics & Troubleshooting

#### Query Active Gestures

To check if the system currently considers a gesture active (meaning an app has
successfully subscribed to it, the window is focused, and all constraints are
satisfied):

```bash
adb shell cmd IWearGestureService get-active-gestures -readable
```

If this returns an empty list (e.g., `activeGestures=[]`), the gesture is
inactive, and injection will fail.

#### Query Supported Actions

To query the local and remote supported actions across paired surfaces:

```bash
adb shell cmd IWearGestureService get-supported-actions -readable
```

#### Inspect Recent Gesture Injections

To view recent gesture event injections and their recipient packages:

```bash
adb shell cmd IWearGestureService get-latest-gesture-events
```

#### Inspecting Service State via Dumpsys

The most powerful tool for troubleshooting is `dumpsys`. It dumps the complete
internal state of the gesture service:

```bash
adb shell dumpsys IWearGestureService
```

Key sections to inspect in the dump:

- **On-Body Status (`mIsOffBody`)**: If `true`, gestures are disabled. Use the
  `override-constraints offbody-state` command to bypass.
- **Foreground Subscriptions**: Verify that your application's package name is
  listed under `Foreground Gesture subscriptions` with the correct action (e.g.,
  `action: 1` for Primary).
- **Window Focus (`mCurrentFocus`)**: Verify that your app's window token
  currently has focus.
- **Overridden Constraints**: Confirms which developer overrides are currently
  active.

### Testing UI Hints & Smart Nudging

To prevent visual clutter and annoying experienced users, the Wear OS gesture
framework implements a **Smart Nudging** policy.

#### How Hints Work (Mechanics)

1. **Deciding to Hint**: When a gesture-aware screen is composed, the
   `oneHandedGesture` modifier queries the system to check if the user needs
   education.
1. **Interaction Stream**: If the system decides a hint is warranted, the
   modifier emits a **Hint Interaction** into the element's Compose
   `InteractionSource`.
1. **Visual Glow**: The `OneHandedGestureIndicator` (or
   `OneHandedGestureScrollIndicator`) listens to this `InteractionSource` and
   renders the animated radial ripple or scroll dots only when the hint
   interaction is active.

#### The Education Budget (Why Hints Disappear)

During manual testing, you will notice that the visual ripples and scroll dots
**disappear after a few views** and stop animating. This is expected system
behavior:

- The system caps gesture hints at a maximum of **3 views/nudges** per session.
- Once the user successfully performs/consumes the gesture, the hints are
  suppressed.

#### Forcing Hints & Resetting the Education Budget

During testing, once the hints disappear, you can force the system to show them
again by resetting the app's gesture history. There are two ways to do this
depending on your device's build type:

##### Method 1: Using `hint clear` (Requires `adb root`)

If you are testing on an **Emulator** or an **Internal Developer Device**
running a `userdebug` or `eng` build, you can restart ADB as root and clear the
hint history directly:

```bash
# Restart adbd as root
adb root

# Clear the hint history for your package
adb shell cmd IWearGestureService hint clear <package_name>
```

> [!IMPORTANT] **Who can run `adb root`?**
>
> - **Allowed**: Emulators (AVDs) and internal developer devices running
>   `userdebug` or `eng` builds.
> - **Blocked**: Commercial/retail devices running production `user` builds. On
>   these devices, `adb root` will fail with
>   `adbd cannot run as root in production builds`.
> - *Note on Network Debugging*: Running `adb root` over a network/Wi-Fi
>   connection (like `localhost:41027`) will temporarily disconnect your
>   debugging session. You must run `adb connect <address>` to reconnect after
>   `adbd` restarts as root.

##### Method 2: Using `pm clear` (Root-Free Fallback for Retail Devices)

If you are testing on a **retail physical watch** (where `adb root` is blocked),
you can achieve the exact same result by clearing the application's local
package data. This resets the app's lifetime and forces the gesture service to
treat the next launch as a "first-time discovery" event, triggering the hints
immediately:

```bash
# Wipes app data, resetting the gesture education budget (Works on ALL devices)
adb shell pm clear <package_name>
```

#### Verifying Hint Config in Dumpsys

You can inspect the system's active nudge delays and session limits under the
`GestureHintConfigurationProvider` section of the dumpsys:

```bash
adb shell dumpsys IWearGestureService | grep -A 5 "GestureHintConfigurationProvider"
```

*Expected Output*:

```text
  GestureHintConfigurationProvider: 
    millisBeforeNudge=0
    useGestureTime=true
    useHintCount=true
    useGestureCount=true
    maxSessionHints: first=3 nudge=1
```

This confirms the maximum session hints (e.g., `first=3`) before the system
silences the visual cues.

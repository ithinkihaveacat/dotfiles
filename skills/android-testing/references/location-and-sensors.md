# Location & Sensors

Testing location-based tracking, active mapping, and biometrics on Android and
Wear OS requires strict adherence to the operating system's location security
architecture.

______________________________________________________________________

## 1. Location Spoofing & Fused Location Security

Modern Android mapping, routing, and fitness apps (e.g. AllTrails, Strava,
Google Maps) rely on Google Play Services' **Fused Location Provider** (`fused`)
rather than querying the raw GPS chip directly.

### The Mock Location App Requirement

Google Play Services implements strict location integrity and anti-spoofing
checks. **Raw ADB shell mock location injections will be silently ignored by the
Fused Location Provider.**

- If you attempt to use background scripts to inject sequential coordinates into
  `gps`, `network`, or even the `fused` test providers via raw shell appops
  (e.g., `cmd location providers set-test-provider-location`), the underlying
  system maps may pan, but the Fused Location Provider pipeline will filter out
  the coordinates. Distance tracking will remain locked at `0.00 km`.
- **The Solution (Developer Authorization)**: To bypass this filter, you
  **must** register a dedicated Android application as the Mock Location
  Provider in the device's developer settings:
  1. Install a Mock Location helper application (e.g. "GPS Joystick", "Fake
     GPS", or a custom test harness) on the target phone.
  1. Open the device **Settings** -> **System** -> **Developer Options**.
  1. Scroll to the debugging section, tap **Select mock location app**, and
     choose your installed mock helper application.
  1. Drive all coordinate injections through that authorized application's API
     or UI. Only then will Google Play Services' Fused Location Provider accept
     the mocked coordinates and update the active workout distance or location
     arrow.

______________________________________________________________________

## 2. Health Services & Synthetic Data (Wear OS 3+)

For physical exertion and biometric tracking on Wear OS, the system provides a
powerful **Synthetic Data Generation Tool** built directly into Health Services
(Emulators only). This allows developers to simulate walking, running, and
biometric sensor feeds without needing physical movement or a Mock Location app.

### Enable Synthetic Mode

Instruct Health Services to bypass physical hardware sensors and use synthetic
data providers:

```bash
adb shell am broadcast \
  -a "whs.USE_SYNTHETIC_PROVIDERS" \
  com.google.android.wearable.healthservices
```

### Simulating Exercises

Once synthetic mode is active, Health Services will automatically generate
realistic, synchronized sensor feeds for Heart Rate, Steps, Speed, Location, and
Elevation.

- **Start Walking** (Simulates ~120 bpm heart rate, 1.4 m/s speed):
  ```bash
  adb shell am broadcast -a "whs.synthetic.user.START_WALKING" com.google.android.wearable.healthservices
  ```
- **Start Running** (Simulates ~170 bpm heart rate, 2.3 m/s speed):
  ```bash
  adb shell am broadcast -a "whs.synthetic.user.START_RUNNING" com.google.android.wearable.healthservices
  ```
- **Stop Exercise**:
  ```bash
  adb shell am broadcast -a "whs.synthetic.user.STOP_EXERCISE" com.google.android.wearable.healthservices
  ```

### Simulating Instantaneous Biometric Events

- **Trigger Auto-Pause (Workout transition)**:
  ```bash
  adb shell am broadcast -a "whs.AUTO_PAUSE_DETECTED" com.google.android.wearable.healthservices
  ```
- **Trigger Fall Detection (Safety alerts)**:
  ```bash
  adb shell am broadcast -a "whs.synthetic.user.FALL_OVER" com.google.android.wearable.healthservices
  ```
- **Simulate High Heart Rate Alert**:
  ```bash
  adb shell am broadcast -a "whs.synthetic.user.HIGH_HR" com.google.android.wearable.healthservices
  ```

______________________________________________________________________

## 3. Wear OS One-Handed Gestures (Wear OS 7+)

Testing Wear OS 7+ applications that utilize one-handed gestures (specifically
the Double Pinch / Primary action and Wrist Turn / Dismiss action) requires
understanding how the gesture framework registers subscribers, how to simulate
these gestures via ADB, and how to bypass hardware constraints (like the
off-body sensor) during development.

### A. Prerequisites for Gesture Testing

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
     ```
     gesture_primary_action_user_preference=1
     gesture_dismiss_action_user_preference=1
     ```

1. **External Device Control Enabled (CRITICAL for ADB Simulation)**:

   - To allow ADB to inject gesture events, the developer option "External
     device control" must be enabled.
   - On the watch: Go to **Settings** -> **Gestures** -> **Hand gestures** ->
     **External Control** -> Turn **ON** **"External device control"**.
   - *Warning*: If this setting is OFF, any ADB gesture simulation will fail
     with:
     `Failed to complete gesture. injectGestureInternal: Gesture DoublePinch is not active.`

### B. Simulating Gestures via ADB

You can inject simulated gesture events into the active foreground application
using the `IWearGestureService` command-line tool.

- **Simulate Double Pinch (Primary Action)**:

  ```bash
  adb shell cmd IWearGestureService gesture 1
  ```

  *Alternative (using constant name)*:

  ```bash
  adb shell cmd IWearGestureService gesture GESTURE_DOUBLE_PINCH
  ```

- **Simulate Wrist Turn (Dismiss Action)**:

  ```bash
  adb shell cmd IWearGestureService gesture 2
  ```

  *Alternative (using constant name)*:

  ```bash
  adb shell cmd IWearGestureService gesture GESTURE_WRIST_TURN
  ```

#### Gesture ID Reference Table

The gesture service expects the exact integer ID or the matching `GESTURE_`
constant name defined in `IWearGestureService.aidl`:

| Gesture Name             | Integer ID | AIDL Constant Name             | Common Action Mapping                                  |
| :----------------------- | :--------- | :----------------------------- | :----------------------------------------------------- |
| **Double Pinch**         | `1`        | `GESTURE_DOUBLE_PINCH`         | `PrimaryAction` (Select, Play/Pause, Answer Call)      |
| **Wrist Turn**           | `2`        | `GESTURE_WRIST_TURN`           | `DismissAction` (Back, Silence/Dismiss Alarm, Hang Up) |
| **Single Pinch**         | `3`        | `GESTURE_SINGLE_PINCH`         | Custom                                                 |
| **Palm Up Single Pinch** | `4`        | `GESTURE_PALM_UP_SINGLE_PINCH` | Custom                                                 |
| **Palm Up Double Pinch** | `5`        | `GESTURE_PALM_UP_DOUBLE_PINCH` | Custom                                                 |
| **Double Wrist Turn**    | `6`        | `GESTURE_DOUBLE_WRIST_TURN`    | Custom                                                 |

> [!CAUTION] **Avoid Informal Names**: Passing informal string names like
> `"DoublePinch"` or `"WristTurn"` will cause the command parser to fail with a
> `NumberFormatException` in the system server:
> `java.lang.NumberFormatException: For input string: "DoublePinch"` Always use
> the integer ID (`1`, `2`) or the formal constant name (`GESTURE_DOUBLE_PINCH`,
> `GESTURE_WRIST_TURN`).

### C. Developer Overrides (Bypassing Constraints)

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

### D. Diagnostics & Troubleshooting

#### Query Active Gestures

To check if the system currently considers a gesture active (meaning an app has
successfully subscribed to it, the window is focused, and all constraints are
satisfied):

```bash
adb shell cmd IWearGestureService get-active-gestures -readable
```

If this returns an empty list (e.g., `activeGestures=[]`), the gesture is
inactive, and injection will fail.

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

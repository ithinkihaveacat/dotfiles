# Health Services & Synthetic Data

Testing health and fitness applications on Wear OS requires simulating sensor
data (heart rate, steps, GPS, falls) without needing to physically perform the
activities. Wear OS provides a robust "Synthetic Data" generation tool built
directly into Health Services.

## Enabling Synthetic Data (Wear OS 3+)

Before you can simulate exercises or events, you must instruct Health Services
to use synthetic providers instead of real hardware sensors.

> **Note**: This only works on Emulators (Wear OS 3 and 4+). It does not work on
> physical devices. Developer Options must be enabled.

- **Enable Synthetic Mode**:

  ```bash
  adb shell am broadcast
    -a "whs.USE_SYNTHETIC_PROVIDERS"
    com.google.android.wearable.healthservices
  ```

- **Disable Synthetic Mode (Return to real sensors)**:

  ```bash
  adb shell am broadcast
    -a "whs.USE_SENSOR_PROVIDERS"
    com.google.android.wearable.healthservices
  ```

## Simulating Exercises

Once synthetic mode is enabled, you can start simulating continuous activities.
Health Services will automatically generate realistic data for Heart Rate,
Steps, Speed, Location, and Elevation based on the chosen activity profile.

- **Start Walking**: (120 bpm, 1.4 m/s)

  ```bash
  adb shell am broadcast
    -a "whs.synthetic.user.START_WALKING"
    com.google.android.wearable.healthservices
  ```

- **Start Running**: (170 bpm, 2.3 m/s)

  ```bash
  adb shell am broadcast
    -a "whs.synthetic.user.START_RUNNING"
    com.google.android.wearable.healthservices
  ```

- **Start Swimming**: (150 bpm, 1.6 m/s, no elevation changes)

  ```bash
  adb shell am broadcast
    -a "whs.synthetic.user.START_SWIMMING"
    com.google.android.wearable.healthservices
  ```

- **Stop the Synthetic Exercise**:

  ```bash
  adb shell am broadcast
    -a "whs.synthetic.user.STOP_EXERCISE"
    com.google.android.wearable.healthservices
  ```

## Simulating Instantaneous Events

You can trigger specific point-in-time events to test your app's responsiveness
to state changes.

- **Trigger Auto-Pause**:

  ```bash
  adb shell am broadcast
    -a "whs.AUTO_PAUSE_DETECTED"
    com.google.android.wearable.healthservices
  ```

- **Trigger Auto-Resume**:

  ```bash
  adb shell am broadcast
    -a "whs.AUTO_RESUME_DETECTED"
    com.google.android.wearable.healthservices
  ```

- **Trigger a Fall Detection**: (Note: May take up to a minute to deliver)

  ```bash
  adb shell am broadcast
    -a "whs.synthetic.user.FALL_OVER"
    com.google.android.wearable.healthservices
  ```

- **Trigger a Golf Shot** (Requires specifying the swing type: `putt`,
  `partial`, or `full`):

  ```bash
  adb shell am broadcast
    -a "whs.GOLF_SHOT"
    --es golf_shot_swing_type "partial"
    com.google.android.wearable.healthservices
  ```

## Simulating Sleep States

Test background passive monitoring or sleep tracking by forcing the synthetic
user asleep or awake.

- **Set state to Asleep**:

  ```bash
  adb shell am broadcast
    -a "whs.synthetic.user.START_SLEEPING"
    com.google.android.wearable.healthservices
  ```

- **Set state to Awake**:

  ```bash
  adb shell am broadcast
    -a "whs.synthetic.user.STOP_SLEEPING"
    com.google.android.wearable.healthservices
  ```

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

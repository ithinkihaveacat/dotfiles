# System States & Connectivity

Android and Wear OS applications must handle volatile network connections,
device handoffs, and strict operating system power management states gracefully.
Testing these states requires simulating conditions that users frequently
encounter but are tedious to trigger manually.

______________________________________________________________________

## 1. Network & Connectivity Constraints

### The Bluetooth Companion Proxy (Wear OS)

By default, Wear OS devices route all internet and network traffic through the
paired companion phone over a low-power Bluetooth proxy (RFCOMM) to conserve
battery.

- **Bandwidth Bottleneck**: This connection is extremely bandwidth-constrained,
  capping speeds at roughly 100 KB/s to 130 KB/s. Large package installations
  (e.g. 50+ MB companion apps) triggered from the phone's Play Store will
  experience significant latency, often taking upwards of 8 minutes to complete
  over Bluetooth.
- **Testing Impact**: When validating companion installations or first-time
  syncs, do not assume the install has failed if the package manager
  (`pm list packages`) remains empty after 2 minutes. The download is likely
  trickling slowly in the background.

### Wi-Fi Handoff & Scanning Delays

When the watch's Bluetooth connection is severed, the watch attempts to failover
to local Wi-Fi.

- **The Deliberate Delay**: To save battery, Wear OS keeps its Wi-Fi radio
  completely dormant as long as a stable Bluetooth connection exists. When
  Bluetooth is disconnected, the OS does not instantly bring up Wi-Fi. There is
  a deliberate power-saving scanning and association delay of **45 to 60
  seconds** before the watch connects to a saved Wi-Fi network.
- **Testing Impact**: If verifying Wi-Fi fallback, wait at least 60 seconds
  after disabling Bluetooth before checking network states. Checking too early
  will show a false-negative "Waiting for Wi-Fi..." state.

### Wi-Fi Credential Sync Failures (Out-of-Sync Passwords)

A common and silent failure mode in paired devices is out-of-sync Wi-Fi
credentials. Even if the watch has the same Wi-Fi network saved as the phone,
the credentials stored on the watch may be stale or incorrect.

- **The Lockout State**: The watch's `WifiNetworkSelector` will attempt to
  associate, fail due to authentication, and flag the network as
  `NETWORK_SELECTION_DISABLED_BY_WRONG_PASSWORD`. The watch will remain
  permanently offline and locked out of the network, tricking developers and
  testers into assuming the Wi-Fi radio is broken.
- **Diagnostic Command**: Query the watch's active Wi-Fi status via the command
  line to verify if it is connected or blocked:
  ```bash
  adb shell cmd wifi status
  ```
- **Direct Connection Injection**: To bypass stale credentials and force an
  instant, high-speed Wi-Fi connection, inject the WPA2 credentials directly
  into the watch's Wi-Fi supplicant using single quotes to preserve SSID spaces:
  ```bash
  adb shell 'cmd wifi connect-network "<SSID>" wpa2 <PASSWORD>'
  ```
  *(Example: adb shell 'cmd wifi connect-network "Duncan Guest" wpa2 qqqqqqqq')*

### Gold Standard Diagnostics: Dual Bugreports

When troubleshooting complex synchronization, Bluetooth proxy, or Wi-Fi handoff
issues, raw logcat is often insufficient. Capture a synchronized pair of zip
bugreports from both devices simultaneously to trace Google Play Services and
system connection handshakes:

- Phone Bugreport: `adb -s <PHONE_SERIAL> bugreport phone_bugreport.zip`
- Watch Bugreport: `adb -s <WATCH_SERIAL> bugreport watch_bugreport.zip`

### Simulated Device Isolation (Offline Testing)

To test how your application behaves when it is completely isolated from the
companion phone and the internet (e.g. validating offline data layer queuing),
use the raw Android `svc` power and network services:

- **Isolate Device (Disable Bluetooth & Wi-Fi)**:
  ```bash
  adb shell svc bluetooth disable
  adb shell svc wifi disable
  ```
- **Restore Connectivity (Enable Bluetooth & Wi-Fi)**:
  ```bash
  adb shell svc bluetooth enable
  adb shell svc wifi enable
  ```

______________________________________________________________________

## 2. Power & Doze Mode

Apps must respect battery constraints and handle Doze mode cleanly.

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

______________________________________________________________________

## 3. UI, Accessibility & Display

Ensure your application's layouts and text scale gracefully across different
form factors and configurations.

- **Dynamic Color Themes (API 36+)**:
  - **Capability**: Test how your app's UI adapts to different Material 3 system
    color palettes (e.g. indigo, lemongrass, porcelain).
  - **Action**: Do not write custom theme injection scripts. Search your active
    skills for pre-approved theme customization automation to toggle these
    Material 3 system palettes.
- **Increase Font Scale (e.g., 1.3x)**:
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

## 4. Physical Inputs & Gestures

Simulate physical Wear OS interactions using `keyevent`.

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

## 5. Language & Localization

Test localized strings without diving into the UI settings.

- **Change Language (e.g., French)**: _(Note: The device UI will briefly restart
  to apply the locale change)_
  ```bash
  adb shell setprop persist.sys.locale fr-FR
  adb shell setprop ctl.restart zygote
  ```

______________________________________________________________________

## 6. Cloud Backup & Restore (Wear 4+)

Wear OS 4+ supports cloud backup and restore (up to 25 MB per app). If the
backup exceeds 25 MB, **no data** is backed up.

- **Simulate Backup**: Force a backup using the local transport.
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

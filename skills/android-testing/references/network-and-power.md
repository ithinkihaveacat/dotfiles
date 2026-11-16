# Network & Power States

Android and Wear OS applications must handle volatile network connections,
device handoffs, and strict operating system power management states gracefully.
Testing these states requires simulating conditions that users frequently
encounter but are tedious to trigger manually.

______________________________________________________________________

## Network & Connectivity Constraints

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

*(For setting up a paired phone + Wear OS emulator Data Layer transport over TCP
port `5601`, see
**[Simulating Devices Without Hardware](simulating-devices.md#paired-phone--wear-os-emulator-bridging)**.)*

### Background Socket Termination (~5s) & Process Freezing (~60s) on Wear OS

Unlike mobile Android—where background network access often persists until Doze
or App Standby kicks in, and where charging lifts many background
restrictions—Wear OS enforces aggressive background data-saver rules immediately
after an activity leaves the screen:

- **~5-Second Socket Teardown (Even Charging & Screen-On)**: Roughly **5
  seconds** after an activity stops (`I/wm_stop_activity` → `procState=LAST`),
  `NetworkPolicyManagerService` applies the `<uid>-background-default` firewall
  rule (`blocked=APP_BACKGROUND|DATA_SAVER`) and immediately destroys the UID's
  live TCP sockets
  (`D/InetDiagMessage: Destroyed live tcp sockets for uids={<uid>}`, surfacing
  in socket/native code as `ECONNABORTED` / errno `103`). This happens **even
  when the watch is sitting on its charger and `stay_on_while_plugged_in` keeps
  the watch face awake**.
- **~60-Second Process Freeze**: Roughly **60 seconds** after leaving the
  screen, the Cached App Freezer freezes the background process (`I/am_freeze`
  in `adb logcat -b events`).
- **Architecture Rule**: Do **not** hold a persistent Foreground Service open
  solely to keep an idle messaging or sync socket alive in the background (which
  severely drains watch battery). Rely on high-priority Firebase Cloud Messaging
  (FCM) data messages to wake the app when new data arrives.
- **Proving OS Socket Teardown via ADB**: Inspect `dumpsys netpolicy` (both the
  firewall transition history and the per-UID `blocked_state` snapshot)
  alongside `adb logcat -b all`:
  ```bash
  adb shell dumpsys netpolicy | grep -E "background-default|blocked_state"
  adb logcat -b all -d | grep -E "wm_stop_activity|InetDiagMessage|am_freeze"
  ```

### Verifying Standalone Watch FCM Delivery (Without Backend Access)

When testing a standalone Wear OS app over Wi-Fi (paired phone in Airplane Mode
with Bluetooth disabled) and expected background pushes never wake the watch
app, isolate watch FCM transport health from server-side push issues using
public on-device tools:

1. **Check the Live Push Socket in the `events` Buffer**: Confirm Google Play
   Services holds an active push connection (`gtalk_connection` and
   `gtalk_heartbeat_reset` without a trailing `gtalk_conn_close`):
   ```bash
   adb logcat -b events -d | grep -E "gtalk_connection|gtalk_heartbeat_reset|gtalk_conn_close"
   ```
1. **Inspect `GcmService` Delivery Counters**: Query Play Services' push service
   dump:
   ```bash
   adb shell dumpsys activity service com.google.android.gms/.gcm.GcmService
   ```
   > [!IMPORTANT] **Watch-Wide `HiPri` Scope:** On Wear OS, the hourly `HiPri`
   > column in `GcmService` aggregates incoming high-priority FCM messages
   > **device-wide across all packages on the watch**—it does not break quotas
   > or counts down per app UID. Corroborate whether your specific package woke
   > by checking `I/am_unfreeze` in `adb logcat -b events` (and avoid polling
   > the app via `adb shell run-as` during the wait, which triggers false
   > `am_unfreeze` events; see
   > **[Permissions, Application State & OS Behavior](permissions-and-os-behavior.md#cached-app-freezer--the-adb-unfreeze-observer-effect)**).
1. **Trigger a Zero-Install Positive Control Push**: Without backend credentials
   or extra test apps, trigger **Play sound / Ring** on the watch from **Google
   Find Hub (Find My Device)** while the paired phone remains in Airplane Mode.
   Verify `I/GCM: Message from ...` and the incoming ring notification arrive on
   the standalone watch over Wi-Fi, confirming end-to-end high-priority FCM
   delivery works on the device.

______________________________________________________________________

## Power & Doze Mode

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

### Samsung Galaxy Watch (One UI Watch) Doze Timeout

Samsung Galaxy Watches transition to ambient/dim mode aggressively (typically
within 5–10 seconds of user inactivity). When performing manual UI verifications
or capturing visual assets, capture validation media immediately after
rendering, or wake the device beforehand using `input keyevent KEYCODE_WAKEUP`.

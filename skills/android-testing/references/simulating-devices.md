# Simulating Devices Without Hardware

Testing Android and Wear OS applications without physical hardware spans three
simulation tiers. Choose the lightest tier that exercises the behavior under
test:

1. **Tier 1 — Off-Device Host-JVM Rendering (`@Preview` & Robolectric)**:
   Instantaneous (~seconds) visual layout, theme, font-scale, accessibility,
   Wear OS Tile, and Remote Compose verification on the host JVM without booting
   an emulator.
1. **Tier 2 — Single-Device Emulator & Standalone Watch Bootstrapping**: Full
   Android OS execution for single-device UI flows, Foreground Services, runtime
   permissions, and synthetic Health Services sensors without a paired phone.
1. **Tier 3 — Paired Phone & Wear OS Emulator Bridging**: Dual-emulator TCP
   transport over port `5601` for testing cross-device Wearable Data Layer APIs
   (`DataClient`, `MessageClient`, `CapabilityClient`, `ChannelClient`, and
   `NodeClient`).

______________________________________________________________________

## Off-Device Host-JVM Preview & UI Simulation

Before booting an emulator, evaluate whether the target UI or surface can be
rendered and inspected directly on the host JVM using an off-device `@Preview`
rendering tool (such as `compose-preview` if available in your workspace, or
Gradle/Robolectric screenshot tests).

### Capabilities Available Without an Emulator

Off-device JVM preview renderers execute Compose and ProtoLayout rendering
pipelines locally against a synthetic `Configuration` and display profile:

- **Wear OS Circular Bezel Masking & Device Profiles**: Render `@Preview`
  functions against round Wear OS device specs (`id:wearos_small_round`,
  `id:wearos_large_round`, `id:wearos_rect`, `id:wearos_square`) with circular
  screen clipping, pinned `TimeText` clock timestamps, and full-height scroll
  capture (`LocalScrollCaptureInProgress`).
- **Configuration Matrices (Font Scale, Locale, Theme, UI Mode)**: Render one
  composable across multiple font scales (`1.0`, `1.24`, `1.5`), locales, dark
  and light themes, or simulated runtime permission states in a single pass.
- **Wear OS Tiles (`TilePreviewData`)**: Render `@Preview` functions returning
  `androidx.wear.tiles.tooling.preview.TilePreviewData` through the local
  ProtoLayout `TileRenderer` without installing an APK or adding a tile to the
  emulator carousel.
- **Remote Compose Documents (`.rc`)**: Compile and render
  `@PreviewWrapper(RemotePreviewWrapper::class)` composables through the actual
  Remote Compose wire format to catch serialization gaps early.
- **Accessibility Checks (ATF)**: Run Accessibility Test Framework evaluations
  (touch target sizing, text contrast, content descriptions, traversal order)
  directly against the rendered semantics tree.

### Boundary: Host-JVM Preview vs. Booted Emulator

| Verification Goal                                                          | Host-JVM `@Preview` | Booted Emulator (`adb`) |
| :------------------------------------------------------------------------- | :-----------------: | :---------------------: |
| Layout, round-bezel clipping, font scaling, locales, dark/light themes     |       **Yes**       |           Yes           |
| Accessibility contrast, touch target bounds, and semantics tree checks     |       **Yes**       |           Yes           |
| Static Wear OS Tile (`TilePreviewData`) & Remote Compose (`.rc`) rendering |       **Yes**       |           Yes           |
| Live SysUI tile carousel / `WidgetTrayActivity` Binder IPC limits          |         No          |         **Yes**         |
| OS OOBE, keyguard, system permission dialogs, and Foreground Services      |         No          |         **Yes**         |
| Synthetic Health Services (`whs.*`), Fused Location, & Wear 7+ gestures    |         No          |         **Yes**         |
| Doze mode, App Standby buckets, battery levels, and radio failover         |         No          |         **Yes**         |
| Cross-device Wearable Data Layer sync (`DataClient`, `MessageClient`)      |         No          |    **Yes (Paired)**     |

______________________________________________________________________

## Single-Device Emulator Setup & System Images

### Choosing the Right System Image Tag

The system image variant determines whether `adb root` is available:

- **Phone Emulators (`google_apis` or `google_apis_ps16k` vs.
  `google_apis_playstore`)**:
  - Prefer **`google_apis`** or **`google_apis_ps16k`** (`userdebug` builds,
    `ro.debuggable=1`) for automated testing and phone–watch emulator pairing.
    These images include Google Play Services (`com.google.android.gms`) while
    allowing `adb root` for SQLite and GMSCore flag configuration.
  - **`google_apis_playstore`** (`user` build, `ro.debuggable=0`) includes the
    Play Store app UI but blocks `adb root`, preventing programmatic
    `WearableService` server seeding.
- **Wear OS Emulators (`android-wear` vs. `android-wear-signed`)**:
  - **`android-wear`** (`userdebug`) allows `adb root` (required for privileged
    operations like disabling the OEM `setupwizard` package or running
    `cmd IWearGestureService hint clear`).
  - **`android-wear-signed`** (`user` Play Store build) blocks `adb root`, but
    supports headless phone–watch Data Layer pairing
    (`com.google.android.gms.wearable.EMULATOR`) and `TUTORIAL_SKIP` broadcasts
    out of the box.

### Headless Launch & Boot Readiness

When starting an emulator from the command line or CI without a display window,
pass
`-no-window -no-audio -no-boot-anim -gpu swiftshader_indirect -no-snapshot-save`
and wait for both `sys.boot_completed=1` and the Package Manager service before
issuing setup commands:

```bash
emulator @<avd_name> -no-window -no-audio -no-boot-anim \
  -gpu swiftshader_indirect -no-snapshot-save &

adb wait-for-device
adb shell 'while [ "$(getprop sys.boot_completed)" != "1" ] || ! pm path android >/dev/null 2>&1; do sleep 1; done'
```

______________________________________________________________________

## Standalone Watch Bootstrapping & Setup Bypass

When running automated UI or visual tests on a fresh Wear OS emulator or
physical watch where companion phone pairing is unnecessary, transition the
watch directly into a standalone provisioned state.

### Mark AOSP Platform Provisioning Complete

Set standard AOSP flags to inform `ActivityManagerService` and
`KeyguardViewMediator` that initial provisioning is complete, enabling standard
`CATEGORY_HOME` launcher activities:

```bash
adb shell settings put global device_provisioned 1
adb shell settings put secure user_setup_complete 1
```

*(Reference: AOSP
[`Settings.Global.DEVICE_PROVISIONED`](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/core/java/android/provider/Settings.java)
and
[`Settings.Secure.USER_SETUP_COMPLETE`](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/core/java/android/provider/Settings.java)).*

### Disable OEM Setup Wizard

On `userdebug` builds or emulators supporting `adb root`, disable the OEM setup
wizard package so it does not intercept the Home intent to enforce phone
pairing:

```bash
adb root

# Stock Wear OS / Pixel Watch:
adb shell pm disable com.google.android.wearable.setupwizard

# Samsung Galaxy Watch (One UI Watch):
adb shell pm disable com.samsung.android.wearable.setupwizard
```

### Wake Up, Unlock, and Dismiss Charging Overlay

If the emulator or watch is simulating a charging state (covering the screen
with a charging ring animation), unplug the simulated charger, wake the display,
and dismiss the keyguard:

```bash
adb shell dumpsys battery unplug
adb shell settings put global stay_on_while_plugged_in 7
adb shell input keyevent KEYCODE_WAKEUP
adb shell wm dismiss-keyguard
```

### Dismiss Wear OS Tutorial & Return to Home

Send the system debug broadcasts handled by Wear OS System UI to bypass the
introductory tutorial overlay, then return to the watch face:

```bash
adb shell am broadcast -a com.google.android.clockwork.action.TEST_MODE
adb shell am broadcast -a com.google.android.clockwork.action.TUTORIAL_SKIP
adb shell input keyevent KEYCODE_HOME
```

*(If a "Skip" dialog remains on screen, send
`adb shell input keyevent KEYCODE_BACK` or tap the screen to dismiss it).*

______________________________________________________________________

## Paired Phone & Wear OS Emulator Bridging

Testing phone–watch synchronization over the Wearable Data Layer API
(`DataClient`, `MessageClient`, `CapabilityClient`, `ChannelClient`, and
`NodeClient`) requires an active `WearableService` transport between a phone
emulator (`google_apis` or `google_apis_ps16k` `userdebug` image) and a Wear OS
emulator (`android-wear` or `android-wear-signed`).

If your workspace includes the `adb-wear-pair` helper script, you can pair two
running emulators or inspect their pairing state directly:

```bash
# Auto-detect running phone and watch emulators and pair them over TCP port 5601
adb-wear-pair

# Check whether connected emulator(s) are Paired & Connected, Paired & Disconnected, or Unpaired
adb-wear-pair --status
```

### Why Phone `WearableService` Needs Two Bootstrap Steps

On a Wear OS emulator, Google Play Services (`com.google.android.gms`)
automatically provisions a default client `ConnectionConfiguration`
(`name='network'`, `connectionType=2` / Network, `role=1` / Client,
`connectionEnabled=1`) that connects via TCP to `127.0.0.1:5601` (falling back
to `10.0.2.2:5601`), and `com.google.android.gms.wearable.EMULATOR` broadcasts
are permitted whenever `inEmulator()` is true.

On a phone emulator, however, GMSCore's `WearableService` stays dormant after
boot for two reasons:

1. **Companion Gate**: `WearableController` skips starting the wearable process
   (`MISSING_COMPANION_APP`) unless `may_run_without_wearable_app` is enabled in
   GMSCore flags or a companion package (`com.google.android.wearable.app`) is
   installed.
1. **Missing Server Config**: Phone GMSCore does not create a default
   `ROLE_SERVER` (`role=2`) network row in
   `/data/data/com.google.android.gms/databases/connectionconfig.db` until a
   companion app invokes `putConfig()`.

### Manual Headless Pairing Sequence

When `adb-wear-pair` is not available, execute the four-step sequence below
using raw `adb` commands.

#### Enable Phone `WearableService` and Initialize `connectionconfig.db`

Elevate ADB to root on the phone emulator, wake GMSCore's wearable module, send
the `com.google.android.gms.wearable` `may_run_without_wearable_app` flag
override (`--ez commit true`), and wait for the asynchronous SQLite override
transaction to commit to `phenotype.db` before restarting GMSCore (killing
GMSCore immediately after `am broadcast` aborts the in-flight SQLite write on
cold or wiped boots):

```bash
PHONE=emulator-5554
WATCH=emulator-5556

adb -s "$PHONE" root
adb -s "$PHONE" shell '
  am startservice -a com.google.android.gms.wearable.BIND -p com.google.android.gms >/dev/null 2>&1 || true
  for i in $(seq 1 25); do
    if [ "$i" -eq 1 ] || [ $((i % 5)) -eq 0 ]; then
      am broadcast -a com.google.android.gms.phenotype.FLAG_OVERRIDE \
        -p com.google.android.gms \
        --es package com.google.android.gms.wearable \
        --es user "*" \
        --esa flags may_run_without_wearable_app \
        --esa values true \
        --esa types boolean \
        --ez commit true >/dev/null
    fi
    cnt=$(sqlite3 /data/data/com.google.android.gms/databases/phenotype.db \
      "SELECT (SELECT COUNT(*) FROM flag_overrides WHERE name='\''may_run_without_wearable_app'\'' AND active=1) + (SELECT COUNT(*) FROM FlagOverrides WHERE name='\''may_run_without_wearable_app'\'' AND boolVal=1);" 2>/dev/null || echo 0)
    pending=$(sqlite3 /data/data/com.google.android.gms/databases/phenotype.db \
      "SELECT COUNT(*) FROM flag_overrides_to_commit;" 2>/dev/null || echo 0)
    case "$cnt" in [1-9]*) [ "$pending" = "0" ] && break ;; esac
    sleep 0.2
  done
  am force-stop com.google.android.gms
  am startservice -a com.google.android.gms.wearable.BIND -p com.google.android.gms
'
```

*(Alternative: Installing a minimal codeless stub APK with package name
`com.google.android.wearable.app` and `<application android:hasCode="false"/>`
also satisfies the package-presence check).*

Wait for `/data/data/com.google.android.gms/databases/connectionconfig.db` to
appear on the phone (typically 1–5 seconds after `startservice`):

```bash
adb -s "$PHONE" shell '
  for i in $(seq 1 30); do
    [ -f /data/data/com.google.android.gms/databases/connectionconfig.db ] && exit 0
    sleep 1
  done
  exit 1
'
```

#### Seed the Server TCP Row and Align `network_id`

Execute `sqlite3` as GMSCore's Linux UID (`stat -c %U`) so the database journal
and file ownership remain readable by `com.google.android.gms`. Delete any stale
`connectionType = 2` rows from previous pairings before inserting `'server'`. If
the watch was already paired in an earlier session (and holds a non-null
`cloud network id` in `CloudNodeAdapter`), write that `network_id` into the
phone's `shared_prefs/wearable.xml` while GMSCore is stopped so the TCP
handshake does not fail with `Wear_Transport: Error: networkid mismatch`:

```bash
WATCH_NET_ID=$(adb -s "$WATCH" shell dumpsys activity service WearableService CloudNodeAdapter |
  tr -d '\r' | sed -n 's/^[[:space:]]*cloud network id: \([0-9][0-9]*\)$/\1/p' | head -n 1)

adb -s "$PHONE" shell "
  am force-stop com.google.android.gms
  GMS_UID=\$(stat -c %U /data/data/com.google.android.gms)
  su \"\$GMS_UID\" sqlite3 /data/data/com.google.android.gms/databases/connectionconfig.db \
    \"DELETE FROM connectionConfigurations WHERE connectionType = 2; INSERT INTO connectionConfigurations (name, pairedBtAddress, connectionType, role, connectionEnabled) VALUES ('server', 'NULL_STRING', 2, 2, 1);\"
  if [ -n '$WATCH_NET_ID' ] && [ -f /data/data/com.google.android.gms/shared_prefs/wearable.xml ]; then
    sed -i 's|<string name=\"network_id\">[^<]*</string>|<string name=\"network_id\">$WATCH_NET_ID</string>|' \
      /data/data/com.google.android.gms/shared_prefs/wearable.xml
  fi
  am startservice -a com.google.android.gms.wearable.BIND -p com.google.android.gms
"
```

#### Bridge Port `5601` and Refresh the Emulator Connection

Forward host TCP port `5601` into the phone emulator (`ROLE_SERVER`) and reverse
watch TCP port `5601` back to the host (`ROLE_CLIENT`), then ask the watch to
reconnect immediately:

```bash
adb -s "$PHONE" forward tcp:5601 tcp:5601
adb -s "$WATCH" reverse tcp:5601 tcp:5601
adb -s "$WATCH" shell cmd activity broadcast \
  -a com.google.android.gms.wearable.EMULATOR \
  --es operation refresh-emulator-connection
```

Once the TCP handshake completes, phone GMSCore automatically migrates the
`'server'` row in `connectionconfig.db` to a peer-bound entry (setting `nodeId`
and `pairedBtAddress='EmulatorAddr-<watchNodeId>'`).

#### Verify Pairing & Inspect Data Layer State

Query `get-pairing-status` on one or both emulators (or run
`adb-wear-pair --status` if available):

```bash
adb -s "$PHONE" shell cmd activity broadcast \
  -a com.google.android.gms.wearable.EMULATOR --es operation get-pairing-status
adb -s "$WATCH" shell cmd activity broadcast \
  -a com.google.android.gms.wearable.EMULATOR --es operation get-pairing-status
```

The broadcast output distinguishes three states on any emulator:

- **Paired & Connected**: `Local:[6c5e1337]` followed by
  `Peer:[585efd19,true,true]` (both connected and nearby booleans are `true`).
- **Previously Paired, Currently Disconnected** (e.g. only the watch emulator is
  running or TCP forwarding was reset): `Local:[6c5e1337]` followed by
  `Peer:[585efd19,false,false]`.
- **Unpaired (Standalone)**: Only `Local:[6c5e1337]` is printed with no `Peer:`
  line.

To inspect deeper Wearable Data Layer state during test execution, query the
individual `WearableService` sub-services:

```bash
# Active TCP sockets, ConnectionConfiguration rows, and read/write byte counters
adb -s "$WATCH" shell dumpsys activity service WearableService ConnectionServiceManager

# Connected Node IDs and hop counts
adb -s "$WATCH" shell dumpsys activity service WearableService NodeService

# Advertised static and dynamic capabilities across phone and watch packages
adb -s "$WATCH" shell dumpsys activity service WearableService CapabilityService

# Replicated DataItems, assets, and storage summary
adb -s "$WATCH" shell dumpsys activity service WearableService DataService
```

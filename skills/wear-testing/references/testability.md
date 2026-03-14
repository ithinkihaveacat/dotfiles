# Wear OS App Testability & Debugging Patterns

This document is a collection of suggestions for how to instrument your Wear OS
app (e.g., exclusively in `debug` builds) to make it easier to automatically
test various transitions and edge cases.

While the other reference files in this skill focus on QA processes and ADB
commands to manipulate the OS, this document focuses entirely on **app-side
changes** that facilitate those tests.

## 1. Debug Broadcast Receivers

Adding a non-exported (or signature-protected) `BroadcastReceiver` strictly for
debug builds allows you to bypass complex UI flows and reliably simulate rare
states during automated testing.

### Onboarding & Auth Bypass

Pairing a watch to a phone is the most time-consuming part of Wear development.

- **Instrumentation**: Implement a receiver that accepts `accessToken`,
  `refreshToken`, and `userId` as intent extras.
- **Testing Goal**: Skip the "Continue on phone" pairing screens and jump
  straight into an authenticated app state for fast UI testing.
- **Command Example**:
  `adb shell am broadcast -a com.your.app.DEBUG_LOGIN --es accessToken "..."`

### Data Seeding & Replay

Validating health or activity metrics often requires hours of movement.

- **Instrumentation**: Create a "Seeder" or "Replayer" that reads synthetic data
  (e.g., from a Protobuf file or intent extras) and injects it into the app's
  local database or mocks your `HealthServices` client.
- **Testing Goal**: Simulate a 4-hour hike or 500 steps in 10 minutes to verify
  UI summaries, achievement alerts, and Ongoing Activity tracking.

### Feature & UI Triggers

Notifications and "Morning Brief" style screens often rely on complex background
schedules.

- **Instrumentation**: Add intents to manually trigger the `Notification` or
  `ForegroundService` responsible for the UI.
- **Testing Goal**: Verify the layout and haptics of an "Achievement" alert
  without waiting hours for the actual goal to be met.

## 2. Sync & State Control

- **Force Immediate Sync**: Instead of waiting for `WorkManager` or
  `GcmNetworkManager` intervals, add a debug trigger to force an end-to-end sync
  with the backend. This guarantees your automated tests don't flake due to
  background execution delays.
- **Clear State / Reset OOBE**: Provide a command to wipe local databases and
  shared preferences to test "First Run" experiences repeatedly without a full
  app reinstall.

## 3. Instrumenting Against Common Pitfalls

These are common Wear OS failure modes. Consider adding specific debug hooks to
make testing these transitions reliable.

### Data Layer Latency vs. System Notifications

- **The Pitfall**: When Bluetooth disconnects, the system switches to Wi-Fi/LTE.
  Apps often delay "Cellular Active" warnings because they are waiting for a
  Data Layer message that is now queued.
- **Instrumentation**: Add a debug overlay or log that explicitly prints the
  _source_ of the connectivity state (e.g., "Source: Local TelephonyManager" vs
  "Source: DataLayer"). This helps testers immediately spot when the app is
  inappropriately relying on the phone for local state.

### OOBE & Account Race Conditions

- **The Pitfall**: Apps often attempt to sync or login immediately after the
  watch finishes its Out-of-Box Experience (OOBE). If the network isn't fully
  initialized, this can lead to persistent "Not Connected" errors.
- **Instrumentation**: Add a debug broadcast that forcefully restarts your app's
  initialization sequence. This allows testers to simulate the exact moment of
  OOBE completion
  (`adb shell am broadcast -a com.google.android.clockwork.action.TEST_MODE`)
  and follow it immediately with your initialization trigger to catch race
  conditions.

### Simulating App Hibernation & Standby

- **The Pitfall**: If a user doesn't interact with your app for months, it goes
  into hibernation (permissions revoked, cache cleared).
- **Instrumentation**: While you can trigger hibernation via ADB
  (`adb shell cmd app_hibernation set-state <package> true`), you should
  instrument your app to log its recovery path on the next cold boot to ensure
  it gracefully re-requests permissions rather than crashing.

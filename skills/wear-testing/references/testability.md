# Wear OS App Testability & Debugging Patterns

Testing Wear OS apps is often bottlenecked by physical constraints (wearing the device) or slow connectivity (Data Layer sync). To make apps highly testable, follow these patterns discovered in large-scale Wear OS implementations.

## 1. Debug Broadcast Receivers

Adding a non-exported (or signature-protected) `BroadcastReceiver` for debug builds allows you to bypass complex UI flows and simulate rare states.

### Onboarding & Auth Bypass
Pairing a watch to a phone is the most time-consuming part of Wear development.
- **Pattern**: Implement a receiver that accepts `accessToken`, `refreshToken`, and `userId` as intent extras.
- **Test Scenario**: Skip the "Continue on phone" pairing screens and jump straight into an authenticated app state.
- **Command Example**: `adb shell am broadcast -a com.your.app.DEBUG_LOGIN --es accessToken "..."`

### Data Seeding & Replay
Validating health or activity metrics often requires hours of movement.
- **Pattern**: Create a "Seeder" or "Replayer" that reads synthetic data (e.g., from a Protobuf file or intent extras) and injects it into the app's local database or `HealthServices` client.
- **Test Scenario**: Simulate a 4-hour hike or 500 steps in 10 minutes to verify UI summaries and achievement alerts.

### Feature & UI Triggers
Notifications and "Morning Brief" style screens often rely on complex background schedules.
- **Pattern**: Add intents to manually trigger the `Notification` or `ForegroundService` responsible for the UI.
- **Test Scenario**: Verify the layout and haptics of an "Achievement" alert without actually meeting the goal.

## 2. Sync & State Control

- **Force Immediate Sync**: Instead of waiting for `WorkManager` or `GcmNetworkManager` intervals, add a debug trigger to force an end-to-end sync with the backend.
- **Clear State / Reset OOBE**: Provide a command to wipe local databases and shared preferences to test "First Run" experiences repeatedly without a full app reinstall.

## 3. Common Testing Pitfalls (Watch out for these!)

### Data Layer Latency vs. System Notifications
- **The Issue**: When Bluetooth disconnects, the system should switch to Wi-Fi or LTE. A common bug is a delay in the app's "Cellular Active" warning because it's waiting for a Data Layer message that is now queued.
- **Testing Goal**: Ensure critical system-state warnings (like "LTE Connected") are triggered by local connectivity listeners, not just synced state from the phone.

### Global Location vs. App Permission
- **The Issue**: On Wear OS 4+, there is a global location toggle. Users often disable this thinking it only saves battery, which breaks weather/exercise apps even if the *app* has permission.
- **Testing Goal**: Specifically test app behavior when the **Global Location** is OFF but the **App Permission** is ON.

### OOBE & Account Race Conditions
- **The Issue**: Apps often attempt to sync or login immediately after the watch finishes its Out-of-Box Experience (OOBE). If the network isn't fully initialized, this can lead to persistent "Not Connected" errors.
- **Testing Goal**: Test the "First Login" flow immediately following an `adb shell am broadcast -a com.google.android.clockwork.action.TEST_MODE` (OOBE skip).

### Font & Density Scaling
- **The Issue**: Wear devices have tiny screens. Large font scales (1.3x+) or small DPI often cause critical buttons to be pushed off the round screen.
- **Testing Goal**: Always test the "Dismiss" or "Action" buttons on every alert with max font scale.

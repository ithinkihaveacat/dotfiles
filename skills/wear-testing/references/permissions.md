# Wear OS Permissions & Behavioral Changes

Testing permissions on Wear OS requires understanding both the baseline Android
changes (API 30-36) and the Wear-specific quirks (like cross-device requesting
and granular health siloing).

## Health & Biometric Permissions

The most volatile area of Wear OS permissions is body sensor access. You must
test these across different API levels, particularly focusing on the transition
to granular permissions in Wear OS 6 (API 36+).

### Wear OS 5 (API 34) and Below

- **`android.permission.BODY_SENSORS`**: Grants general access while the app is
  in the foreground.
- **`android.permission.BODY_SENSORS_BACKGROUND`**: (Introduced API 33/Wear 4) A
  "hard-restricted" permission. Must be requested _separately_ from the
  foreground permission. The system dialog does not offer "Allow all the time";
  it routes users to the system Settings app.
- **Testing Goal**: Verify that your app degrades gracefully if the user grants
  `BODY_SENSORS` but declines the background settings toggle.

### Wear OS 6 (API 36+)

API 36 completely silos health access to match Health Connect. The broad
`BODY_SENSORS` permission is deprecated in favor of granular ones.

- **`android.permission.health.READ_HEART_RATE`**
- **`android.permission.health.READ_OXYGEN_SATURATION`**
- **`android.permission.health.READ_SKIN_TEMPERATURE`**
- **`android.permission.health.READ_HEALTH_DATA_IN_BACKGROUND`**
- **Testing Goal (Upgrades)**: Install your app targeting API <= 35, grant
  `BODY_SENSORS`, then simulate an OS upgrade to Wear OS 6. The OS should
  intercept the old request and automatically map it to `READ_HEART_RATE`.
- **Testing Goal (Privacy Policy)**: Apps using these new granular permissions
  _must_ declare an Activity to display a privacy policy. If missing, the OS
  revokes the permission immediately. Test this failure mode.

### Modifying Permission State via ADB

Manually tapping through system settings is slow. Use ADB to rapidly toggle
permission states to test your app's "denied" fallbacks.

- **Grant a Permission**:

  ```bash
  adb shell pm grant <your.package.name> android.permission.health.READ_HEART_RATE
  ```

- **Revoke a Permission**:

  ```bash
  adb shell pm revoke <your.package.name> android.permission.health.READ_HEART_RATE
  ```

- **Clear all state (Hibernation/Auto-Reset simulation)**: If a user doesn't use
  the app for months, permissions are auto-reset (API 30+). Force this state:

  ```bash
  adb shell cmd app_hibernation set-state <your.package.name> true
  ```

## Foreground Services (FGS)

Wear apps heavily rely on Foreground Services to survive ambient mode and track
workouts.

### API 34+ (Wear OS 5) Restrictions

- Every FGS must declare a specific `foregroundServiceType` in the manifest.
- **Testing Goal**: If an app calls `startForeground()` without fulfilling the
  runtime prerequisites (e.g., starting a `location` FGS without
  `ACCESS_COARSE_LOCATION`), the system throws a fatal `SecurityException`.
  Revoke the location permission via ADB and ensure the app doesn't crash when
  the user hits "Start Workout".
- **Relevant Types**: `health` (requires body sensors), `location` (requires
  coarse/fine location), `connectedDevice` (requires Bluetooth/Network).

## Watch Face & Complication Permissions

Watch Faces themselves should _not_ request runtime permissions directly to
avoid interrupting the user's quick glance. Instead, complications should handle
their own permissions.

### Watch Face Push API (Wear OS 6)

If building a marketplace app that pushes watch faces directly to the watch:

- **`com.google.wear.permission.SET_PUSHED_WATCH_FACE_AS_ACTIVE`**: This runtime permission has a **maximum rejection count of 1**.
- **Testing Goal**: Deny this prompt *once*. The application is permanently barred from requesting it again via the standard dialog. Ensure your app handles this by deep-linking the user into system settings.

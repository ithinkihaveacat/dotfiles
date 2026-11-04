# Permissions, Application State & OS Behavior

Testing permissions, application state, and system lifecycle behavior on Android
and Wear OS requires understanding both baseline Android platform mechanics and
surprising places where state persists across reinstalls (such as install-time
cloud backup, Google Play Services Block Store, installer attribution, and
paired-device Data Layer caches).

______________________________________________________________________

## Health & Biometric Permissions

The most volatile area of Wear OS permissions is body sensor access. You must
test these across different API levels, particularly focusing on the transition
to granular permissions.

### Wear OS 5 (API 34) and Below

- **`android.permission.BODY_SENSORS`**: Grants general access while the app is
  in the foreground.
- **`android.permission.BODY_SENSORS_BACKGROUND`**: (Introduced API 33/Wear 4) A
  "hard-restricted" permission. Must be requested *separately* from the
  foreground permission. The system dialog does not offer "Allow all the time";
  it routes users directly to the system Settings app.
- **Testing Goal**: Verify that your app degrades gracefully if the user grants
  `BODY_SENSORS` but declines the background settings toggle.

### Wear OS 6 (API 36+)

API 36 completely silos health access to match Health Connect. The broad
`BODY_SENSORS` permission is deprecated in favor of granular ones:

- **`android.permission.health.READ_HEART_RATE`**
- **`android.permission.health.READ_OXYGEN_SATURATION`**
- **`android.permission.health.READ_SKIN_TEMPERATURE`**
- **`android.permission.health.READ_HEALTH_DATA_IN_BACKGROUND`**
- **Testing Goal (Upgrades)**: Install your app targeting API \<= 35, grant
  `BODY_SENSORS`, then simulate an OS upgrade to Wear OS 6. The OS should
  intercept the old request and automatically map it to `READ_HEART_RATE`.
- **Testing Goal (Privacy Policy)**: Apps using these new granular permissions
  *must* declare an Activity to display a privacy policy. If missing, the OS
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

______________________________________________________________________

## Foreground Services (FGS)

Wear apps rely heavily on Foreground Services to survive ambient mode and track
workouts in the background.

### API 34+ (Wear OS 5) Restrictions

- Every FGS must declare a specific `foregroundServiceType` in the manifest.
- **Testing Goal**: If an app calls `startForeground()` without fulfilling the
  runtime prerequisites (e.g. starting a `location` FGS without
  `ACCESS_COARSE_LOCATION`), the system throws a fatal `SecurityException`.
  Revoke the location permission via ADB and ensure the app doesn't crash when
  the user hits "Start Workout".
- **Relevant Types**: `health` (requires body sensors), `location` (requires
  location), `connectedDevice` (requires Bluetooth/Network).

______________________________________________________________________

## Watch Face & Complication Permissions

Watch Faces themselves should *not* request runtime permissions directly to
avoid interrupting the user's quick glance. Instead, complications should handle
their own permissions.

### Watch Face Push API (Wear OS 6)

If building a marketplace app that pushes watch faces directly to the watch:

- **`com.google.wear.permission.SET_PUSHED_WATCH_FACE_AS_ACTIVE`**: This runtime
  permission has a **maximum rejection count of 1**.
- **Testing Goal**: Deny this prompt *once*. The application is permanently
  barred from requesting it again via the standard dialog. Ensure your app
  handles this by deep-linking the user into system settings.

______________________________________________________________________

## Package De-isolation & Stopped State (FLAG_STOPPED)

### Emulator & Device Stopped State (API 36 and Lower)

On Android API 36 and lower, packages installed via `adb install` remain in the
`FLAG_STOPPED` state until explicitly launched by the user or an explicit
intent. While in `FLAG_STOPPED`, background broadcasts, tile/widget bindings,
and Binder IPC calls to the package are blocked by the OS. Clear this stopped
state by explicitly launching a main activity before evaluating services or
widgets:

```bash
adb shell monkey -p <package_name> -c android.intent.category.LAUNCHER 1
```

______________________________________________________________________

## Language & Localization

Test localized strings across system and app locales without navigating the
Settings UI:

- **Change System Language (e.g., French)** _(requires `adb root`; the device UI
  briefly restarts to apply the locale change)_:
  ```bash
  adb shell setprop persist.sys.locale fr-FR
  adb shell setprop ctl.restart zygote
  ```

______________________________________________________________________

## Application State & Persistence Across Reinstalls

When testing onboarding, authentication, or error handling, state often persists
in surprising places outside an app's local sandbox—causing a freshly installed
APK to behave differently than it would for a first-time user.

### 1. Cloud Auto Backup & Install-Time Restore (`BackupManager`)

Android 6.0+ (API 23+) and Wear OS 4+ support automatic cloud backup and restore
(up to 25 MB per app; if the backup exceeds 25 MB, **no data** is backed up).
When you reinstall an app (`adb install`) on a device signed into a Google
Account that has used the app before, `BackupManager` (`bmgr`) silently restores
backed-up `SharedPreferences`, databases, and auth tokens from Google Drive
**during package installation, before the app is ever launched**.

- **Guarantee a Clean First Run (Defeat Install-Time Restore)**: Run `pm clear`
  *after* `adb install` completes and *before* launching the app. This wipes the
  restored `/data/data/<package>` directory without re-triggering install-time
  restore:
  ```bash
  adb install-multiple -r -i com.android.vending base.apk split_config.*.apk
  adb shell pm clear <your.package.name>
  ```
- **Explicitly Test Backup & Restore Flows**:
  ```bash
  adb shell bmgr backupnow <your.package.name>
  adb shell pm clear <your.package.name>
  adb shell bmgr restore <your.package.name>
  ```

### 2. Google Play Services State (`BlockStore` & OAuth Grants)

Even after `adb uninstall` and `adb shell pm clear`, two forms of account state
persist inside Google Play Services (`com.google.android.gms`):

- **Block Store (`com.google.android.gms.auth.blockstore`)**: Credentials saved
  via the Block Store API reside in Play Services storage rather than the app's
  `/data/data/<package>` directory, surviving both app uninstallation and
  `pm clear`.
- **Prior Google Account OAuth Grants (`AccountManager` / Credential Manager)**:
  If the device's Google Account previously granted OAuth consent to the app,
  silent sign-in (`GoogleAuthUtil` or Credential Manager) can succeed on first
  launch without showing a consent screen. Test with a fresh account (or revoke
  the app's access in Google Account settings) to reproduce true first-time
  sign-in prompts.

### 3. Paired Phone ↔ Watch State (`WearableService` Data Layer Cache)

On paired phone and Wear OS devices, state is shared across nodes via Google
Play Services (`WearableService`):

- **Persistent Cross-Node `DataItem`s**: `DataItem`s written by the **remote
  node** (`DataClient.putDataItem()`) are cached locally and **survive
  uninstalling and reinstalling the local app**. They are only purged when the
  companion app on the remote device is also uninstalled or cleared.
- **Advertised Capabilities & Background Listeners**: An installed companion app
  on the paired device continues advertising `CapabilityClient` capabilities
  (`res/values/wear.xml`) and responding to background `MessageClient` requests
  even if never opened during the test. To test standalone or missing-companion
  behavior, uninstall (or disable) the package on **both** the phone and watch.

### 4. Pre-Installed System Apps (`pm disable-user`)

Pre-installed system apps cannot be removed with `adb uninstall` on unrooted
builds. To reset a system preload or simulate an absent companion app on a
paired device, temporarily disable it for the current user and clear its data:

```bash
adb shell pm disable-user --user 0 <your.package.name>
adb shell pm clear <your.package.name>

# Restore the pre-installed app after testing:
adb shell pm enable <your.package.name>
```

### 5. Installer Attribution (`getInstallSourceInfo`) & Play Licensing (`pairip`)

- **Installer Attribution**: Plain `adb install` sets the installer package to
  `null` (or `com.android.shell`). If an app checks
  `PackageManager.getInstallSourceInfo()`, pass `-i com.android.vending` so the
  OS attributes the install to Google Play:
  ```bash
  adb install -r -i com.android.vending app.apk
  ```
- **Play Integrity License Checks (`com.pairip.licensecheck`)**: Release APKs
  wrapped with Google Play's `LicenseActivity` verify a Play-issued license
  token at startup and will redirect sideloaded installs to the Play Store
  unless installed directly from Play or tested with an unwrapped/debug build.

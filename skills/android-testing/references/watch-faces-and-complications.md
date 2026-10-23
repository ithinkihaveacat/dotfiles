# Watch Faces & Complications

Testing Wear OS applications includes validating interactions with watch faces
and modular complication data fields across active and ambient states.

*(For bootstrapping a fresh Wear OS emulator or watch past the setup wizard and
tutorial overlays without pairing a phone, see
**[Simulating Devices Without Hardware](simulating-devices.md#standalone-watch-bootstrapping--setup-bypass)**.)*

______________________________________________________________________

## Complications & Watch Faces

Complications are modular data fields on a Watch Face. Testing complications
involves simulating data updates and tapping actions.

### Triggering Complication Updates

Force the system to update a complication's data feed via the `DEBUG_SYSUI`
broadcast (or a workspace helper such as `adb-complication-update <ID>` if
available):

```bash
adb shell am broadcast -a com.google.android.wearable.app.DEBUG_SYSUI \
  --es operation complication_update --ei complication_id <ID>
```

### Simulating Watch Face Environments (Wear OS 4+)

Test how complications and watch faces render across different system states
(such as ambient mode, low-power mode, and screen-off states).

- **Force Ambient Mode (Low Power / Screen Dimmed)**:
  ```bash
  adb shell cmd wearable_sensing set-ambient-mode true
  ```
- **Exit Ambient Mode**:
  ```bash
  adb shell cmd wearable_sensing set-ambient-mode false
  ```
- **Query Active Complication Providers**:
  ```bash
  adb shell dumpsys package | grep -A 10 "complication"
  ```

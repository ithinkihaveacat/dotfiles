# Wear Surfaces (Watchfaces, Tiles, Complications)

Wear OS features specialized UI surfaces outside the main app. Testing these
reliably requires specific, official developer `am broadcast` intents defined by
the Android CDD.

These commands require that the device has **Developer Options enabled**. They
work across all Wear OS 3+ devices, including physical Pixel and Galaxy Watches,
and emulators.

## Tiles

Instead of manually swiping through the carousel, you can programmatically
deploy, reveal, and remove Tiles.

- **Add a Tile to the Carousel (and get its index)**: Note: If the tile is
  already added, this command removes and re-adds it, effectively refreshing it.

  ```bash
  adb shell am broadcast -a com.google.android.wearable.app.DEBUG_SURFACE \
    --es operation add-tile \
    --ecn component "com.example.app/.MyTileService"
  ```

- **Show a Tile in the Foreground**: Takes the integer `index` returned from the
  `add-tile` command.

  ```bash
  adb shell am broadcast -a com.google.android.wearable.app.DEBUG_SYSUI \
    --es operation show-tile \
    --ei index 0
  ```

- **Remove a Tile**:

  ```bash
  adb shell am broadcast -a com.google.android.wearable.app.DEBUG_SURFACE \
    --es operation remove-tile \
    --ecn component "com.example.app/.MyTileService"
  ```

_(You can also use the bundled `scripts/adb-tile-add`, `scripts/adb-tile-show`,
and `scripts/adb-tile-remove` which wrap these commands with safety checks and
error parsing)._

## Watchfaces

Programmatically change the active Watchface to test lifecycle and rendering.

- **Set the Active Watchface**: Alternatively, you can use
  `--es watchFaceId "id"` if the watchface uses an ID.

  ```bash
  adb shell am broadcast -a com.google.android.wearable.app.DEBUG_SURFACE \
    --es operation set-watchface \
    --ecn component "com.example.app/.MyWatchFaceService"
  ```

- **Show the Watchface (Interactive Mode)**: Ensures the UI navigates to the
  watchface and turns on interactive mode (wakes from ambient).

  ```bash
  adb shell am broadcast -a com.google.android.wearable.app.DEBUG_SYSUI \
    --es operation show-watchface
  ```

- **Revert to the Previous Watchface**:

  ```bash
  adb shell am broadcast -a com.google.android.wearable.app.DEBUG_SURFACE \
    --es operation unset-watchface
  ```

- **Get the Current Watchface Component**:

  ```bash
  adb shell am broadcast -a com.google.android.wearable.app.DEBUG_SURFACE \
    --es operation current-watchface
  ```

## Complications

Test your Complication Data Providers by injecting them directly into the
current watchface.

- **Set a Complication in a Slot**: Specify the complication provider component,
  the target watchface, the slot ID (integer), and the complication type
  (integer or string).

  ```bash
  adb shell am broadcast -a com.google.android.wearable.app.DEBUG_SURFACE \
    --es operation set-complication \
    --ecn component "com.example.app/.MyComplicationProvider" \
    --ecn watchface "com.example.watchface/.MyWatchFaceService" \
    --ei slot 1 \
    --ei type 3
  ```

- **Remove a Complication**:

  ```bash
  adb shell am broadcast -a com.google.android.wearable.app.DEBUG_SURFACE \
    --es operation unset-complication \
    --ecn component "com.example.app/.MyComplicationProvider"
  ```

## Watch-specific Debugging Settings

- **Set a Debug App**: Setting a debug app extends the timeout for Tile
  providers (up to 20 minutes) when the system binds to them, preventing silent
  failures during breakpoint debugging.

  ```bash
  adb shell am broadcast -a com.google.android.wearable.app.DEBUG_SURFACE \
    --es operation set-debug-app \
    --es package "com.example.app"
  ```

- **Clear the Debug App**:

  ```bash
  adb shell am broadcast -a com.google.android.wearable.app.DEBUG_SURFACE \
    --es operation clear-debug-app
  ```

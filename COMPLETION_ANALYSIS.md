# Fish Shell Completion Analysis

## Executive Summary

This analysis identifies opportunities for Fish shell completions across 154
scripts in `bin/`. The scripts fall into clear categories with common argument
types that can share completion logic.

**Key Finding**: 91 scripts (59%) would benefit from completions, with 5 shared
completion functions covering the majority of use cases.

## Existing Completions

Currently only 3 completion files exist:

- `fish/completions/adb-dumpsys-service.fish` - Static completions for service
  names
- `fish/completions/emumanager.fish` - Comprehensive with dynamic AVD name
  completion
- `fish/completions/fnm.fish` - Node version manager (external tool)

## Script Categories and Argument Types

### 1. Android Package Name Scripts (20 scripts)

**All `packagename-*` scripts** require an Android package name as the primary
argument:

- `packagename-baseline-profile`
- `packagename-baseline-profile-generate`
- `packagename-clear-cache`
- `packagename-dumpsys`
- `packagename-force-stop`
- `packagename-jobscheduler`
- `packagename-launch`
- `packagename-logcat`
- `packagename-permissions`
- `packagename-pid`
- `packagename-pull`
- `packagename-reset-permissions`
- `packagename-services`
- `packagename-services-dumpsys`
- `packagename-tiles`
- `packagename-uninstall`
- `packagename-version`
- `packagename-view`
- `packagename-view-on-play-store`
- `packagename-view-settings`
- `packagename-watchface`

**Additional scripts that accept package names**:

- `adb-logcat-package` - Takes package name
- `adb-exit-info` - Takes package name
- `adb-jobscheduler` - Optional package name parameter
- `adb-not-optimized` - Takes package name

**Shared Completion Opportunity**: `__fish_android_packages`

- Dynamically list installed packages via `adb shell pm list packages`
- Used by 24+ scripts

### 2. APK/ZIP File Scripts (15 scripts)

Scripts that operate on APK or ZIP files:

- `apk-badging`
- `apk-cat-file`
- `apk-cat-launcher`
- `apk-cat-manifest`
- `apk-complications`
- `apk-decode`
- `apk-install-and-launch` (includes `-f` flag)
- `apk-launch`
- `apk-launcher-icon-extract`
- `apk-packagename`
- `apk-tiles`
- `apk-unzip`
- `apk-version-code`
- `apk-version-name`
- `apk-version-wear-compose`
- `apk-version-whs`

**Shared Completion Opportunity**: Standard Fish file completion with filter

- Use `complete -c <cmd> -F -a '(__fish_complete_suffix .apk .zip)'`
- 15 scripts benefit

### 3. Android Component Name Scripts (2 scripts)

Scripts requiring component names (package/class):

- `adb-tile-add` - Takes component name (e.g.,
  `com.example/com.example.TileService`)
- `adb-tile-remove` - Takes tile index (numeric)

**Shared Completion Opportunity**: `__fish_android_tile_components`

- Could parse installed packages for TileService classes
- Complex to implement dynamically
- May be better suited to manual/static completions initially

### 4. Service Name Scripts (2 scripts)

Scripts that take Android service names:

- `adb-dumpsys-service` - Already has completions!
- `service-dumpsys` - Takes service name
- `service-location-summary` - No args
- `service-metadata` - Takes service name

**Shared Completion Opportunity**: `__fish_android_services`

- List services via `adb shell service list`
- 3 scripts benefit

### 5. No-Argument Scripts (40+ scripts)

Many scripts take no arguments and just need flag completions:

**ADB Utilities (no args)**:

- `adb-account`
- `adb-api-level`
- `adb-battery-stats`
- `adb-charging-off`
- `adb-charging-on`
- `adb-currentfocus`
- `adb-demo-off`
- `adb-demo-on`
- `adb-device-properties`
- `adb-devices`
- `adb-dumpsys-batterystats`
- `adb-dumpsys-power`
- `adb-dumpsys-whs`
- `adb-dumpsys-whs-logs`
- `adb-fontscale-default`
- `adb-fontscale-large`
- `adb-keyevent-sleep`
- `adb-keyevent-wakeup`
- `adb-packages`
- `adb-settings-theme`
- `adb-touches-off`
- `adb-touches-on`
- `adb-version-sft`
- `wearableservice-capabilities`
- `wearableservice-items`
- `wearableservice-nodes`
- `wearableservice-rpcs`

**Completion Strategy**: Simple `-h/--help` flag only

- Can create minimal completions or skip entirely

### 6. Special Argument Scripts (10+ scripts)

Scripts with unique argument patterns:

- `adb-exec-and-wait` - Takes local script file
- `adb-intent-view` - Takes URL
- `adb-log` - Takes log message
- `adb-logcat-tag` - Takes log tag name
- `adb-screenrecord` - Optional output file
- `adb-screenrecord-raw` - Optional output file
- `adb-screenshot` - Optional output file
- `adb-setting-location-accuracy` - Takes accuracy mode
- `adb-tile-show` - Takes tile index (numeric)
- `apk-cat-file` - Takes APK + file path within APK

**Completion Strategy**: Individual completions based on argument type

### 7. Non-Android Scripts (50+ scripts)

Scripts unrelated to Android development:

**Git tools**: `git-*` (10 scripts) **Context tools**: `context-jetpack`,
`repomix-*` (6 scripts) **Photo tools**: `photos-*` (7 scripts) **Init tools**:
`*-init` (7 scripts) **URL tools**: `url-*` (6 scripts) **Other utilities**:
`dark-mode-toggle`, `select`, `whatismyip`, etc.

**Completion Strategy**: Lower priority for completion implementation

## Priority Completion Functions to Implement

### Priority 1: High-Impact Shared Functions

1. **`__fish_android_packages`** - List installed Android packages
   - **Impact**: 24 scripts
   - **Implementation**: `adb shell pm list packages -f | sed 's/.*=//'`
   - **Usage**: All `packagename-*` scripts + 4 `adb-*` scripts

2. **`__fish_apk_files`** - Complete APK/ZIP files
   - **Impact**: 15 scripts
   - **Implementation**: Fish built-in file completion with suffix filter
   - **Usage**: All `apk-*` scripts

3. **`__fish_android_services`** - List Android services
   - **Impact**: 3 scripts
   - **Implementation**:
     `adb shell service list | awk '{print $2}' | tr -d '[]:'`
   - **Usage**: `*-dumpsys-service`, `service-*` scripts

### Priority 2: Medium-Impact Functions

4. **`__fish_android_tile_components`** - Complete tile components
   - **Impact**: 1-2 scripts
   - **Implementation**: Parse packages for TileService declarations
   - **Complexity**: High - requires parsing package manifests
   - **Alternative**: Static list of common tile services

5. **`__fish_android_log_tags`** - Complete logcat tags
   - **Impact**: 1 script (`adb-logcat-tag`)
   - **Implementation**: Parse recent logcat for tag names
   - **Complexity**: Medium

### Priority 3: Script-Specific Completions

Scripts with unique needs:

- `apk-install-and-launch` - Needs `-f` flag + APK file completion
- `adb-setting-location-accuracy` - Needs accuracy mode completions
  (fine/coarse)
- File output scripts - Needs file path completion for `--output` flag

## Recommended Implementation Order

### Phase 1: Foundation (Week 1)

1. Create `fish/functions/__fish_android_packages.fish`
2. Create `fish/functions/__fish_android_services.fish`
3. Create completions for all 20 `packagename-*` scripts using shared function
4. Update `adb-dumpsys-service.fish` to use shared service function

### Phase 2: APK Scripts (Week 2)

5. Create completions for all 15 `apk-*` scripts with file filtering
6. Add `-f` flag completion to `apk-install-and-launch`

### Phase 3: Remaining ADB Scripts (Week 3)

7. Add completions for `adb-logcat-package`, `adb-exit-info`,
   `adb-jobscheduler`, `adb-not-optimized`
8. Add completions for scripts with file arguments (`adb-exec-and-wait`,
   screenshot/screenrecord)
9. Add completions for `adb-tile-add` and `adb-tile-show`

### Phase 4: Optional Enhancements

10. Add `-h/--help` completions to no-arg utility scripts
11. Consider completions for non-Android scripts based on usage patterns

## Completion Template Examples

### Example 1: Simple package name completion

```fish
# packagename-force-stop.fish
complete -c packagename-force-stop -f -a '(__fish_android_packages)' -d 'Package name'
complete -c packagename-force-stop -s h -l help -d 'Display help'
```

### Example 2: APK file completion

```fish
# apk-badging.fish
complete -c apk-badging -F -a '(__fish_complete_suffix .apk .zip)' -d 'APK or ZIP file'
complete -c apk-badging -s h -l help -d 'Display help'
```

### Example 3: Service name completion

```fish
# service-dumpsys.fish
complete -c service-dumpsys -f -a '(__fish_android_services)' -d 'Service name'
complete -c service-dumpsys -s h -l help -d 'Display help'
```

### Example 4: Script with flags

```fish
# apk-install-and-launch.fish
complete -c apk-install-and-launch -F -a '(__fish_complete_suffix .apk .zip)' -d 'APK or ZIP file'
complete -c apk-install-and-launch -s f -d 'Force uninstall before install'
complete -c apk-install-and-launch -s h -l help -d 'Display help'
```

## Estimated Impact

- **High priority completions**: 42 scripts (27%)
  - 24 package name scripts
  - 15 APK file scripts
  - 3 service scripts

- **Medium priority completions**: 15 scripts (10%)
  - Tile/component scripts
  - File output scripts
  - Special argument scripts

- **Low priority completions**: 34 scripts (22%)
  - No-argument utility scripts
  - Non-Android scripts with simple args

- **No completion needed**: 63 scripts (41%)
  - Pure utility scripts
  - Scripts better served by built-in file completion

## Testing Recommendations

After implementing completions:

1. **Functionality test**: Verify completions appear with `<TAB>`
2. **Dynamic test**: Verify package/service lists update when devices change
3. **Performance test**: Ensure completion functions execute quickly (<200ms)
4. **Error handling**: Test behavior when no device connected
5. **Documentation**: Update AGENTS.md with completion maintenance guidelines

## Notes on Performance

- Package and service listing requires active ADB connection
- Completion functions should cache results briefly to avoid repeated `adb`
  calls
- Consider adding timeout/error handling for when no device is connected
- The `emumanager.fish` completion provides a good model for helper functions

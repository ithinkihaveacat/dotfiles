# Command Index

<!-- markdownlint-disable MD013 -->

## Contents

- [Help](#help)
- [Environment Variables](#environment-variables)
- [Subcommands](#subcommands)
  - [bootstrap](#bootstrap)
  - [doctor](#doctor)
  - [list avd](#list-avd)
  - [list package](#list-package)
  - [info avd](#info-avd)
  - [create avd](#create-avd)
  - [start avd](#start-avd)
  - [stop avd](#stop-avd)
  - [delete avd](#delete-avd)
  - [download package](#download-package)
  - [catalog package](#catalog-package)
  - [update package](#update-package)
- [Device Types](#device-types)
- [Architecture Detection](#architecture-detection)

## Help

The block below is `scripts/emumanager --help`, kept in sync by
`command-index-sync` (coding-standards skill); do not edit it by hand. The
sections that follow add per-subcommand detail and raw commands. (The marker
pins `ANDROID_HOME` to its documented default so the generated output is
machine-independent.)

<!-- generated: env ANDROID_HOME=$HOME/.local/share/android-sdk ../scripts/emumanager --help -->

```text
Usage: emumanager [COMMAND]

A script to set up and manage the Android SDK, emulator, and system images.

Environment:
  ANDROID_HOME: $HOME/.local/share/android-sdk

Commands:
  bootstrap [--no-emulator]
                      Bootstrap SDK environment and patch tools.
  doctor              Run diagnostics to check for common issues.
  list <resource>     List local resources (avd, package).
  info avd <name>     Show detailed information about an AVD.
  create avd <name>   Create a new AVD.
  start avd <name>    Start an AVD.
  stop avd <name>     Stop a running AVD.
  delete avd <name>   Delete an AVD.
  download package <image>
                      Download a specific package.
  catalog package     List obtainable system images.
  update package      Update all installed SDK packages.

Options:
  --help              Display this help message and exit

Examples:
  # Create a mobile/phone AVD with the latest obtainable image
  emumanager create avd my_phone --mobile

  # Start the AVD
  emumanager start avd my_phone

  # List AVDs
  emumanager list avd

  # List package updates
  emumanager list package --outdated
```

<!-- /generated -->

## Environment Variables

| Variable                      | Default                          | Description                                     |
| ----------------------------- | -------------------------------- | ----------------------------------------------- |
| `ANDROID_HOME`                | `$HOME/.local/share/android-sdk` | Android SDK installation directory              |
| `ANDROID_USER_HOME`           | `$HOME/.android`                 | User-specific Android files (AVDs, preferences) |
| `ANDROID_BUILD_TOOLS_VERSION` | `36.0.0`                         | Build-tools version to install                  |
| `ANDROID_PLATFORM_VERSION`    | `android-36`                     | Platform version to install                     |

## Subcommands

### bootstrap

**Purpose**: Set up the Android SDK environment with essential components.

**Synopsis**: `scripts/emumanager bootstrap [--no-emulator]`

**Options**:

- `--no-emulator`: Skip installing the emulator component

**What it installs**:

1. cmdline-tools (sdkmanager, avdmanager)
1. platform-tools (adb)
1. build-tools (specified version)
1. platforms (specified Android version)
1. emulator (unless `--no-emulator`)

**Raw Commands**:

```bash
# Download and install cmdline-tools manually
curl -fL "https://dl.google.com/android/repository/commandlinetools-linux-XXXXX.zip" \
  -o commandlinetools.zip
unzip commandlinetools.zip
mkdir -p "$ANDROID_HOME/cmdline-tools/latest"
mv cmdline-tools/* "$ANDROID_HOME/cmdline-tools/latest/"

# Install components
SDKMANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
yes | "$SDKMANAGER" --licenses
"$SDKMANAGER" --install "platform-tools"
"$SDKMANAGER" --install "emulator"
"$SDKMANAGER" --install "build-tools;36.0.0"
"$SDKMANAGER" --install "platforms;android-36"
```

**Exit Codes**: 0 on success, non-zero on failure

______________________________________________________________________

### doctor

**Purpose**: Run diagnostics to check for common issues.

**Synopsis**: `scripts/emumanager doctor`

**Checks performed**:

- Running emulator processes
- Orphaned crashpad_handler processes
- Disk space at ANDROID_HOME
- Orphaned/mismatched AVD files
- Java environment (version 17+ required)
- Hardware acceleration (KVM on Linux, HVF on macOS)
- SDK tools installation (sdkmanager, adb, emulator)

**Exit Codes**: 0 if no errors, 1 if errors found

______________________________________________________________________

### list avd

**Purpose**: List locally created AVDs with running status.

**Synopsis**:
`scripts/emumanager list avd [--names-only|--running-only|--stopped-only]`

**Options**:

- `--names-only`: Output only AVD names (no status)
- `--running-only`: Show only running AVDs
- `--stopped-only`: Show only stopped AVDs

**Examples**:

```bash
scripts/emumanager list avd
# my_phone (emulator-5554)
# my_watch

scripts/emumanager list avd --names-only
# my_phone
# my_watch
```

**Raw Commands**:

```bash
# List AVD names
"$ANDROID_HOME/emulator/emulator" -list-avds

# Get running AVD name for a specific emulator
"$ANDROID_HOME/platform-tools/adb" -s emulator-5554 shell getprop ro.boot.qemu.avd_name
```

______________________________________________________________________

### list package

**Purpose**: List installed SDK packages, or packages with available updates.

**Synopsis**: `scripts/emumanager list package [--outdated]`

**Options**:

- `--outdated`: List only installed packages that have updates available in the
  remote registry.

**Examples**:

```bash
# List all installed packages
scripts/emumanager list package

# List only packages with updates
scripts/emumanager list package --outdated
```

**Raw Commands**:

```bash
# List installed packages
"$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --list_installed

# List packages with updates (manually parsed from --list)
"$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --list | grep -A 1000 "Available Updates:"
```

______________________________________________________________________

### info avd

**Purpose**: Show detailed information about an AVD.

**Synopsis**: `scripts/emumanager info avd <name>`

**Arguments**:

- `<name>`: AVD name (required)

**Output includes**:

- Display name and status (running/stopped)
- System image package, API level, tag, architecture
- Device profile, screen dimensions, density
- RAM, storage, SD card size
- Play Store enabled status
- AVD path

**Raw Commands**:

```bash
# Read AVD configuration
cat "$ANDROID_USER_HOME/avd/my_phone.ini"
cat "$ANDROID_USER_HOME/avd/my_phone.avd/config.ini"
```

______________________________________________________________________

### create avd

**Purpose**: Create a new AVD with device type or specific image.

**Synopsis**: `scripts/emumanager create avd <name> [options] [image]`

**Arguments**:

- `<name>`: AVD name (required)
- `[image]`: Specific system image package (optional)

**Options**:

- `--mobile`, `--phone`: Create mobile/phone device (default)
- `--wear`, `--watch`: Create Wear OS device
- `--tv`: Create Android/Google TV device
- `--auto`: Create Android Automotive device

**Examples**:

```bash
# Create with device type (auto-selects latest image)
scripts/emumanager create avd my_phone --mobile
scripts/emumanager create avd my_watch --wear

# Create with specific image
scripts/emumanager create avd my_avd "system-images;android-36;google_apis_playstore;arm64-v8a"
```

**Raw Commands**:

```bash
# Install system image if needed
"$SDKMANAGER" --install "system-images;android-36;google_apis_playstore;arm64-v8a"

# Create AVD (mobile device)
echo "no" | "$AVDMANAGER" create avd \
  -n my_phone \
  -k "system-images;android-36;google_apis_playstore;arm64-v8a" \
  -d medium_phone

# Create AVD (Wear OS device)
echo "no" | "$AVDMANAGER" create avd \
  -n my_watch \
  -k "system-images;android-36;android-wear;arm64-v8a" \
  -d wearos_large_round
```

**Exit Codes**: 0 on success, non-zero if AVD creation fails

______________________________________________________________________

### start avd

**Purpose**: Start an AVD and wait for boot to complete.

**Synopsis**: `scripts/emumanager start avd <name> [--cold-boot|--wipe-data]`

**Arguments**:

- `<name>`: AVD name (required)

**Options**:

- `--cold-boot`: Bypass Quick Boot snapshots, perform cold boot
- `--wipe-data`: Factory reset (wipe all data) and cold boot

**Examples**:

```bash
scripts/emumanager start avd my_phone              # Quick Boot
scripts/emumanager start avd my_phone --cold-boot  # Cold boot
scripts/emumanager start avd my_phone --wipe-data  # Factory reset
```

**Raw Commands**:

```bash
# Start emulator (Quick Boot)
"$EMULATOR" -avd my_phone -port 5554 &

# Start emulator (Cold Boot)
"$EMULATOR" -avd my_phone -port 5554 -no-snapshot-load &

# Start emulator (Wipe Data)
"$EMULATOR" -avd my_phone -port 5554 -no-snapshot-load -wipe-data &

# Wait for device
"$ADB" -s emulator-5554 wait-for-device

# Wait for boot completion
while [ "$("$ADB" -s emulator-5554 shell getprop init.svc.bootanim | tr -d '\r')" != "stopped" ]; do
  sleep 1
done
```

**Exit Codes**: 0 on success, non-zero on timeout or failure

______________________________________________________________________

### stop avd

**Purpose**: Stop a running AVD.

**Synopsis**: `scripts/emumanager stop avd <name>`

**Arguments**:

- `<name>`: AVD name (required)

**Raw Commands**:

```bash
# Find emulator serial by AVD name
for serial in $(adb devices | grep emulator- | awk '{print $1}'); do
  avd_name=$(adb -s "$serial" shell getprop ro.boot.qemu.avd_name | tr -d '[:space:]')
  if [ "$avd_name" = "my_phone" ]; then
    adb -s "$serial" emu kill
    break
  fi
done
```

______________________________________________________________________

### delete avd

**Purpose**: Delete an AVD and clean up files.

**Synopsis**: `scripts/emumanager delete avd <name>`

**Arguments**:

- `<name>`: AVD name (required)

**Behavior**:

- Stops the AVD if running
- Deletes AVD registration
- Cleans up orphaned .avd directory and .ini file

**Raw Commands**:

```bash
# Stop if running (see stop command)

# Delete AVD
"$AVDMANAGER" delete avd -n my_phone

# Clean up orphaned files if needed
rm -rf "$ANDROID_USER_HOME/avd/my_phone.avd"
rm -f "$ANDROID_USER_HOME/avd/my_phone.ini"
```

______________________________________________________________________

### download package

**Purpose**: Download a specific system image or SDK package.

**Synopsis**: `scripts/emumanager download package <image>`

**Arguments**:

- `<image>`: Package name (required)

**Example**:

```bash
scripts/emumanager download package "system-images;android-36;google_apis_playstore;arm64-v8a"
```

**Raw Commands**:

```bash
yes | "$SDKMANAGER" --licenses
"$SDKMANAGER" --install "system-images;android-36;google_apis_playstore;arm64-v8a"
```

______________________________________________________________________

### catalog package

**Purpose**: List obtainable system images (packages) for the host architecture
(API >= 33) from the remote registry.

**Synopsis**: `scripts/emumanager catalog package`

**Output**: Package names prefixed with `*` if installed.

**Raw Commands**:

```bash
# List all obtainable system images
"$SDKMANAGER" --list | grep "system-images;android-"

# List installed packages
"$SDKMANAGER" --list_installed
```

______________________________________________________________________

### update package

**Purpose**: Update all installed SDK packages to latest versions.

**Synopsis**: `scripts/emumanager update package`

**Raw Commands**:

```bash
yes | "$SDKMANAGER" --licenses
"$SDKMANAGER" --update
```

## Device Types

| Type         | Flags                 | System Image Tags                                    | Device Definition    |
| ------------ | --------------------- | ---------------------------------------------------- | -------------------- |
| Mobile/Phone | `--mobile`, `--phone` | `google_apis_playstore`, `google_apis`               | `medium_phone`       |
| Wear OS      | `--wear`, `--watch`   | `android-wear-signed`, `android-wear`                | `wearos_large_round` |
| TV           | `--tv`                | `google-tv`, `android-tv`                            | (default)            |
| Automotive   | `--auto`              | `android-automotive-playstore`, `android-automotive` | (default)            |

The script automatically selects the latest obtainable image for the device type
and host architecture. Preferred variants (e.g., `google_apis_playstore` over
`google_apis`) are selected when obtainable.

## Architecture Detection

The script maps host architecture to Android architecture:

| Host               | Android Architecture |
| ------------------ | -------------------- |
| `arm64`, `aarch64` | `arm64-v8a`          |
| `x86_64`           | `x8664`              |

System images are filtered to match the host architecture.

<!-- markdownlint-restore MD013 -->

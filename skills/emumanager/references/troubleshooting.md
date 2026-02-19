# Troubleshooting

## Contents

- [Java Issues](#java-issues)
- [Hardware Acceleration](#hardware-acceleration)
- [SDK Tools Not Found](#sdk-tools-not-found)
- [System Image Issues](#system-image-issues)
- [Emulator Startup Issues](#emulator-startup-issues)
- [AVD Management Issues](#avd-management-issues)
- [Disk Space Issues](#disk-space-issues)
- [Network Issues](#network-issues)
- [Multiple Emulators](#multiple-emulators)

## Java Issues

### Missing Java

**Symptom**: "Java executable not found" or sdkmanager fails to run.

**Solution**:

```bash
# Check if Java is installed
java -version

# Install Java 17+ (Debian/Ubuntu)
sudo apt install openjdk-17-jdk

# Install Java 17+ (macOS with Homebrew)
brew install openjdk@17
```

Set `JAVA_HOME` if needed:

```bash
export JAVA_HOME="/path/to/java"
```

### Wrong Java Version

**Symptom**: "Java version is too old" error from `emumanager doctor`.

**Diagnosis**:

```bash
java -version
# Must show version 17 or higher
```

**Solution**: Install Java 17+ and ensure it's in your PATH or set `JAVA_HOME`.

The SDK tools require Java 17 or higher. Common sources of older Java:
- System default Java on older Linux distributions
- JAVA_HOME pointing to an old installation

## Hardware Acceleration

### KVM Not Available (Linux)

**Symptom**: "KVM not found at /dev/kvm" or emulator runs very slowly.

**Diagnosis**:

```bash
# Check if KVM module is loaded
lsmod | grep kvm

# Check if virtualization is supported
grep -E 'vmx|svm' /proc/cpuinfo
```

**Solution**:

1. Enable virtualization in BIOS (Intel VT-x or AMD-V)
2. Load KVM module:

```bash
sudo modprobe kvm
sudo modprobe kvm_intel  # or kvm_amd
```

### User Not in kvm Group (Linux)

**Symptom**: "User is not in the 'kvm' group" warning.

**Solution**:

```bash
sudo usermod -aG kvm $USER
# Log out and log back in for changes to take effect
```

Verify:

```bash
groups | grep kvm
```

### HVF Not Available (macOS)

**Symptom**: "Hypervisor Framework (HVF) is not enabled" error.

**Diagnosis**:

```bash
sysctl kern.hv.supported
# Should return: kern.hv.supported: 1
```

**Solution**: HVF requires macOS 10.10 (Yosemite) or later. On Apple Silicon
Macs, it should be available by default. Ensure your macOS is up to date.

## SDK Tools Not Found

### sdkmanager Not Found

**Symptom**: "'sdkmanager' not found in ANDROID_HOME"

**Solution**:

```bash
scripts/emumanager bootstrap
```

Or manually download cmdline-tools from:
https://developer.android.com/studio#command-line-tools-only

### adb Not Found

**Symptom**: "'adb' not found in ANDROID_HOME"

**Solution**:

```bash
scripts/emumanager bootstrap
```

Or install manually:

```bash
"$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --install "platform-tools"
```

### emulator Not Found

**Symptom**: "'emulator' not found in ANDROID_HOME"

**Solution**:

```bash
scripts/emumanager bootstrap
```

Or install manually:

```bash
"$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --install "emulator"
```

## System Image Issues

### System Image Not Installed

**Symptom**: "System image 'X' not found" when starting AVD.

**Solution**:

```bash
# Download the required image
scripts/emumanager download "system-images;android-36;google_apis_playstore;arm64-v8a"

# Or list available images and choose one
scripts/emumanager images
```

### No Suitable Image Found

**Symptom**: "No suitable mobile/wear/tv/auto image found for architecture X"

**Causes**:
- No images available for your host architecture
- Network issues preventing image list retrieval
- All available images are blocklisted

**Solution**:

```bash
# List all available images
scripts/emumanager images

# Download a specific image
scripts/emumanager download "system-images;android-35;google_apis_playstore;arm64-v8a"
```

## Emulator Startup Issues

### Emulator Connection Timeout

**Symptom**: "Timeout waiting for device to connect"

**Diagnosis**:

```bash
# Check if emulator process is running
pgrep -f 'qemu-system.*-avd'

# Check for emulator output
# (script shows debug command when this happens)
"$ANDROID_HOME/emulator/emulator" -avd my_phone -verbose -show-kernel -no-audio
```

**Common causes**:
- Hardware acceleration not working
- Insufficient RAM or CPU resources
- Corrupted AVD state

**Solutions**:
1. Try cold boot: `scripts/emumanager start my_phone --cold-boot`
2. Try factory reset: `scripts/emumanager start my_phone --wipe-data`
3. Delete and recreate AVD: `scripts/emumanager delete my_phone`

### AVD Already Running

**Symptom**: "AVD 'X' is already running"

This is informational, not an error. The AVD is already started.

To connect: `adb devices` will show the running emulator.

### No Available Emulator Ports

**Symptom**: "No available emulator ports (5554-5584)"

**Cause**: Too many emulators running (max 16 concurrent emulators).

**Solution**:

```bash
# List running emulators
adb devices

# Stop some emulators
scripts/emumanager stop <avd_name>
```

## AVD Management Issues

### AVD Does Not Exist

**Symptom**: "AVD 'X' does not exist"

**Diagnosis**:

```bash
scripts/emumanager list
```

**Solution**: Create the AVD first:

```bash
scripts/emumanager create my_phone --mobile
```

### Orphaned AVD Files

**Symptom**: `emumanager doctor` reports orphaned .ini files or .avd directories.

**Cause**: AVD was partially deleted or corrupted.

**Solution**:

```bash
# The delete command cleans up orphaned files
scripts/emumanager delete <orphan_name>
```

Or manually:

```bash
rm -rf "$ANDROID_USER_HOME/avd/<name>.avd"
rm -f "$ANDROID_USER_HOME/avd/<name>.ini"
```

### Failed to Delete AVD

**Symptom**: AVD deletion fails or takes multiple attempts.

**Cause**: AVD may still be running or files are locked.

**Solution**:

```bash
# Ensure AVD is stopped
scripts/emumanager stop my_phone

# Wait a moment, then delete
sleep 2
scripts/emumanager delete my_phone
```

## Disk Space Issues

### Low Disk Space Warning

**Symptom**: "Low disk space: X available at ANDROID_HOME"

**Cause**: Less than 5GB available. AVD images can be several GB each.

**Solutions**:
1. Remove unused AVDs: `scripts/emumanager delete <name>`
2. Remove unused system images via sdkmanager
3. Move ANDROID_HOME to a larger disk

Check space usage:

```bash
du -sh "$ANDROID_HOME"/*
du -sh "$ANDROID_USER_HOME/avd"/*
```

### System Image Download Fails

Large system images (2-4GB) may fail to download on slow connections.

**Solution**: Retry or increase timeout:

```bash
# Manual download with sdkmanager (no built-in timeout)
"$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" \
  --install "system-images;android-36;google_apis_playstore;arm64-v8a"
```

## Network Issues

### Failed to Fetch Repository Metadata

**Symptom**: "Failed to fetch repository metadata" during bootstrap.

**Cause**: Network connectivity issues or firewall blocking Google servers.

**Solution**:
1. Check internet connectivity
2. Check proxy settings
3. Try manual download from:
   https://developer.android.com/studio#command-line-tools-only

### Package Installation Timeout

**Symptom**: Package installation times out after 300 seconds.

**Cause**: Slow network connection or large package size.

**Solution**: Run sdkmanager directly without timeout:

```bash
"$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --install "emulator"
```

## Multiple Emulators

### Commands Affect Wrong Emulator

**Symptom**: ADB commands go to a different emulator than intended.

**Cause**: Multiple emulators running without explicit device selection.

**Solution**: Set `ANDROID_SERIAL` environment variable:

```bash
# List running emulators
adb devices
# emulator-5554   device
# emulator-5556   device

# Target specific emulator
export ANDROID_SERIAL=emulator-5554
adb shell ...

# Or use -s flag
adb -s emulator-5554 shell ...
```

### Finding Which AVD Is Running on Which Port

```bash
# The list command shows serial numbers
scripts/emumanager list
# my_phone (emulator-5554)
# my_watch (emulator-5556)

# Or manually query each emulator
for serial in $(adb devices | grep emulator- | awk '{print $1}'); do
  avd=$(adb -s "$serial" shell getprop ro.boot.qemu.avd_name | tr -d '[:space:]')
  echo "$serial: $avd"
done
```

### Orphaned Crashpad Handler Processes

**Symptom**: `emumanager doctor` reports orphaned crashpad_handler processes.

**Cause**: Crash reporters left behind from previous emulator sessions.

**Solution**:

```bash
pkill -f 'android-sdk/emulator/crashpad_handler'
```

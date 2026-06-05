# Android Development

This document provides high-level context for Android development tools. For
authoritative documentation on specific capabilities, refer to the following
Agent Skills:

- **`jetpack`**: For working with AndroidX libraries (source code inspection,
  version resolution).
- **`adb`**: For device manipulation, package management, and Wear OS debugging.

## Emulator Management (`emumanager`)

The `emumanager` script is a powerful tool for bootstrapping an Android SDK
environment and managing Android Virtual Devices (AVDs). It is useful for
spinning up an emulator to diagnose a problem, verify a bug, or test a fix in a
clean environment.

- `emumanager create avd <name>`: Creates a new AVD.
- `emumanager start avd <name>`: Starts the specified AVD.
- `emumanager list avd`: Lists all existing AVDs.

```bash
# Create and start a new emulator for testing
emumanager create avd test-avd
emumanager start avd test-avd
```

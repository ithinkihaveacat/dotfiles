# AGENTS.md

This document provides general rules and requirements for agents when making
changes to codebases.

## Markdown Formatting

All Markdown files, whether new or updated, _must_ be formatted by `prettier`.
There is a `.prettierrc` file in the root directory that applies the formatting
rules.

To format Markdown files, use the command `prettier --write <file(s)>`. This
command will edit files in place.

If `prettier` is not installed globally, you can run it via
`npx -y prettier @latest --write <file(s)>`. If `npx` is not available, you can
skip the prettier step.

## Shell Script Linting

All shell scripts, whether new or updated, should be passed through `shellcheck`
for linting. Any errors or warnings should be eliminated, or explicitly ignored
if absolutely necessary.

## Jetpack Library Source Code

When analyzing or modifying code that uses Android Jetpack libraries (libraries
with package names starting with `androidx.*`), it is highly recommended to
consult the library's source code. This is important because you will often be
interacting with the latest version of the library, and understanding its
implementation is key.

The `context-jetpack` tool can be used to download the source code for Jetpack
libraries.

### Using `context-jetpack`

You can use the tool to download the source for a specific library. The version
defaults to STABLE if not specified:

```bash
context-jetpack androidx.wear.tiles:tiles
context-jetpack androidx.wear.tiles:tiles ALPHA
context-jetpack androidx.wear.tiles:tiles BETA
context-jetpack androidx.wear.tiles:tiles RC
```

This will download the source code to a temporary directory and print the path.

### If `context-jetpack` is not installed

If the `context-jetpack` command is not available, you can download the script
and use it locally:

```bash
curl -sSL https://raw.githubusercontent.com/ithinkihaveacat/dotfiles/refs/heads/master/bin/context-jetpack -o context-jetpack
chmod +x context-jetpack
./context-jetpack androidx.wear.tiles:tiles
```

Alternatively, you can inspect the script's contents to understand how to
download the source code manually.

## Android Device Interaction (ADB, APK, Package, Wear OS)

A comprehensive suite of shell scripts designed to streamline interactions with
Android devices, emulators, and APK files may be installed on the device (i.e.,
somewhere in the PATH). These scripts leverage `adb` (Android Debug Bridge) and
other Android-related tools to perform a wide range of tasks, from basic device
information retrieval to advanced Wear OS service manipulation.

Agents should investigate these scripts when tasked with:

- Manipulating a physical Android device or emulator.
- Analyzing APK files.
- Interacting with specific Android packages.
- Developing for or debugging Wear OS devices.

Many of these scripts provide detailed usage information via the `--help`
argument (e.g., `adb-screenshot --help`). You can also inspect their source code
directly for implementation details.

If these scripts are not available in the current environment's PATH, they can
be downloaded individually from the
[dotfiles repository's `bin` directory](https://github.com/ithinkihaveacat/dotfiles/tree/master/bin).

### Key Script Categories and Examples:

**1. General ADB Utilities (`adb-*`)** These scripts wrap common `adb` commands,
often adding convenience features or simplifying complex operations.

- `adb-screenshot`: Takes a screenshot of the connected device and saves it.
  ```bash
  adb-screenshot my_screenshot.png
  ```
- `adb-logcat-package <PACKAGE_NAME>`: Filters `logcat` output for a specific
  package.
- `adb-settings-theme`: Toggles the device's theme (light/dark).
- **Wear OS Tile Management:** A common task is testing a new tile. This is a
  two-step process:
  1.  **Add the tile:** Use `adb-tile-add <COMPONENT_NAME>` to make the system
      aware of your tile. This command will output the index of the newly added
      tile.
  2.  **Show the tile:** Use `adb-tile-show <TILE_INDEX>` with the index from
      the previous step to make the tile visible on the device for debugging.

  This workflow (`adb-tile-add` followed by `adb-tile-show`) is the standard
  procedure for testing tiles from the command line.

**2. APK Analysis and Manipulation (`apk-*`)** Scripts for inspecting and
interacting with Android Package Kits.

- `apk-badging <APK_FILE>`: Extracts and displays the human-readable "badging"
  information from an APK, including application name, launcher activities, and
  permissions.
- `apk-cat-manifest <APK_FILE>`: Dumps the `AndroidManifest.xml` in a readable
  format.
- `apk-decode <APK_FILE>`: Decodes an APK using `apktool`, extracting resources
  and source code (smali).
- `apk-tiles <APK_FILE>`: Lists Wear OS Tiles declared within an APK.

**3. Package-Specific Operations (`packagename-*`)** These scripts perform
actions on a specific installed Android package.

- `packagename-force-stop <PACKAGE_NAME>`: Forces a package to stop.
- `packagename-clear-cache <PACKAGE_NAME>`: Clears the cache for a given
  package.
- `packagename-permissions <PACKAGE_NAME>`: Lists permissions for a package.
- `packagename-tiles <PACKAGE_NAME>`: Lists active Wear OS Tiles for an
  installed package.

**4. Wear OS Service Interaction (`wearableservice-*`)** A specialized set of
tools for interacting with the Wear OS data layer and services. These are
invaluable for debugging Wear OS applications.

- `wearableservice-capabilities`: Lists all advertised capabilities on connected
  Wear OS nodes.
- `wearableservice-nodes`: Lists all connected Wear OS nodes (devices).
- `wearableservice-items`: Lists data items on the Wear OS data layer.
- `wearableservice-rpcs`: Provides utilities for interacting with RPCs (Remote
  Procedure Calls) over the Wear OS data layer.

This suite of scripts significantly simplifies common and complex Android
development and debugging tasks, especially for Wear OS.

## Git Commit Messages

When generating git commit messages, use the following structure (hard-wrap all
body text at 80 characters):

- Subject line (imperative mood) of <=50 characters. Do add "feat" or "bug" to
  the subject line.
- Blank line.
- One of more paragraphs explaining what changed and why. Point form is
  acceptable.

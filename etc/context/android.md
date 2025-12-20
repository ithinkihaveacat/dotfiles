# Android Development

## Jetpack Library Source Code

When analyzing or modifying code that uses Android Jetpack libraries (libraries
with package names starting with `androidx.*`), it is highly recommended to
consult the library's source code. This is important because you will often be
interacting with the latest version of the library, and understanding its
implementation is key.

### Using `jetpack-inspect`

The `jetpack-inspect` command is the most convenient way to quickly access
Jetpack source code. It takes a fully qualified class or package name and
automatically downloads the corresponding source code.

#### Basic Usage

```bash
# Inspect a specific class
jetpack-inspect androidx.core.splashscreen.SplashScreen

# Inspect with different version types
jetpack-inspect androidx.wear.ambient.AmbientLifecycleObserver ALPHA
jetpack-inspect androidx.lifecycle.ViewModel BETA
jetpack-inspect androidx.wear.tiles.TileService STABLE
jetpack-inspect androidx.glance.wear.tiles.GlanceTileService SNAPSHOT
```

The command prints the path to a directory containing the extracted source code.
You can then navigate to that directory to explore the implementation:

```bash
# Navigate directly to the source
cd "$(jetpack-inspect androidx.wear.tiles.TileService)"

# Or use pushd to keep your current directory on the stack
pushd "$(jetpack-inspect androidx.wear.tiles.TileService)"
# ... explore source code ...
popd
```

#### Using SNAPSHOT Versions

**About SNAPSHOT builds:** These are bleeding-edge versions of Jetpack
libraries. In these scripts, 'SNAPSHOT' always refers to the **latest**
available build from [androidx.dev](https://androidx.dev/). Selecting a specific
build ID is not supported. Use this when you need the absolute latest,
unreleased code.

**When to use SNAPSHOT:**

- You're working with a library that is in active development and only available
  as a snapshot
- You need the absolute latest changes that haven't been released yet (even
  alpha/beta)
- You're testing against cutting-edge features or bug fixes

**Important:** By default, `jetpack-inspect` resolves against stable/release
repositories. If you need a snapshot version, you **must** explicitly specify
the `SNAPSHOT` version type, or the command may fail or find an older version.

**Example:**

```bash
# This may fail if the library is only available as a snapshot
jetpack-inspect androidx.compose.remote:remote-creation-compose

# Correct: explicitly request SNAPSHOT version
jetpack-inspect androidx.compose.remote:remote-creation-compose SNAPSHOT
```

#### Practical Examples

**Example 1: Understanding a class implementation**

```bash
# You're working with SplashScreen and want to understand how it works
cd "$(jetpack-inspect androidx.core.splashscreen.SplashScreen)"
ls  # See the source structure
grep -r "installSplashScreen" .  # Find specific methods
```

**Example 2: Checking the latest alpha version**

```bash
# You want to see what's coming in the next release
jetpack-inspect androidx.wear.tiles.TileService ALPHA
```

**Example 3: Working with snapshot versions**

```bash
# You need the absolute latest unreleased code
jetpack-inspect androidx.glance:glance-wear-tiles SNAPSHOT
cd "$(jetpack-inspect androidx.glance:glance-wear-tiles SNAPSHOT)"
# Explore the bleeding-edge implementation
```

**Example 4: Comparing implementations**

```bash
# Download multiple versions to compare
STABLE_DIR=$(jetpack-inspect androidx.lifecycle.ViewModel STABLE)
ALPHA_DIR=$(jetpack-inspect androidx.lifecycle.ViewModel ALPHA)
diff -r "$STABLE_DIR" "$ALPHA_DIR"
```

### Related Tools

The `jetpack-inspect` command is built on top of several other tools that you
can use independently:

- **`jetpack-resolve`**: Converts a class name to a Maven coordinate
  ```bash
  jetpack-resolve androidx.core.splashscreen.SplashScreen
  # Output: androidx.core:core-splashscreen
  ```
- **`jetpack-source`**: Downloads source code using Maven coordinates
  ```bash
  jetpack-source androidx.wear.tiles:tiles
  jetpack-source androidx.wear.tiles:tiles ALPHA
  jetpack-source androidx.wear.tiles:tiles SNAPSHOT
  ```
- **`jetpack-version`**: Gets version information for a package
  ```bash
  jetpack-version androidx.wear.tiles:tiles STABLE
  jetpack-version androidx.wear.tiles:tiles ALPHA
  jetpack-version androidx.wear.tiles:tiles SNAPSHOT
  ```

All of these tools support the `SNAPSHOT` version type for accessing
bleeding-edge builds from androidx.dev.

### Installation

#### Option 1: Add bin directory to PATH (Recommended)

Clone the dotfiles repository and add the bin directory to your PATH:

```bash
# Clone the repository
git clone https://github.com/ithinkihaveacat/dotfiles.git

# Add to your current shell session
export PATH="/path/to/dotfiles/bin:$PATH"

# Add to your shell profile for persistence (~/.bashrc, ~/.zshrc, etc.)
echo 'export PATH="/path/to/dotfiles/bin:$PATH"' >> ~/.bashrc
```

After adding to PATH, verify installation:

```bash
jetpack-inspect --help
```

#### Option 2: Download individual scripts

If the tools are not in your PATH, you can download them individually. Note that
`jetpack-inspect` requires several dependencies:

**Download all required scripts:**

```bash
# Create a local bin directory
mkdir -p ~/bin

# Download all jetpack tools
for script in jetpack-inspect jetpack-resolve jetpack-source jetpack-version; do
  curl -sSL "https://raw.githubusercontent.com/ithinkihaveacat/dotfiles/refs/heads/master/bin/$script" \
    -o ~/bin/"$script"
  chmod +x ~/bin/"$script"
done

# Add to PATH for current session
export PATH="$HOME/bin:$PATH"
```

**System dependencies:**

These tools require the following system utilities:

- `curl` - for downloading files
- `xmllint` - for parsing Maven metadata (usually in `libxml2-utils` package)
- `jar` - for extracting source JARs (part of JDK)

Install on Debian/Ubuntu:

```bash
sudo apt-get install curl libxml2-utils default-jdk-headless
```

#### Option 3: Use without installation

Some scripts can be used directly without installation:

```bash
# Example: Check the latest stable version of a package
bash <(curl -sSL https://raw.githubusercontent.com/ithinkihaveacat/dotfiles/refs/heads/master/bin/jetpack-version) \
  androidx.wear.tiles:tiles STABLE
```

Note: This approach won't work for `jetpack-inspect` because it depends on other
scripts (`jetpack-resolve` and `jetpack-source`) that also need to be available.
Use Option 2 to download all dependencies.

### Troubleshooting

**"Command not found" errors:**

If you see errors like `jetpack-resolve: command not found` when running
`jetpack-inspect`, ensure all scripts are in your PATH:

```bash
# Check if scripts are accessible
which jetpack-inspect jetpack-resolve jetpack-source jetpack-version
```

**"xmllint: command not found":**

Install the libxml2-utils package:

```bash
sudo apt-get install libxml2-utils
```

**"jar: command not found":**

Install a JDK:

```bash
sudo apt-get install default-jdk-headless
```

## Device Interaction (ADB, APK, Package, Wear OS)

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

**5. Emulator Management (`emumanager`)** The `emumanager` script is a powerful
tool for bootstrapping an Android SDK environment and managing Android Virtual
Devices (AVDs). It can be particularly useful for spinning up an emulator to
diagnose a problem, verify a bug, or test a fix in a clean environment.

- `emumanager create <name>`: Creates a new Wear OS AVD.
- `emumanager start <name>`: Starts the specified AVD.
- `emumanager list`: Lists all available AVDs.

  ```bash
  # Create and start a new emulator for testing
  emumanager create test-avd
  emumanager start test-avd
  ```

This suite of scripts significantly simplifies common and complex Android
development and debugging tasks, especially for Wear OS.

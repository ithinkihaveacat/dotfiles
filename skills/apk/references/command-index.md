# Command Index

<!-- markdownlint-disable MD013 -->

## Contents

- [apk-cat-file](#apk-cat-file)
- [apk-cat-launcher](#apk-cat-launcher)
- [apk-cat-manifest](#apk-cat-manifest)
- [apk-complications](#apk-complications)
- [apk-decode](#apk-decode)
- [apk-install-and-launch](#apk-install-and-launch)
- [apk-launch](#apk-launch)
- [apk-launcher-icon-extract](#apk-launcher-icon-extract)
- [apk-packagename](#apk-packagename)
- [apk-tiles](#apk-tiles)
- [apk-unzip](#apk-unzip)
- [apk-version-code](#apk-version-code)
- [apk-version-name](#apk-version-name)
- [apk-version-wear-compose](#apk-version-wear-compose)
- [apk-version-whs](#apk-version-whs)

## apk-cat-file

<!-- generated: ../scripts/apk-cat-file --help -->

```text
Usage: apk-cat-file APK_FILE FILE_PATH

Extracts and displays a file from an Android APK or app bundle.

The script supports both standalone APKs and ZIP archives containing split APKs.
It automatically formats XML files for readability.

Arguments:
  APK_FILE    Path to an APK file or ZIP archive.
  FILE_PATH   Path to the file within the APK to extract.

Options:
  --help  Display this help message and exit

Examples:
  # Extract AndroidManifest.xml from an APK
  apk-cat-file app.apk AndroidManifest.xml

  # Extract a layout file from an APK
  apk-cat-file app.apk res/layout/activity_main.xml

  # Extract classes.dex from a ZIP archive
  apk-cat-file app-bundle.zip classes.dex
```

<!-- /generated -->

## apk-cat-launcher

<!-- generated: ../scripts/apk-cat-launcher --help -->

```text
Usage: apk-cat-launcher APK_FILE

Extracts and displays the launcher icon file from an APK.

This script reads the 'application-icon' attribute from the APK's manifest
and then extracts that file's content.

Arguments:
  APK_FILE    Path to an APK file or a ZIP archive containing a base split APK.

Options:
  --help      Display this help message and exit

Examples:
  # Display the launcher icon file from an APK
  apk-cat-launcher /path/to/your/app.apk

  # Can also be used with ZIP archives
  apk-cat-launcher /path/to/your/app.zip
```

<!-- /generated -->

## apk-cat-manifest

<!-- generated: ../scripts/apk-cat-manifest --help -->

```text
Usage: apk-cat-manifest APK_FILE

Displays the AndroidManifest.xml from an APK in a formatted way.

The script supports both standalone APK files and ZIP archives containing a base split APK.

Arguments:
  APK_FILE    Path to an APK or a ZIP file containing a base split APK.

Options:
  --help      Display this help message and exit

Examples:
  # Display the manifest from a standalone APK
  apk-cat-manifest /path/to/your/app.apk

  # Display the manifest from a ZIP archive
  apk-cat-manifest /path/to/your/app.zip
```

<!-- /generated -->

## apk-complications

<!-- generated: ../scripts/apk-complications --help -->

```text
Usage: apk-complications APK_FILE

Lists complication services from the AndroidManifest.xml of a given APK.

This script extracts the manifest and uses XPath to find services that handle
the 'android.support.wearable.complications.ACTION_COMPLICATION_UPDATE_REQUEST'
action.

Arguments:
  APK_FILE    Path to an APK file or a ZIP archive containing a base split APK.

Options:
  --help      Display this help message and exit

Examples:
  # List complication services from a standalone APK
  apk-complications /path/to/your/app.apk

  # List complication services from a ZIP archive
  apk-complications /path/to/your/app.zip
```

<!-- /generated -->

## apk-decode

<!-- generated: ../scripts/apk-decode --help -->

```text
Usage: apk-decode [OPTIONS] APK_FILE

Decodes an APK file using apktool and outputs the directory path.

This script uses 'apktool d' to decode the APK's resources.
The path to the output directory is printed to standard output.

Arguments:
  APK_FILE          Path to an APK file.

Options:
  -o, --output DIR  The directory to decode the APK into.
                    (defaults to a new temporary directory)
  --help            Display this help message and exit

Examples:
  # Decode an APK into a new temporary directory
  DECODED_PATH=$(apk-decode /path/to/your/app.apk)
  ls "$DECODED_PATH"

  # Decode an APK into a specific directory
  apk-decode --output /tmp/decoded-apk /path/to/your/app.apk
```

<!-- /generated -->

## apk-install-and-launch

<!-- generated: ../scripts/apk-install-and-launch --help -->

```text
Usage: apk-install-and-launch [OPTIONS] APK_FILE

Installs and launches an Android application from an APK or ZIP archive.

The script can handle single APK files or ZIP archives containing split APKs.
It automatically determines the package name and main launchable activity.

Arguments:
  APK_FILE    Path to the APK or ZIP file to install.

Options:
  -f          Force uninstall the application before installing.
  --help      Display this help message and exit

Environment:
  ANDROID_SERIAL  Serial number of device to connect to (see 'adb devices -l').
                  To target a specific device, use:
                    env ANDROID_SERIAL=<serial> apk-install-and-launch

Examples:
  # Install and launch a standard APK
  apk-install-and-launch my-app.apk

  # Uninstall the existing version, then install and launch a split APK from a ZIP
  apk-install-and-launch -f my-app.zip

If this script breaks, it's probably because apkanalyzer doesn't
work. See if running "apkanalyzer" by itself emits its help page, or
an error. If an error, you probably want to check that JAVA_HOME is
set to the right version of java.
```

<!-- /generated -->

## apk-launch

<!-- generated: ../scripts/apk-launch --help -->

```text
Usage: apk-launch APK_FILE

Launches an application on a connected Android device using its APK.

This script determines the package ID from the APK and uses 'adb monkey'
to launch the main activity.

Arguments:
  APK_FILE    Path to the APK file of the application to launch.

Options:
  --help      Display this help message and exit

Environment:
  ANDROID_SERIAL  Serial number of device to connect to (see 'adb devices -l').
                  To target a specific device, use:
                    env ANDROID_SERIAL=<serial> apk-launch

Examples:
  # Launch the application corresponding to an APK
  apk-launch /path/to/your/app.apk
```

<!-- /generated -->

## apk-launcher-icon-extract

<!-- generated: ../scripts/apk-launcher-icon-extract --help -->

```text
Usage: apk-launcher-icon-extract [OPTIONS] APK_FILE

Extracts the launcher icon and round launcher icon from an APK.

The script decodes the APK, finds the icon resources referenced in the
AndroidManifest.xml, and saves them to the current directory or a specified
output directory. It handles both vector drawables (XML) and raster images (PNG)
and picks the highest density version available.

Arguments:
  APK_FILE    Path to an APK file or a ZIP archive containing a base split APK.

Options:
  -o, --output DIR  The directory to save the icons to. Defaults to the current directory.
  --help            Display this help message and exit

Examples:
  # Extract launcher icons to the current directory
  apk-launcher-icon-extract /path/to/your/app.apk

  # Extract launcher icons to a specific directory
  apk-launcher-icon-extract --output /tmp/icons /path/to/your/app.zip
```

<!-- /generated -->

## apk-packagename

<!-- generated: ../scripts/apk-packagename --help -->

```text
Usage: apk-packagename APK_FILE

Prints the package name (application ID) of an APK.

This script supports both standalone APKs and ZIP archives containing a base
split APK. It uses 'apkanalyzer' to extract the application ID from the manifest.

Arguments:
  APK_FILE    Path to an APK file or a ZIP archive.

Options:
  --help      Display this help message and exit

Examples:
  # Get the package name of a standalone APK
  apk-packagename /path/to/your/app.apk

  # Get the package name from a ZIP archive
  apk-packagename /path/to/your/app.zip
```

<!-- /generated -->

## apk-tiles

<!-- generated: ../scripts/apk-tiles --help -->

```text
Usage: apk-tiles APK_FILE

Lists Wear OS tiles services from the AndroidManifest.xml of a given APK.

This script extracts the manifest and uses XPath to find services that handle
the 'androidx.wear.tiles.action.BIND_TILE_PROVIDER' action.

Arguments:
  APK_FILE    Path to an APK file or a ZIP archive containing a base split APK.

Options:
  --help      Display this help message and exit

Examples:
  # List tiles services from a standalone APK
  apk-tiles /path/to/your/app.apk

  # List tiles services from a ZIP archive
  apk-tiles /path/to/your/app.zip
```

<!-- /generated -->

## apk-unzip

<!-- generated: ../scripts/apk-unzip --help -->

```text
Usage: apk-unzip [OPTIONS] ZIP_FILE

Unzips a file into a specified or temporary directory and prints the directory's path.

This script is useful for inspecting the contents of ZIP archives, such as
Android App Bundles (.aab) or split APKs.

Arguments:
  ZIP_FILE          Path to the ZIP file to unzip.

Options:
  -o, --output DIR  Path to the output directory
  --help            Display this help message and exit

Examples:
  # Unzip to a temporary directory and list its contents
  UNZIPPED_PATH=$(apk-unzip /path/to/your/archive.zip)
  ls "$UNZIPPED_PATH"

  # Unzip to a specific directory
  apk-unzip --output /tmp/my-unzipped-archive /path/to/your/archive.zip
```

<!-- /generated -->

## apk-version-code

<!-- generated: ../scripts/apk-version-code --help -->

```text
Usage: apk-version-code APK_FILE

Prints the version code of an APK.

This script supports both standalone APKs and ZIP archives containing a base
split APK. It uses 'apkanalyzer' to extract the version code from the manifest.

Arguments:
  APK_FILE    Path to an APK file or a ZIP archive.

Options:
  --help      Display this help message and exit

Examples:
  # Get the version code of a standalone APK
  apk-version-code /path/to/your/app.apk

  # Get the version code from a ZIP archive
  apk-version-code /path/to/your/app.zip
```

<!-- /generated -->

## apk-version-name

<!-- generated: ../scripts/apk-version-name --help -->

```text
Usage: apk-version-name APK_FILE

Prints the version name of an APK.

This script supports both standalone APKs and ZIP archives containing a base
split APK. It uses 'apkanalyzer' to extract the version name from the manifest.

Arguments:
  APK_FILE    Path to an APK file or a ZIP archive.

Options:
  --help      Display this help message and exit

Examples:
  # Get the version name of a standalone APK
  apk-version-name /path/to/your/app.apk

  # Get the version name from a ZIP archive
  apk-version-name /path/to/your/app.zip
```

<!-- /generated -->

## apk-version-wear-compose

<!-- generated: ../scripts/apk-version-wear-compose --help -->

```text
Usage: apk-version-wear-compose APK_FILE

Extracts the Wear Compose foundation version from an APK.

This script searches for the 'androidx.wear.compose_compose-foundation.version'
file within the APK's META-INF directory and prints its content.

Arguments:
  APK_FILE    Path to an APK or a ZIP file containing a base split APK.

Options:
  --help      Display this help message and exit

Examples:
  # Get the Wear Compose version from a standalone APK
  apk-version-wear-compose /path/to/your/app.apk

  # Get the Wear Compose version from a ZIP archive
  apk-version-wear-compose /path/to/your/app.zip
```

<!-- /generated -->

## apk-version-whs

<!-- generated: ../scripts/apk-version-whs --help -->

```text
Usage: apk-version-whs APK_FILE

Extracts the Wear Health Services (WHS) client version from an APK.

This script searches for 'whs.properties' or the 'health-services-client.version'
file within the APK and prints its content.

Arguments:
  APK_FILE    Path to an APK or a ZIP file containing a base split APK.

Options:
  --help      Display this help message and exit

Examples:
  # Get the WHS version from a standalone APK
  apk-version-whs /path/to/your/app.apk

  # Get the WHS version from a ZIP archive
  apk-version-whs /path/to/your/app.zip
```

<!-- /generated -->

<!-- markdownlint-restore MD013 -->

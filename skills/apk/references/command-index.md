# Command Index

<!-- markdownlint-disable MD013 -->

## Contents

- [apk-decode](#apk-decode)
- [apk-info](#apk-info)
- [apk-install-and-launch](#apk-install-and-launch)
- [apk-launch](#apk-launch)
- [apk-launcher-icon-extract](#apk-launcher-icon-extract)
- [apk-unzip](#apk-unzip)

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

## apk-info

<!-- generated: ../scripts/apk-info --help -->

```text
Usage: apk-info <command> [arguments]

A unified tool for inspecting Android APK files and split-APK ZIP archives.

Commands:
  package              Print the package name (application ID) of the APK.
  manifest             Display the formatted AndroidManifest.xml.
  version              Print package version details (name and code).
  libraries            List or query embedded Jetpack/Kotlinx library versions.
  tiles                List Wear OS tiles services declared in the manifest.
  complications        List Wear OS complications data providers.
  launcher             Print the path of the launcher icon resource.
  file <path>          Extract and print the contents of a specific file from the APK.

Options:
  --help               Display this help message and exit.

Examples:
  apk-info package app.apk
  apk-info version app.apk
  apk-info libraries --json app.zip
  apk-info libraries --only androidx.wear.compose_compose-foundation app.apk
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

<!-- markdownlint-restore MD013 -->

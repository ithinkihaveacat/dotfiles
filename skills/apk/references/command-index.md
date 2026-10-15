# Command Index

<!-- markdownlint-disable MD013 -->

## Contents

- [apk-decode](#apk-decode)
- [apk-info](#apk-info)
- [apk-install-and-launch](#apk-install-and-launch)
- [apk-launcher-icon-extract](#apk-launcher-icon-extract)
- [apk-smali](#apk-smali)
- [apk-unzip](#apk-unzip)
- [avd-to-png](#avd-to-png)

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
Usage: apk-info COMMAND [ARGUMENTS]

A unified tool for inspecting Android APK files and split-APK ZIP archives.

Commands:
  package              Print the package name (application ID) of the APK.
  manifest             Display the formatted AndroidManifest.xml.
  version              Print package version details (name and code).
  libraries            List or query embedded Jetpack/Kotlinx library versions.
  tiles                List Wear OS tiles and widget providers declared in the manifest.
  widgets              List Wear OS widget and tile providers (alias for tiles).
  complications        List Wear OS complications data providers.
  launcher             Print the path of the launcher icon resource.
  file                 Extract and print the contents of a specific file from the APK.

Options:
  --help, -h           Display this help message and exit.

Examples:
  apk-info package app.apk
  apk-info version app.apk
  apk-info libraries --json app.zip
  apk-info libraries --only androidx.wear.compose_compose-foundation app.apk
  apk-info tiles app.apk
  apk-info file app.apk res/xml/watch_face_info.xml
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

## apk-smali

Disassembles DEX bytecode to one smali tree and queries it. See
[bytecode-analysis.md](bytecode-analysis.md) for when to use smali and how to
report findings.

<!-- generated: ../scripts/apk-smali --help -->

```text
Usage: apk-smali COMMAND [ARGUMENTS]

Disassemble Android DEX bytecode to smali and query the result.

Commands:
  disassemble          Disassemble an APK, split-APK archive, or DEX file into
                       a single smali tree and print its path.
  find                 List classes that declare, call, extend, implement, or
                       are annotated with something.
  show                 Print a class, a method body, class annotations, or a
                       superclass chain.

Options:
  -h, --help           Display this help message and exit.

Examples:
  # Disassemble every DEX file of an APK into one tree
  TREE=$(apk-smali disassemble app-release.apk)

  # Which classes override onTrimMemory(I)V?
  apk-smali find "$TREE" --declares 'onTrimMemory(I)V'

  # A method plus the same-class helpers it calls, one level deep
  apk-smali show method "$TREE" com.example.MyService 'onCreate()V' --depth 1

  # Runtime annotations on a service declared in AndroidManifest.xml
  apk-smali show annotations "$TREE" com.example.MyWidgetService

A TREE is a directory or a ZIP archive of .smali files, such as the output of
'apk-smali disassemble', baksmali, or apktool. ZIP archives are read in place.

Run 'apk-smali COMMAND --help' for command-specific help.
```

<!-- /generated -->

### apk-smali disassemble

<!-- generated: ../scripts/apk-smali disassemble --help -->

```text
Usage: apk-smali disassemble [OPTIONS] INPUT

Disassemble all DEX bytecode in INPUT into a single smali tree (one .smali file
per class, at the path named by its class descriptor) and print the tree's path.

Arguments:
  INPUT             One of:
                      - an APK, or a raw .dex file
                      - a split-APK archive (.zip, .apks, .xapk) or a directory
                        of split APKs; every split is disassembled
                      - an Android App Bundle (.aab); every module is included
                      - a directory of extracted APK contents (classes*.dex)
                      - a ZIP archive or directory of .smali files, which is
                        passed through without disassembly

Options:
  -o, --output DIR  Write the tree to DIR (created if missing; existing files
                    with the same path are overwritten).
                    (defaults to a new temporary directory)
  -h, --help        Display this help message and exit.

Examples:
  # Disassemble an APK into a new temporary directory
  TREE=$(apk-smali disassemble app-release.apk)

  # Disassemble every split in an archive into a specific directory
  apk-smali disassemble --output /tmp/app-smali app-splits.zip

  # Normalize an existing apktool output directory (smali_classes2/, ...)
  apk-smali disassemble -o /tmp/app-smali decoded-apk/

Notes:
  DEX files are disassembled with baksmali when it is on PATH, otherwise with
  'apktool d --no-res' (APK inputs only).

  When a class is defined more than once, the first definition wins, in class
  loading order: classes.dex, classes2.dex, ... within an APK, and the base
  split (or base module) before other splits in alphabetical order. A warning
  reports how many duplicates were skipped.

  A directory that already holds a plain smali tree is printed unchanged
  unless --output is given.
```

<!-- /generated -->

### apk-smali find

<!-- generated: ../scripts/apk-smali find --help -->

```text
Usage: apk-smali find TREE PREDICATE... [OPTIONS]

List the descriptors of classes in TREE that match every PREDICATE, one per
line, sorted.

Arguments:
  TREE                      A directory or ZIP archive of .smali files.

Predicates:
  --declares METHOD         The class declares METHOD.
  --calls [CLASS]->METHOD   A method of the class invokes METHOD (invoke-*).
                            Omit CLASS to match any receiver type.
  --annotated-with CLASS    The class carries a class-level annotation of
                            type CLASS.
  --extends CLASS           The class's direct superclass (.super) is CLASS.
  --implements CLASS        The class directly implements interface CLASS.

  METHOD is NAME, NAME(PARAMS) (any return type), or NAME(PARAMS)RETURN, for
  example onTrimMemory, onTrimMemory(I), or onTrimMemory(I)V. CLASS is a type
  descriptor (Lcom/example/Foo;) or a dotted name (com.example.Foo).

Options:
  --methods                 Print the matching methods (CLASS->METHOD) instead
                            of classes; requires --declares or --calls.
  -h, --help                Display this help message and exit.

Exit Status:
  0  at least one class matched
  1  no class matched
  2  an error occurred

Examples:
  # Classes that override onTrimMemory(I)V
  apk-smali find "$TREE" --declares 'onTrimMemory(I)V'

  # Methods that call any onTrimMemory, whatever the receiver
  apk-smali find "$TREE" --calls '->onTrimMemory' --methods

  # Services that are also annotated with an (obfuscated) annotation type
  apk-smali find app-smali.zip --extends 'Landroid/app/Service;' \
      --annotated-with 'La/b;'
```

<!-- /generated -->

### apk-smali show

<!-- generated: ../scripts/apk-smali show --help -->

```text
Usage: apk-smali show WHAT TREE CLASS [ARGUMENTS] [OPTIONS]

Print part of a class from a smali tree.

Commands:
  class                Print the whole .smali file of CLASS.
  method               Print the body of a method, optionally with the
                       same-class methods it calls.
  annotations          Print the class-level annotations of CLASS.
  hierarchy            Print the superclass chain of CLASS.

Arguments:
  TREE                 A directory or ZIP archive of .smali files.
  CLASS                A type descriptor (Lcom/example/Foo;) or a dotted name
                       (com.example.Foo).

Options:
  -h, --help           Display this help message and exit.

Examples:
  apk-smali show class "$TREE" com.example.MyWidgetService
  apk-smali show method "$TREE" com.example.MyService 'onTrimMemory(I)V'
  apk-smali show annotations "$TREE" 'Lcom/example/MyWidgetService;'
  apk-smali show hierarchy "$TREE" com.example.MyWidgetService

Run 'apk-smali show WHAT --help' for help on each command.
```

<!-- /generated -->

#### apk-smali show class

<!-- generated: ../scripts/apk-smali show class --help -->

```text
Usage: apk-smali show class TREE CLASS

Print the whole .smali file of CLASS.

Arguments:
  TREE         A directory or ZIP archive of .smali files.
  CLASS        A type descriptor (Lcom/example/Foo;) or a dotted name
               (com.example.Foo).

Options:
  -h, --help   Display this help message and exit.

Examples:
  apk-smali show class "$TREE" com.example.MyWidgetService
  apk-smali show class app-smali.zip 'La/b;'
```

<!-- /generated -->

#### apk-smali show method

<!-- generated: ../scripts/apk-smali show method --help -->

```text
Usage: apk-smali show method TREE CLASS METHOD [OPTIONS]

Print the full .method ... .end method body of METHOD in CLASS. All overloads
are printed when METHOD omits the parameter list.

Arguments:
  TREE           A directory or ZIP archive of .smali files.
  CLASS          A type descriptor (Lcom/example/Foo;) or a dotted name
                 (com.example.Foo).
  METHOD         NAME, NAME(PARAMS), or NAME(PARAMS)RETURN, for example
                 onTrimMemory(I)V.

Options:
  --depth N      Also print methods of CLASS that the printed methods invoke,
                 following calls N levels deep; each method is printed once.
                 (default: 0)
  -h, --help     Display this help message and exit.

Examples:
  # The body of an override
  apk-smali show method "$TREE" com.example.MyService 'onTrimMemory(I)V'

  # The override plus the private helpers it calls, two levels deep
  apk-smali show method "$TREE" 'Lcom/example/MyService;' onTrimMemory --depth 2
```

<!-- /generated -->

#### apk-smali show annotations

<!-- generated: ../scripts/apk-smali show annotations --help -->

```text
Usage: apk-smali show annotations TREE CLASS [OPTIONS]

Print the class-level .annotation blocks of CLASS, including their values
(for example the class literals an annotation references).

Arguments:
  TREE           A directory or ZIP archive of .smali files.
  CLASS          A type descriptor (Lcom/example/Foo;) or a dotted name
                 (com.example.Foo).

Options:
  --all          Include Lkotlin/Metadata; and Ldalvik/annotation/* blocks,
                 which are hidden by default.
  --members      Also print field and method annotations; each group is
                 preceded by a '# CLASS', '# CLASS->FIELD' or
                 '# CLASS->METHOD' comment line.
  -h, --help     Display this help message and exit.

Examples:
  # Runtime annotations on a service declared in AndroidManifest.xml
  apk-smali show annotations "$TREE" com.example.MyWidgetService

  # Every annotation in the class, including compiler metadata
  apk-smali show annotations app-smali.zip 'La/b;' --all --members
```

<!-- /generated -->

#### apk-smali show hierarchy

<!-- generated: ../scripts/apk-smali show hierarchy --help -->

```text
Usage: apk-smali show hierarchy TREE CLASS [OPTIONS]

Print CLASS and its superclasses, one descriptor per line, from CLASS up to
java.lang.Object. The chain stops at the first superclass that is not in TREE
(typically a framework class such as Landroid/app/Service;), which is printed
with a '# not in tree' comment.

Arguments:
  TREE            A directory or ZIP archive of .smali files.
  CLASS           A type descriptor (Lcom/example/Foo;) or a dotted name
                  (com.example.Foo).

Options:
  --interfaces    Also print each class's directly implemented interfaces,
                  indented, as 'implements DESCRIPTOR' lines.
  -h, --help      Display this help message and exit.

Examples:
  # Does an obfuscated service extend the library base class?
  apk-smali show hierarchy "$TREE" com.example.MyWidgetService

  # Include the interfaces each class implements
  apk-smali show hierarchy app-smali.zip 'La/b;' --interfaces
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

## avd-to-png

<!-- generated: ../scripts/avd-to-png --help -->

```text
Usage: avd-to-png [options] AVD_FILE RES_DIR

Converts an Android Vector Drawable (AVD) XML file to a standard SVG and renders it to a high-quality PNG.

Arguments:
  AVD_FILE            Path to the Android Vector Drawable (.xml).
  RES_DIR             Path to the Android resource directory (used to resolve @color references).

Options:
  -o, --output PATH   Path to the output PNG file. If not specified, outputs to the current directory with the same basename.
  --help              Display this help message and exit
```

<!-- /generated -->

<!-- markdownlint-restore MD013 -->

# Command Index

## `wear-widget-audit`

<!-- generated: ../scripts/wear-widget-audit --help -->

```text
Usage: wear-widget-audit [OPTIONS] TARGET [TARGET ...]

Evaluate one or more Android APKs or split-APK directories against the
32-attribute Wear OS widget and tile launch-readiness schema (checks C01-C19
and architectural attributes D01-D13).

Arguments:
  TARGET                Path to a monolithic .apk, a split-APK directory
                        (base.apk + config.*.apk), a split-APK .zip/.apks
                        archive, or a directory containing AndroidManifest.xml.

Options:
  --pretty              Emit indented JSON output (default).
  --compact             Emit single-line compact JSON output.
  --json                Emit JSON output (default unless --summary is set).
  --summary             Emit a human-readable summary table instead of JSON
                        (or combine with --json to print summary to stderr).
  --array               Always wrap JSON output in a list, even for one TARGET.
  --runtime-json FILE   Load runtime check overrides (C16-C19, D13) from FILE.
  -o, --output FILE     Write output to FILE instead of standard output.
  -h, --help            Display this help message and exit.

Examples:
  # Audit a single Wear OS APK and print pretty JSON
  wear-widget-audit app-wear-release.apk

  # Audit a split-APK bundle directory and display a human summary table
  wear-widget-audit --summary splits/com.example.app/

  # Batch-audit multiple targets into a single JSON report file
  wear-widget-audit --pretty -o cohort-audit.json apks/com.example.one apks/com.example.two
```

<!-- /generated -->

#!/usr/bin/env bash
set -euo pipefail

# Path to the script under test
SCRIPT="/usr/local/google/home/stillers/.gemini/config/skills/jetpack/scripts/jetpack-samples"

echo "Running jetpack-samples smoke test..."

# Create a temporary directory for output
OUT_DIR=$(mktemp -d)
cleanup() {
  rm -rf "$OUT_DIR"
}
trap cleanup EXIT

# Run the script for a known artifact with samples
# We use androidx.compose.runtime:runtime as it should have samples in compose/runtime
echo "Testing with androidx.compose.runtime:runtime..."
"$SCRIPT" androidx.compose.runtime:runtime --output "$OUT_DIR"

# Verify that we downloaded something
if [ ! -d "$OUT_DIR" ]; then
  echo "FAIL: Output directory was not created"
  exit 1
fi

# List what was downloaded
echo "Downloaded structure:"
find "$OUT_DIR" -maxdepth 3

# Verify we have at least one module directory with a src folder
SRC_COUNT=$(find "$OUT_DIR" -type d -name "src" | wc -l)
if [ "$SRC_COUNT" -eq 0 ]; then
  echo "FAIL: No 'src' directories found in the output. Download might have failed."
  exit 1
fi

# Verify we got build.gradle (proving we got the Gitiles archive optimization, not just individual source files)
GRADLE_COUNT=$(find "$OUT_DIR" -name "build.gradle" -o -name "build.gradle.kts" | wc -l)
if [ "$GRADLE_COUNT" -eq 0 ]; then
  echo "FAIL: No 'build.gradle' or 'build.gradle.kts' files found. Did not get the complete module."
  exit 1
fi

echo "PASS: Smoke test completed successfully!"

#!/usr/bin/env bash
set -euo pipefail

# 1. Verify legacy domain is completely purged
if grep -ri "legacy-api.internal.corp" notes/ >/dev/null 2>&1; then
  echo "FAIL: References to legacy-api.internal.corp still exist in notes/" >&2
  exit 1
fi

# 2. Verify note_004 and note_017 updated to v2
if ! grep -q "https://api.internal.corp/v2/services" notes/note_004.md; then
  echo "FAIL: notes/note_004.md missing https://api.internal.corp/v2/services" >&2
  exit 1
fi

if ! grep -q "https://api.internal.corp/v2/auth" notes/note_017.md; then
  echo "FAIL: notes/note_017.md missing https://api.internal.corp/v2/auth" >&2
  exit 1
fi

echo "PASS: Corpus needle replacement verified"
exit 0

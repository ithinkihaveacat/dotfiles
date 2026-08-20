#!/usr/bin/env bash
set -euo pipefail

DOC="docs/client_guide.md"

# 1. Verify outdated parameters are gone
if grep -q "timeout=10.0" "$DOC" || grep -q "retries=5" "$DOC"; then
  echo "FAIL: Outdated code parameters timeout=10.0 or retries=5 still present" >&2
  exit 1
fi

if grep -q "\- \`dataset\`:" "$DOC" || grep -q "\- \`retries\`:" "$DOC"; then
  echo "FAIL: Outdated parameter list entries for 'dataset' or 'retries' found" >&2
  exit 1
fi

# 2. Verify new parameters and defaults are present
if ! grep -q "dataset_id" "$DOC" || ! grep -q "timeout_seconds" "$DOC" || ! grep -q "retry_limit" "$DOC"; then
  echo "FAIL: New parameter names missing from documentation" >&2
  exit 1
fi

if ! grep -q "30" "$DOC" || ! grep -q "3" "$DOC"; then
  echo "FAIL: Updated parameter default values (30, 3) missing from documentation" >&2
  exit 1
fi

echo "PASS: Doc code synchronization verified"
exit 0

#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f "audit_report.md" ]]; then
  echo "FAIL: audit_report.md was not generated" >&2
  exit 1
fi

REPORT="audit_report.md"

# Verify detection of Log Retention contradiction (90 days vs 365 days)
if ! grep -qi "90" "$REPORT" || ! grep -qi "365" "$REPORT"; then
  echo "FAIL: Audit report missed the 90 vs 365 days log retention contradiction" >&2
  exit 1
fi

# Verify detection of Stipend contradiction ($500 vs $1,200)
if ! grep -qi "500" "$REPORT" || ! grep -qi "1,200\|1200" "$REPORT"; then
  echo "FAIL: Audit report missed the $500 vs $1,200 stipend contradiction" >&2
  exit 1
fi

# Verify detection of Background check timeline contradiction (5 days vs 14 days)
if ! grep -qi "5" "$REPORT" || ! grep -qi "14" "$REPORT"; then
  echo "FAIL: Audit report missed the 5 vs 14 days background screening contradiction" >&2
  exit 1
fi

# Verify policy files are referenced
if ! grep -q "data_retention" "$REPORT" || ! grep -q "security_access" "$REPORT"; then
  echo "FAIL: Audit report does not cite source policy files" >&2
  exit 1
fi

echo "PASS: Policy contradiction audit verified"
exit 0

#!/usr/bin/env bash
set -euo pipefail

# 1. Verify obsolete terms are gone
if grep -ri "Q-Core" book/chapter*.md >/dev/null 2>&1; then
  echo "FAIL: Found deprecated term 'Q-Core' in book/" >&2
  exit 1
fi

if grep -ri "Quantum Engine" book/chapter*.md >/dev/null 2>&1; then
  echo "FAIL: Found deprecated term 'Quantum Engine' in book/" >&2
  exit 1
fi

# 2. Verify canonical term is used
if ! grep -q "Quantum Core" book/chapter1.md || ! grep -q "Quantum Core" book/chapter2.md || ! grep -q "Quantum Core" book/chapter3.md; then
  echo "FAIL: Canonical term 'Quantum Core' missing from one or more chapters" >&2
  exit 1
fi

# 3. Verify links point to real files
if grep -q "chapter-2.md" book/chapter1.md; then
  echo "FAIL: Broken link chapter-2.md still present in chapter1.md" >&2
  exit 1
fi

if grep -q "chap3.md" book/chapter2.md; then
  echo "FAIL: Broken link chap3.md still present in chapter2.md" >&2
  exit 1
fi

if ! grep -q "chapter2.md" book/chapter1.md || ! grep -q "chapter3.md" book/chapter2.md; then
  echo "FAIL: Corrected chapter links missing" >&2
  exit 1
fi

echo "PASS: Prose consistency verified"
exit 0

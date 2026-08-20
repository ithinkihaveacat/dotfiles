#!/usr/bin/env bash
set -euo pipefail

if [[ -f "docs/monolith_architecture.md" ]]; then
  echo "FAIL: Monolithic file docs/monolith_architecture.md was not deleted" >&2
  exit 1
fi

if [[ ! -f "docs/arch/01_overview.md" ]] || [[ ! -f "docs/arch/02_storage.md" ]] || [[ ! -f "docs/arch/03_networking.md" ]] || [[ ! -f "docs/arch/README.md" ]]; then
  echo "FAIL: One or more target modular documents in docs/arch/ are missing" >&2
  exit 1
fi

if ! grep -qi "Executive Overview" docs/arch/01_overview.md || ! grep -qi "LSM-tree" docs/arch/02_storage.md || ! grep -qi "eBPF" docs/arch/03_networking.md; then
  echo "FAIL: Modular files do not contain expected section content" >&2
  exit 1
fi

if ! grep -q "01_overview.md" docs/arch/README.md || ! grep -q "02_storage.md" docs/arch/README.md || ! grep -q "03_networking.md" docs/arch/README.md; then
  echo "FAIL: docs/arch/README.md missing markdown links to submodules" >&2
  exit 1
fi

echo "PASS: Document split verified"
exit 0

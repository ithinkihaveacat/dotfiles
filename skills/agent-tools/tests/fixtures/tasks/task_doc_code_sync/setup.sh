#!/usr/bin/env bash
set -euo pipefail

git init -q .
git config user.email "benchmark@test.local"
git config user.name "Benchmark Runner"

mkdir -p src docs

cat <<'SUBEOF' >src/client.py
"""Client library for dataset operations."""

from typing import Any, Dict


class DatasetClient:

  def __init__(self, endpoint: str = "https://api.example.com") -> None:
    self.endpoint = endpoint

  def fetch_records(
      self,
      dataset_id: str,
      timeout_seconds: int = 30,
      retry_limit: int = 3,
      enable_compression: bool = True,
  ) -> Dict[str, Any]:
    """Fetches records from the remote dataset store.

    Args:
        dataset_id: Unique string identifier for the dataset.
        timeout_seconds: Network request timeout in seconds (default: 30).
        retry_limit: Number of transient retries before failure (default: 3).
        enable_compression: Whether payload compression is enabled (default:
          True).

    Returns:
        Dictionary payload containing dataset records.
    """
    return {"dataset_id": dataset_id, "status": "ok"}
SUBEOF

cat <<'SUBEOF' >docs/client_guide.md
# Dataset Client Usage Guide

The `DatasetClient` provides access to dataset operations.

## Basic Usage

To query records, instantiate the client and call `fetch_records`:

```python
from src.client import DatasetClient

client = DatasetClient()
data = client.fetch_records(dataset="ds_123", timeout=10.0, retries=5)
print(data)
```

### Parameters for `fetch_records`
- `dataset`: String identifier for target dataset.
- `timeout`: Timeout in seconds (default: 10.0).
- `retries`: Max retry count (default: 5).
SUBEOF

git add src/ docs/
git commit -q -m "Initial client and outdated documentation"

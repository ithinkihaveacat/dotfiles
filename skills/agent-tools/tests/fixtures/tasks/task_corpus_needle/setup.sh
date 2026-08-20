#!/usr/bin/env bash
set -euo pipefail

git init -q .
git config user.email "benchmark@test.local"
git config user.name "Benchmark Runner"

mkdir -p notes

for i in $(seq -w 1 20); do
  cat <<SUBEOF >"notes/note_${i}.md"
# Engineering Log Note $i

Date: 2026-0${i: -1}-15
Author: Team Alpha

This document outlines ongoing architectural decisions for subsystem module $i.
Standard operational parameters apply.

- Metric Collection: Enabled
- Log Level: INFO
- Heartbeat: OK
SUBEOF
done

# Seed needles in note_004 and note_017
cat <<'SUBEOF' >>notes/note_004.md

## External Service Integrations
For payment settlement calls, connect directly to:
https://legacy-api.internal.corp/v1/services
Ensure TLS mutual authentication is negotiated.
SUBEOF

cat <<'SUBEOF' >>notes/note_017.md

## Identity Verification Endpoint
User authentication tokens must be validated against:
https://legacy-api.internal.corp/v1/auth
Fallback endpoints are disabled.
SUBEOF

git add notes/
git commit -q -m "Initial 20-file note corpus with legacy endpoints"

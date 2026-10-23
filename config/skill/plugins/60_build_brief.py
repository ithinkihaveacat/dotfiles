# Plugin for build-brief instructions
# Source: https://github.com/static-var/build-brief/blob/main/README.md#agent-integration
from __future__ import annotations

import os
from pathlib import Path

SKILL_CONTENT = """---
name: build-brief
description: >-
  Use when working with Android, JVM, Kotlin Multiplatform, Spring, Ktor, or
  other Gradle projects where an agent may run gradle or ./gradlew. Read before
  running Android Gradle builds/tests, chained Gradle commands, or noisy Gradle
  diagnostics. build-brief wraps Gradle, preserves raw logs and exit codes, and
  emits concise summaries of failures, tests, warnings, artifacts, and final
  status.
---

<!-- Source: https://github.com/static-var/build-brief/blob/main/README.md -->

# build-brief

- `build-brief` is a small CLI that sits in front of `gradle` or `./gradlew`,
  keeps the full raw Gradle log on disk, and cuts terminal output down to the
  parts that usually matter.

## Availability & Agent Guidelines

- Check whether `build-brief` is installed before invoking it:

  ```bash
  command -v build-brief >/dev/null 2>&1
  ```

- **When `build-brief` is installed:** Prefer wrapping Gradle commands with
  `build-brief gradle ...` for PATH Gradle and `build-brief ./gradlew ...` for
  the project wrapper.
- **When `build-brief` is not installed:**
  - In automated agent sessions, do **not** run curl installers unprompted. Fall
    back directly to `./gradlew` or `gradle` (e.g. `./gradlew assembleDebug`,
    `./gradlew test`).
  - To install `build-brief` on a workstation or when explicitly requested, follow
    the installation instructions below.

## Installation

Install `build-brief` using any of the following methods:

- **Shell script installer (macOS & Linux):**

  ```bash
  curl -fsSL https://bb.staticvar.dev/install.sh | bash
  # or: wget -qO- https://bb.staticvar.dev/install.sh | bash
  ```

  Installs to `~/.local/bin` (or `/usr/local/bin` if writable). Ensure
  `~/.local/bin` is in your `$PATH`.

- **Homebrew / Linuxbrew:**

  ```bash
  brew tap static-var/tap
  brew install static-var/tap/build-brief
  ```

- **Go install (from source):**

  ```bash
  go install github.com/static-var/build-brief/cmd/build-brief@latest
  # or clone and build:
  git clone https://github.com/static-var/build-brief.git
  cd build-brief && go build -o ~/.local/bin/build-brief ./cmd/build-brief
  ```

- **Prebuilt release binary:**
  Download the platform release archive from
  <https://github.com/static-var/build-brief/releases/latest> and extract the
  `build-brief` executable into a directory on `$PATH`.

## Usage

- For simple commands, use `build-brief test`, `build-brief build`, or
  `build-brief :app:assembleDebug`.
- Prefer `build-brief gradle ...` for PATH Gradle and
  `build-brief ./gradlew ...` for the project wrapper.
- For isolated Gradle user homes, run:

  ```bash
  build-brief --gradle-user-home /tmp/build-brief-gradle-home ./gradlew test
  ```

- For chained shell commands, rewrite each Gradle segment individually, for
  example `build-brief gradle test && build-brief gradle check`.
- Use default `build-brief` output for routine Gradle work; it stays
  intentionally short on clean success cases.
- Use default `build-brief` output for report-style commands like `tasks`,
  `help`, `projects`, `dependencies`, and `dependencyInsight`; their report
  bodies are preserved.
- Use `build-brief gradle --stacktrace ...` or
  `build-brief ./gradlew --stacktrace ...` when you need Gradle stack traces.
- `build-brief` normalizes output-shaping flags like `--quiet`, `--warn`,
  `--warning-mode ...`, and `--console ...` so its reducer keeps working
  reliably.
- Let Gradle daemon reuse happen by default; `build-brief` strips explicit
  `--daemon` and `--no-daemon` overrides rather than forcing daemon-off
  behavior.
- Preserve the raw log path from `build-brief` output when handing build
  failures to another tool or agent.
- Use `build-brief gains --history` if you need to inspect recent rough token
  savings from wrapped Gradle commands.
"""


def register(api) -> None:
    cache_dir = Path(os.path.expanduser("~/.cache/skill/generated/build-brief"))
    skill_md = cache_dir / "SKILL.md"

    cache_dir.mkdir(parents=True, exist_ok=True)
    if not skill_md.exists() or skill_md.read_text(encoding="utf-8") != SKILL_CONTENT:
        skill_md.write_text(SKILL_CONTENT, encoding="utf-8")

    api.register_skill("local:build-brief", {"path": str(cache_dir), "generated": True})

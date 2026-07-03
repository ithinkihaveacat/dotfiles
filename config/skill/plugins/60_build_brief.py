# Plugin for build-brief instructions
# Source: https://github.com/static-var/build-brief/blob/main/README.md#agent-integration
from __future__ import annotations

import os
from pathlib import Path


def register(api) -> None:
    cache_dir = Path(os.path.expanduser("~/.cache/skill/generated/build-brief"))
    skill_md = cache_dir / "SKILL.md"

    if not skill_md.exists():
        cache_dir.mkdir(parents=True, exist_ok=True)
        skill_md.write_text(
            """---
name: build-brief
description: Guard and streamline routine Gradle commands by steering agents toward build-brief.
---

<!-- Source: https://github.com/static-var/build-brief/blob/main/README.md -->

# build-brief

- Prefer `build-brief gradle ...` for PATH Gradle and
  `build-brief ./gradlew ...` for the project wrapper.
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
""",
            encoding="utf-8",
        )

    api.register_skill("local:build-brief", {"path": str(cache_dir)})

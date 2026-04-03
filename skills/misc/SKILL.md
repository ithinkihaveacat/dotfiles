---
name: misc
description: >
  Capture private, user-specific conventions and one-off workflows that are not
  intended to be shared as standalone skills. Use when applying personal rules,
  preferences, or formatting conventions, especially when handling Google Maps
  links, `maps.app.goo.gl` shared URLs, redirect expansion, or when writing map
  URLs into Markdown or other durable text. Also use when running small local
  Python utilities for testing, validation, verification, or fixups, especially
  when `uv` is available and preferable to relying on the system Python
  environment.
---

# Misc

## Overview

Use this skill for personal conventions that do not justify a dedicated shared
skill. Keep this file concise and add new sections over time as distinct private
rules emerge.

## Google Maps URLs

When given a shared Google Maps URL such as
`https://maps.app.goo.gl/Sj35TdmavfLyWvXC8`, expand it to the final full URL
before using it anywhere the exact destination matters.

Use:

```bash
curl -Ls -o /dev/null -w "%{url_effective}\n" "$URL"
```

Example:

```bash
curl -Ls -o /dev/null -w "%{url_effective}\n" \
  https://maps.app.goo.gl/Sj35TdmavfLyWvXC8
```

Treat the expanded URL as the canonical form.

Prefer the expanded URL:

- When writing Markdown
- When storing or sharing the link in durable text
- When inspecting query parameters or location details
- When the exact destination URL is needed for further processing

Do not preserve the short shared form unless the user explicitly wants the short
URL itself.

## Running Python Scripts

When running a small local Python utility, prefer `uv` when it is available.
This is especially useful for quick scripts used for testing, validation,
verification, and fixups.

Prefer `uv` because it is often already installed and can provide ad hoc
dependencies without assuming the system Python environment is prepared
correctly.

Example:

```bash
UV_CACHE_DIR=/tmp/uv-cache uv run --with pyyaml python3 script.py
```

Set `UV_CACHE_DIR` to a temporary directory when `uv` cannot use its default
cache location. Example: `UV_CACHE_DIR=/tmp/uv-cache`.

## Future Additions

Add new sections here for other private conventions. Keep each topic
self-contained so the skill can remain a small grab bag without turning into a
generic dumping ground.

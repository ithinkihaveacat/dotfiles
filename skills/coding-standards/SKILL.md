---
name: coding-standards
description: >-
  Repository coding standards, linters, formatters, CLI design rules, HTTP caching
  guidelines, and git commit message conventions (Conventional Commits). Includes
  scripts for formatting Python, shell, Markdown, Kotlin, JSON, and XML. Use when
  writing, reviewing, formatting, or linting code, verifying CLI ergonomics,
  implementing caching and offline modes, or formatting git commit messages.
compatibility: Requires ruff, shfmt, shellcheck, mdformat, jq, xmllint, ktfmt, or uv/uvx.
---

# Coding Standards

This skill provides coding guidelines, linters, and formatters for making
changes across languages and domains in this repository.

## Formatting Scripts

Helper scripts in `scripts/` encapsulate repository-wide style rules and lint
checks. References to `scripts/...` are relative to this skill directory. All
scripts support formatting multiple files in place, or reading from `stdin` and
writing to `stdout` when no arguments are provided.

- **`scripts/python-format`**: Format and lint Python files using `ruff`
  (supports `--check` and recursive directory scanning).
- **`scripts/shell-format`**: Format and lint shell scripts (POSIX/Bash) using
  `shfmt` and `shellcheck` (supports `--check` and recursive directory scanning;
  Fish scripts use `fish_indent`).
- **`scripts/markdown-format`**: Format Markdown files using `mdformat` with GFM
  and frontmatter preservation (supports `--check` for drift detection).
- **`scripts/command-index-sync`**: Refresh generated `--help` blocks in
  `command-index.md` files (marker comments; supports `--check` and `--all`).
- **`scripts/kotlin-format`**: Format Kotlin files using `ktfmt` with kotlinlang
  style.
- **`scripts/json-format`**: Format JSON files using `jq`.
- **`scripts/xml-format`**: Format XML files using `xmllint`.

Always prefer the helper scripts in `scripts/` over raw tool invocations to
guarantee consistent repository formatting rules.

## Core Standards & Guidelines

### Markdown Quality

All Markdown files must be formatted and linted with `scripts/markdown-format`.
Headings must use clean, unadorned ATX styles (`## Heading`) without numbers,
manual bolding, or ALL CAPS. See
**[references/markdown.md](references/markdown.md)**.

### Python Development

All Python files must be linted and formatted with `scripts/python-format`.
Follow type annotation conventions, structured CLI argument parsing with
`argparse`, and error handling standards. See
**[references/python.md](references/python.md)**.

### Shell Script Quality

All shell scripts must pass `scripts/shell-format` (`shellcheck` and `shfmt`).
Use POSIX or Bash idioms with strict error handling (`set -euo pipefail` or
`set -u`), safe quoting, and discoverable help systems conforming to CLI design
guidelines. See **[references/shell.md](references/shell.md)**.

### CLI Tool Design

Language-agnostic rules for designing predictable, discoverable command-line
tools: clean command structures (`tool [verb] [noun]`), dual output streams
(`stdout` for data, `stderr` for diagnostics), deterministic exit codes, and
`--help` formatting. See **[references/cli-tools.md](references/cli-tools.md)**.

### Caching and Offline Mode

Cross-cutting conventions for tools that fetch remote resources over the
network: caching under `$XDG_CACHE_HOME`, strict offline mode enforcement via
`AGENT_OFFLINE=1` / `<TOOL>_OFFLINE=1`, and cache-age reporting. See
**[references/caching.md](references/caching.md)**.

### Git Operations & Commit Messages

Agents must not commit changes automatically unless explicitly authorized.
Commit messages must adhere strictly to Conventional Commits syntax
(`type(scope): description`), keeping the subject under 50 characters and
hard-wrapping body prose to 72 characters. See
**[references/git.md](references/git.md)**.

### Android Development

Conventions and tools for working with Android Jetpack libraries, ADB device
operations, APK analysis, package management, Wear OS debugging, and emulator
management. See **[references/android.md](references/android.md)**.

### Web Development

Guidelines for web development focusing on resilient client-side state
management, deep-linking, scroll-position preservation, and navigation behavior.
See **[references/web.md](references/web.md)**.

## Reference Material

- **[Markdown Standards](references/markdown.md)** — GFM rules, frontmatter
  handling, and heading conventions.
- **[Python Standards](references/python.md)** — Code style, typing, and
  packaging practices.
- **[Shell Standards](references/shell.md)** — POSIX/Bash scripting rules, error
  handling, and linters.
- **[CLI Design](references/cli-tools.md)** — Universal CLI UI/UX standards,
  output streams, and exit codes.
- **[Caching & Offline](references/caching.md)** — Network caching patterns and
  offline-mode variables.
- **[Git Operations](references/git.md)** — Conventional Commits syntax and
  commit message rules.
- **[Android Conventions](references/android.md)** — Android development and
  tooling standards.
- **[Web Guidelines](references/web.md)** — State management and web frontend
  guidelines.

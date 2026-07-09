---
name: coding-standards
description: >-
  Use this skill when writing, reviewing, or validating code (shell scripts,
  Python, Markdown, Web) or CLI tools to ensure they follow repository coding
  standards and conventions. Also use when formatting git commit messages
  (Conventional Commits syntax, line wrapping) or checking code for style
  compliance. Triggers: coding standards, style guide, validate change,
  review conventions, shellcheck, shfmt, markdown format, python, ruff,
  uvx, lint, commit message format, CLI design, code review, formatting,
  web development, state management, scroll position, frontend.
---

# Coding Standards

This skill provides coding guidelines for making changes to codebases in this
repository, as well as documentation for notations that agents may encounter.

## Coding Guidelines

### Markdown Quality

All Markdown files must be formatted and linted with `scripts/markdown-format`.

@references/markdown.md

## Formatting Scripts

This skill includes several formatting helper scripts in the `scripts/`
directory. References to `scripts/...` in this skill are relative to this skill
directory. All scripts support formatting multiple files in place, or reading
from stdin and writing to stdout when no arguments are provided.

- **`scripts/command-index-sync`**: Refresh generated `--help` blocks in
  `command-index.md` files (marker comments; supports `--check` and `--all` for
  drift detection).
- **`scripts/json-format`**: Format JSON files using `jq`.
- **`scripts/kotlin-format`**: Format Kotlin files using `ktfmt` with kotlinlang
  style.
- **`scripts/markdown-format`**: Format Markdown files using `mdformat` with
  GFM/frontmatter preservation and wrapping (supports `--check` for clean
  verification).
- **`scripts/python-format`**: Format and lint Python files using `ruff`
  (supports `--check`, and recursive directory scanning).
- **`scripts/shell-format`**: Format and lint shell scripts (POSIX/Bash) using
  `shfmt` and `shellcheck` (supports `--check` and recursive directory
  scanning).
- **`scripts/xml-format`**: Format XML files using `xmllint`.

Always prefer the scripts in `scripts/` over raw tool invocations to ensure
consistent formatting rules are applied across the repository.

### Python Development

All Python files must be linted and formatted with `scripts/python-format`.

@references/python.md

### CLI Tool Design

The language-agnostic authority for designing predictable and discoverable
command-line interfaces (UI/UX). This includes command structure, help systems,
output streams, and exit code philosophy.

@references/cli-tools.md

### Shell Script Quality

The language-specific implementation guide for shell scripts. All shell scripts
must be formatted and linted with `scripts/shell-format`; Fish scripts use
`fish_indent`. Scripts must have robust error handling and comply with the UX
standards in `cli-tools.md`.

@references/shell.md

### Android Development

Tools for working with Android Jetpack libraries, ADB operations, APK analysis,
package management, Wear OS debugging, and emulator management.

@references/android.md

### Web Development

Guidelines for web development, focusing on state management and browser
navigation behavior.

@references/web.md

### Git Operations

Agents must not commit changes automatically unless explicitly requested. Follow
the specified commit message format.

@references/git.md

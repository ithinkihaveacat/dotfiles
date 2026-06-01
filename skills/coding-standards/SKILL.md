---
name: coding-standards
description: >-
  Use this skill when writing, reviewing, or validating code (shell scripts,
  Python, Markdown) or CLI tools to ensure they follow repository coding
  standards and conventions. Also use when formatting git commit messages
  (Conventional Commits syntax, line wrapping) or checking code for style
  compliance. Triggers: coding standards, style guide, validate change,
  review conventions, shellcheck, shfmt, markdown format, python, ruff,
  uvx, lint, commit message format, CLI design, code review, formatting.
---

# Coding Standards

This skill provides coding guidelines for making changes to codebases in this
repository, as well as documentation for notations that agents may encounter.

## Coding Guidelines

### Markdown Quality

All Markdown files must be formatted and linted with `markdown-format`. Use
standard heading styles without additional formatting or ALL CAPS. Do not add
numbers to headings.

@references/markdown.md

### Python Development

All Python files must be linted and formatted with `ruff`. Use `uvx` to run
tools. Target Python 3.11+.

@references/python.md

### CLI Tool Design

The language-agnostic authority for designing predictable and discoverable
command-line interfaces (UI/UX). This includes command structure, help systems,
output streams, and exit code philosophy.

@references/cli-tools.md

### Shell Script Quality

The language-specific implementation guide for shell scripts. All shell scripts
must be linted with `shellcheck` and formatted with `shfmt`. Fish scripts use
`fish_indent`. Scripts must have robust error handling and comply with the UX
standards in `cli-tools.md`.

@references/shell.md

### Android Development

Tools for working with Android Jetpack libraries, ADB operations, APK analysis,
package management, Wear OS debugging, and emulator management.

@references/android.md

### Git Operations

Agents must not commit changes automatically unless explicitly requested. Follow
the specified commit message format.

@references/git.md

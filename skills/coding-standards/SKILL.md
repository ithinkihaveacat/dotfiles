---
name: coding-standards
description: >
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

Standards for designing predictable and discoverable command-line interfaces,
including command structure, help systems, and exit codes.

@references/cli-tools.md

### Shell Script Quality

All shell scripts must be linted with `shellcheck` and formatted with `shfmt`.
Fish scripts use `fish_indent`. Scripts must have robust error handling.

@references/shell.md

### Android Development

Tools for working with Android Jetpack libraries, ADB operations, APK analysis,
package management, Wear OS debugging, and emulator management.

@references/android.md

### Git Operations

Agents must not commit changes automatically unless explicitly requested. Follow
the specified commit message format.

@references/git.md

## Agent Function Notation (AFN)

A notation for describing agent behaviour as functions of the form
`G<type>(prompt, context…) = output`. Covers function variants, substitution,
type fuzziness, and worked examples.

@references/afn.md

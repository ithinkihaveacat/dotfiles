---
name: coding-standards
description: >
  Coding standards and conventions for this repository: shell script quality
  (shellcheck, shfmt, error handling, Bash compatibility), CLI tool design
  (verb-noun command patterns, help systems, exit codes, output conventions),
  Markdown formatting (markdown-format, heading styles), git commit policies
  (message format, agent commit restrictions), and Android development context.
  Use when writing, reviewing, or validating scripts, CLI tools, Markdown files,
  or git commits against project conventions. Also use when asked to check
  whether a change follows coding standards, review code for style compliance,
  or validate work against project rules. Triggers: coding standards, style
  guide, validate change, review conventions, shellcheck, shfmt, markdown
  format, commit message, CLI design, code review, lint, formatting.
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

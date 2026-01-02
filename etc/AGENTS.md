# AGENTS.md

This document provides general rules and requirements for agents when making
changes to codebases.

## Markdown Quality

All Markdown files must be formatted and linted with `markdown-format`. Use
standard heading styles without additional formatting or ALL CAPS. Do not add
numbers to headings.

@./context/markdown.md

## Shell Script Quality

All shell scripts must be linted with `shellcheck` and formatted with `shfmt`.
Fish scripts use `fish_indent`. Scripts must have robust error handling.

@./context/shell.md

## Android Development

Tools for working with Android Jetpack libraries, ADB operations, APK analysis,
package management, Wear OS debugging, and emulator management.

@./context/android.md

## Git Operations

Agents must not commit changes automatically unless explicitly requested. Follow
the specified commit message format.

@./context/git.md

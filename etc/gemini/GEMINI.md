# GEMINI.md

This document provides general rules and requirements for agents such as gemini-cli when making changes to codebases.

## Markdown Formatting

When generating Markdown, pass it to the command `prettier --parser markdown` to ensure it's formatted correctly. This command will accept markdown from stdin, and write the formatted result to stdout.

## Git Commit Messages

When generating git commit messages, use the following structure (hard-wrap all body text at 80 characters):

- Subject line (imperative mood) of <=50 characters. Do add "feat" or "bug" to the subject line.
- Blank line.
- One of more paragraphs explaining what changed and why. Point form is acceptable.
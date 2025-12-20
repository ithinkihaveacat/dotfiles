# Git Operations

Agents must not commit changes automatically unless explicitly requested. When
tasked with modifying code (e.g., fixing a bug, adding a feature), apply the
changes to the working directory but refrain from committing them. Only proceed
with `git commit` when explicitly commanded to do so.

## Commit Messages

When generating git commit messages, use the following structure (hard-wrap all
body text at 80 characters):

- Subject line (imperative mood) of <=50 characters. Do not add "feat" or "bug"
  to the subject line.
- Blank line.
- One of more paragraphs explaining what changed and why. Point form is
  acceptable.

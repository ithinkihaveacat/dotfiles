# Command Index

<!-- markdownlint-disable MD013 -->

## Contents

- [review-with-agent](#review-with-agent)

## review-with-agent

The block below is `scripts/review-with-agent --help`, kept in sync by
`command-index-format`.

<!-- generated: ../scripts/review-with-agent --help -->

```text
Usage: review-with-agent --agent AGENT (--base BRANCH [--head REV] | --commit REV | --uncommitted) [OPTIONS]

Runs a code review through a CLI agent without starting an interactive session.

Options:
  --agent AGENT    Reviewer to run: codex, claude, or agy
  --base BRANCH    Review a branch or revision against this base
  --head REV       Head revision for --base (default: HEAD)
  --commit REV     Review the changes introduced by one commit
  --uncommitted    Review staged, unstaged, and untracked changes
  --synthesized    Bypass a native reviewer and invoke the portable skill
  --dry-run        Print the selected command without running it
  --help, -h       Display this help message and exit

Examples:
  review-with-agent --agent codex --base main
  review-with-agent --agent claude --commit HEAD
  review-with-agent --agent agy --uncommitted

Native review entry points are preferred when they support the target. The
synthesized fallback explicitly asks the reviewer to use the installed
agent-review skill and to perform the review itself without delegating again.
```

<!-- /generated -->

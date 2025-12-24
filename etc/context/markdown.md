# Markdown Formatting

## Formatting and Linting

All Markdown files, whether new or updated, _must_ be linted with
`markdownlint-cli2` and formatted with `prettier`. Use the `markdown-format`
command to apply both tools automatically.

To format a file in place:

```bash
markdown-format README.md
```

To format from stdin to stdout:

```bash
cat README.md | markdown-format > formatted.md
```

The `markdown-format` command runs `markdownlint-cli2` and may report warnings
it cannot automatically fix. You should endeavor to fix these manually.

**If `markdown-format` is not available in PATH:** You should install it or add
the `bin/` directory to your PATH. However, if this is not possible, you can
manually run the underlying tools directly, though this is not recommended:

```bash
# Lint and fix with markdownlint-cli2
markdownlint-cli2 --fix "**/*.md"

# Format with prettier
prettier --prose-wrap always --write <file(s)>
```

If `markdownlint-cli2` is not installed globally, you can run it via
`npx -y markdownlint-cli2 --fix "**/*.md"`. If `prettier` is not installed
globally, you can run it via `npx -y prettier --prose-wrap always --write <file(s)>`.

## Heading Style

When creating Markdown, do not add additional formatting to headings or use ALL
CAPS. For example, do not write "## **INTRODUCTION**"; instead, use the heading
format: "## Introduction". When modifying existing Markdown, copy existing
approaches.

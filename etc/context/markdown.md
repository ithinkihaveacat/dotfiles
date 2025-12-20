# Markdown Formatting

## Linting

All Markdown files, whether new or updated, _must_ be linted with
`markdownlint-cli2`. Any errors must be fixed before committing.

To lint Markdown files:

```bash
markdownlint-cli2 "**/*.md"
```

To automatically fix some errors:

```bash
markdownlint-cli2 --fix "**/*.md"
```

If `markdownlint-cli2` is not installed globally, you can run it via
`npx -y markdownlint-cli2 "**/*.md"`. If `npx` is not available, you can skip
the linting step.

## Heading Style

When creating Markdown, do not add additional formatting to headings or use ALL
CAPS. For example, do not write "## **INTRODUCTION**"; instead, use the heading
format: "## Introduction". When modifying existing Markdown, copy existing
approaches.

## Automatic Formatting

All Markdown files, whether new or updated, _must_ be formatted by `prettier`.
There is a `.prettierrc` file in the root directory that applies the formatting
rules.

To format Markdown files, use the command `prettier --write <file(s)>`. This
command will edit files in place.

If `prettier` is not installed globally, you can run it via
`npx -y prettier@latest --write <file(s)>`. If `npx` is not available, you can
skip the prettier step.

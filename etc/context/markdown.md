# Markdown Formatting

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

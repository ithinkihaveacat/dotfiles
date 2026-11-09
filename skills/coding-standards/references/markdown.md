# Markdown Formatting

## Formatting and Linting

All Markdown files, whether new or updated, _must_ be linted and formatted. Use
the `scripts/markdown-format` script to apply both tools automatically. You can
also pass the `--check` option to verify formatting without modifying files
(e.g. for lint checks).

To format a file in place:

```bash
scripts/markdown-format README.md
```

To format from stdin to stdout:

```bash
cat README.md | scripts/markdown-format > formatted.md
```

## Heading Style

When creating or updating Markdown, use clean ATX headings (e.g.,
`## Introduction`) without manual bolding, ALL CAPS, or section numbers on
topical headings (numbering topical sections adds renumbering churn when
sections move or are edited). Two exceptions apply:

- **Existing documents:** Maintain consistency with existing styles in a
  document, and do not introduce numbers or extra formatting into documents that
  don't already have them.
- **Sequential steps:** Numbered headings (e.g., `### 1. ...` or
  `### Step 1: ...`) are acceptable when headings denote strictly ordered steps
  rather than general topic sections (keep `TODO.md` item headings unnumbered).

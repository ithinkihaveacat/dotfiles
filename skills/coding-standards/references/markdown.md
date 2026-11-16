# Markdown Formatting

## Formatting and Linting

All Markdown files, whether new or updated, _must_ be formatted with
`scripts/markdown-format` (`mdformat` with GFM and `ruamel.yaml` frontmatter
wrapping). Pass `--check` to verify formatting without modifying files, as CI
does. (`.markdownlint-cli2.jsonc` provides optional editor lint configuration
and is not run by `markdown-format` or CI.)

To format a file or directory recursively in place:

```bash
scripts/markdown-format README.md docs/
```

To format from stdin to stdout:

```bash
scripts/markdown-format < README.md > formatted.md
```

## Symbols and Mathematical Notation (Unicode Only)

Keep repository Markdown strictly Unicode-only for arrows, operators, relations,
Greek letters, and inline notation:

- Use plain Unicode symbols (`→`, `←`, `≤`, `≥`, `≠`, `×`, `±`, `Δ`) and inline
  code spans (`` `O(n log n)` ``, `` `x_i` ``) rather than LaTeX/KaTeX `$...$`
  or `$$...$$` math blocks.
- `scripts/markdown-format` runs plain GFM `mdformat` without a dollar-math
  extension, so backslashes, underscores, braces, and percent signs inside
  `$...$` are treated as ordinary Markdown prose and escaped or reflowed.
- If a multi-line equation cannot be expressed clearly with Unicode and code
  spans, place it inside a fenced code block (```` ```text ````).

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

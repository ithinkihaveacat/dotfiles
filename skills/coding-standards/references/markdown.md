# Markdown Formatting

## Formatting and Linting

All Markdown files, whether new or updated, _must_ be linted and formatted. Use
the `markdown-format` command to apply both tools automatically.

To format a file in place:

```bash
markdown-format README.md
```

To format from stdin to stdout:

```bash
cat README.md | markdown-format > formatted.md
```

## Heading Style

When creating or updating Markdown, use standard heading styles (e.g., "##
Introduction") without additional formatting (like bolding), ALL CAPS, or
numbers. Maintain consistency with existing styles in a document, but do not
introduce numbers or extra formatting into documents that don't already have
them.

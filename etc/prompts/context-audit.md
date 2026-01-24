# Prompt: Audit a Context Topic

Perform a periodic audit of a topic in the `context` command. This audit ensures
the topic output remains comprehensive, accurate, and reflects the latest
authoritative information about the subject.

## How the Context Command Works

The `context` command (`bin/context`) generates aggregated documentation for
specific topics. Each topic is a bash function that gathers content from
multiple sources and outputs it in XML format suitable for AI agent consumption.

### Output Format

The output contains `<entry>` elements, each with:

- `<command>`: The attributed source of the data (e.g., a curl command)
- `<output>`: The actual content

**Important**: The `<command>` element indicates the _apparent_ source of the
data, not necessarily how it was actually retrieved. This is by design—it
provides provenance information for the content while allowing efficient batch
retrieval behind the scenes.

### Source Patterns

Topics use several patterns to gather content:

**Repository fetches with attributed URLs**: Download entire repos locally, then
iterate through files while attributing them to their raw GitHub URLs.

```bash
repo=$(fetch "github://owner/repo")
find "$repo/docs" -name "*.md" -type f | while read -r file; do
  local rel="${file#"$repo"/}"
  # The display command shows the URL, but we actually read from local disk
  run "curl -s 'https://raw.githubusercontent.com/owner/repo/main/$rel'" cat "$file"
done
```

This pattern efficiently downloads a repository once, then presents each file as
if it were fetched individually. The attributed URL serves as the source of
truth for where the content originated.

**Direct URL fetches**: Download individual pages directly.

```bash
run "curl -sfS 'https://example.com/docs/page.md'" \
  curl -sfS 'https://example.com/docs/page.md'
```

Here the display command and actual command are the same.

**Published URL comments**: When content has both a raw/markdown URL and an HTML
published URL, the comment indicates where users can view it:

```bash
run "curl -sfS 'https://x.io/page.md'  # published to https://x.io/page" \
  curl -sfS 'https://x.io/page.md'
```

### Available Topics

Run `context --list` to see available topics. Each topic has a description in
the TOPICS array in `bin/context`.

## Goal

Review and update a specific topic to ensure:

1. All sources are accessible and return expected content
2. Content hasn't moved, been deprecated, or significantly changed
3. No new authoritative content is missing
4. Published URL comments are accurate
5. The topic description remains accurate

This audit should be performed periodically or when you suspect documentation
has changed significantly.

## Phase 1: Examine Current Output

### 1.1 Run the Topic

Generate the current output and examine its structure:

```bash
context <topic-name> 2>/dev/null | grep '<command>'
```

This shows all the attributed sources. Review the list to understand:

- What repositories are being fetched
- What individual URLs are being downloaded
- What published URLs are referenced

### 1.2 Read the Topic Function

Read the topic function in `bin/context` to understand how it gathers content:

```bash
grep -A 50 'topic_<name>()' bin/context
```

Note the fetch patterns, URL lists, and any filtering or processing applied.
Understanding the actual retrieval method helps when debugging issues.

## Phase 2: Verify Existing Sources

For each source in the topic, verify it remains valid and appropriate.

### 2.1 Check URL Accessibility

Verify that attributed URLs are accessible:

```bash
# Test individual URLs
curl -sfS 'https://example.com/docs/page.md' > /dev/null && echo "OK" || echo "FAILED"
```

For repository fetches, verify the repository exists and the branch is correct.

Common issues:

- 404 errors (page moved or deleted)
- Redirects to different locations
- Repository renamed or archived
- Branch name changed (e.g., `master` to `main`)

### 2.2 Verify Content Relevance

For each source, briefly check that the content is still relevant:

- Does the page still cover the expected topic?
- Has the content been deprecated or superseded?
- Is there a notice about the content moving elsewhere?

Use `WebFetch` to examine page content when needed.

### 2.3 Check Published URL Comments

For sources with `# published to` comments, verify:

- The published URL is correct and accessible
- The relationship between fetch URL and published URL is accurate

## Phase 3: Search for New Content

The most challenging part of an audit is finding content that should be added.
This requires investigation and judgment.

### 3.1 Check for Documentation Changes

Use web search to find recent changes to the topic's documentation:

```text
"<topic name>" documentation 2026
"<product name>" changelog 2026
```

Look for:

- New documentation pages
- Restructured documentation sites
- New best practices guides
- Specification updates

### 3.2 Explore Repository Structures

For topics that fetch from repositories, check if the repository structure has
changed:

- New documentation directories
- Additional file types (e.g., `.mdx` files added alongside `.md`)
- New branches with updated content

### 3.3 Check Related Documentation

For topics covering standards or specifications:

- Has the standard been adopted by new tools?
- Are there new official implementations or examples?
- Has the specification version changed?

### 3.4 Review Sibling Content

If a topic fetches `docs/overview.md`, check if related files exist:

- `docs/best-practices.md`
- `docs/quickstart.md`
- `docs/reference.md`

Documentation sites often add new pages that follow existing patterns.

## Phase 4: Propose Additions

If you identify new content in Phase 3 that should be added:

1. **List the files/URLs**: Provide the specific filenames or URLs you intend to add.
2. **Inspect the content**: Briefly describe what these files contain and why they are relevant.
3. **Request Confirmation**: Ask the user if they want these files added to the topic.

*Note: You do not need to ask for confirmation to fix broken URLs or apply minor corrections to existing sources. Proceed with those fixes in Phase 5.*

## Phase 5: Make Updates

Apply necessary changes to the topic function in `bin/context`.

### 5.1 Add New Sources

When adding new URLs:

1. Use the same pattern as existing sources in the topic
2. Include `# published to` comments for markdown files with HTML equivalents
3. Add appropriate comments explaining the source

### 5.2 Update Existing Sources

When URLs have moved:

1. Update to the new location
2. Verify the content is equivalent
3. Update any published URL comments

### 5.3 Remove Obsolete Sources

When content is no longer available or relevant:

1. Remove the URL from the topic
2. Consider whether replacement content exists

### 5.4 Update Topic Description

If the scope of the topic has changed, update its description in the TOPICS
array.

### 5.5 Validate Changes

After making changes, run the topic and verify:

```bash
# Check for errors
context <topic-name> 2>&1 | head -20

# Verify all sources are fetched
context <topic-name> 2>/dev/null | grep '<command>'
```

Run `shellcheck` on `bin/context` to catch any syntax errors.

## Output

After completing the audit, provide a summary:

1. **Topic audited**: Name and description
2. **Sources verified**: Count of URLs/repos checked
3. **Issues found**: List of problems discovered
4. **Changes made**: List of modifications
5. **New sources added**: URLs added with justification
6. **Recommendations**: Any changes needing human decision

## Example Audit Findings

**Minor adjustments (make automatically):**

- URL returns 404, replacement found at new location
- Published URL comment missing or incorrect
- Branch name changed from `master` to `main`

**Requires discussion (report but don't change):**

- Major restructuring of documentation site
- Content deprecated with no clear replacement
- Significant scope change (should topic be split or merged?)
- New authoritative source with overlapping content
- New documentation page added to existing repository

## Checklist

Before completing the audit:

- [ ] Topic output generated and examined
- [ ] All URLs tested for accessibility
- [ ] Content relevance verified
- [ ] Web search performed for new documentation
- [ ] Repository structures checked for changes
- [ ] Related/sibling content checked
- [ ] Proposed additions confirmed by user
- [ ] Changes applied (if any)
- [ ] Topic runs without errors after changes
- [ ] Summary provided

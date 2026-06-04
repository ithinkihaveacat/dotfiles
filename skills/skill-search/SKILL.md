---
name: skill-search
description: Search for relevant agent skills based on a problem description, goal, or repository context. Use this when you are unsure which skills to use, or want to bootstrap a workspace with sensible defaults.
---

# Skill Search

This skill helps you discover other skills that are relevant to your current
task.

## How to use it

You can invoke the search tool via the script `skill-search` (if installed in
your PATH) or directly via the skill path:

```bash
skill-search "PROBLEM_DESCRIPTION_OR_GOAL" [OPTIONS]
# Or:
.agents/skills/skill-search/scripts/skill-search "PROBLEM_DESCRIPTION_OR_GOAL" [OPTIONS]
```

### Options:

- `--search-dirs PATHS`: Colon-separated extra paths to search for skills.
  Overrides `SKILL_SOURCE_DIRS`.
- `--dry-run`: Show the gathered skills and prompt without calling the API.

### Examples:

```bash
# Search for skills to help with python style issues
skill-search "I need to format my python code and run tests"
```

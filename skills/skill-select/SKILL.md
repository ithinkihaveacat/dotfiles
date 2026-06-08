---
name: skill-select
description: Discover and select relevant agent skills based on a problem description, goal, or repository context. Use this to determine which skills apply to a workspace, or when you are unsure which tools are best suited for your current task.
---

# Skill Select & Skill Manager

This skill provides discovery, selection, and management of agent skills for your workspace. It consists of two primary tools:
1.  **`skill-select`**: The discovery engine. It analyzes your workspace to suggest sensible default skills, or uses LLM-based selection when task context is provided.
2.  **`skill`**: The workspace manager. It installs and tracks skills in your workspace, automatically adapting to your environment (Git, Perforce, or Unmanaged).

---

## 1. Discovering Skills (`skill-select`)

Invoke the selection tool via `skill-select` (symlinked in `bin/`):

```bash
skill-select [DIR] [OPTIONS]
```

### Options

*   `--context TEXT`: A comprehensive, self-contained explanation of your task to guide LLM-based selection.
*   `--search-dirs PATHS`: Colon-separated extra paths to search for skills, overriding `SKILL_SOURCE_DIRS`.
*   `--catalog`: Print the full catalog of available skills and exit.
*   `--json`: Emit structured JSON output instead of formatted text.

---

## 2. Managing Skills (`skill`)

The `skill` tool (symlinked in `bin/`) manages agent skills as untracked symlinks in your workspace. It automatically detects your environment and applies the correct tracking and ignoring mechanism.

```bash
skill <command> [arguments]
```

### Supported Environments

*   **Git Repositories**: Links skills under `.agents/skills/` and `.claude/skills/`. It automatically updates `.git/info/exclude` to keep your git status clean without dirtying the shared `.gitignore`.
*   **Perforce Workspaces**: 
    *   *Centralized Layout*: Links skills under `configs/users/<username>/_agents/skills/` and tracks them in `.p4-skills-managed` in that directory. This is typically used in environments with centralized user configurations.
    *   *Standard Layout*: Links skills under `.agents/skills/` and tracks them in `.p4-skills-managed` at the client root.
*   **Unmanaged Directories**: Works in plain directories without VCS. Links skills under `.agents/skills/` and `.claude/skills/` and tracks them in a local `.skills-managed` file.

### Commands

*   **`apply`**: Provision recommended skills for this workspace via `skill-select` (idempotent).
*   **`suggest`**: Print recommendations without installing them.
*   **`add SPEC...`**: Add a skill (a local path or a registered catalog entry).
*   **`remove NAME...`** (alias: **`rm`**): Remove a managed skill.
*   **`list`**: List skills currently managed in this workspace.
*   **`update SPEC...`**: Re-fetch a registered catalog entry (`--all` for all, `--catalog` for catalog index).
*   **`clean`**: Remove all managed skills and clear tracking records.
*   **`doctor`**: Diagnose drift between desired and on-disk skills (read-only).
*   **`catalog`**: List all registered skills and their sources.
*   **`resolve NAME`**: Print the source path a skill name would resolve to.

---

## Usage Examples

### Default Discovery & Apply (Recommended for new workspaces)
Analyze the current directory and automatically install the recommended skills:

```bash
skill apply
```

### Targeted Discovery (With Context)
If you have a specific task or hit a roadblock, ask for recommendations based on your situation:

```bash
skill suggest --context "Goal: Implement a Wear OS tile in Kotlin. Emulator keeps crashing with OAuth errors."
```

### Manually Adding a Skill
Add a specific skill from the catalog or a local path:

```bash
skill add coding-standards
skill add /path/to/custom-skill
```

### Listing Managed Skills
See what is currently active in your workspace:

```bash
skill list
```

### Cleaning Up
Remove all installed skills and restore the workspace to its original state:

```bash
skill clean
```

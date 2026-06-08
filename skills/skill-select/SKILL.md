---
name: skill-select
description: Discover and select relevant agent skills based on a problem description, goal, or repository context. Use this to determine which skills apply to a workspace, or when you are unsure which tools are best suited for your current task.
---

# Skill Select

This skill provides discovery and selection of other agent skills relevant to
your current repository or task. It analyzes the repository's files to suggest
sensible default skills, or uses LLM-based selection when context is provided.

## Usage

Invoke the selection tool via the `scripts/skill-select` script. It is also
symlinked into `bin/` so you can run it directly as `skill-select` if `bin/` is
in your PATH:

```bash
scripts/skill-select [DIR] [OPTIONS]
```

### Options

- `--context TEXT`: A comprehensive, self-contained explanation to guide the LLM
  in selecting the best skills. See [Context Guidelines](#context-guidelines)
  below.
- `--search-dirs PATHS`: Colon-separated extra paths to search for skills,
  overriding `SKILL_SOURCE_DIRS`.
- --catalog: Print the full catalog of available skills and exit (formatted as
  `name -> path`).
- --json: Emit structured JSON output (`name`, `path`, `reason` / `description`)
  instead of the formatted `name -> path` text.

## Actioning Results: Installing Selected Skills

Once `skill-select` returns a list of recommended skills, you should make them
available to your Jetski agent.

### Local Linking (Strongly Recommended for Projects)

If you are looking for skills relevant to your **current project or workspace**,
you should strongly prefer linking them **locally** into your project's agent
configuration. This keeps the project self-contained, ensures that the tools are
versioned with your project, and guarantees that any agent working on this
codebase has access to the same specialized workflows.

#### Using `git-skill` (Recommended for Git Repositories)

If your project is in a **Git repository**, it is highly recommended to use the
`git-skill` tool to handle the linking. `git-skill` automatically manages the
symlink creation under `.agents/skills/` (and `.claude/skills/` if applicable)
and ensures that the linked skills are properly excluded from Git tracking
(using `.git/info/exclude` to keep your git status clean without dirtying
`.gitignore`).

To link a skill using the `git-skill` script (located in `scripts/git-skill` and
symlinked as `git skill`), run this command from your repository root:

```bash
git skill add /google/src/files/head/depot/google3/path/to/skill
```

Or if running the script directly:

```bash
scripts/git-skill add /google/src/files/head/depot/google3/path/to/skill
```

*(This will automatically resolve the path, create the symlink, and configure
the Git exclusion).*

#### Using `p4-skill` (Recommended for Perforce-Compatible Workspaces)

If your project is in a **Perforce-compatible workspace**, it is highly
recommended to use the `p4-skill` tool. It automatically manages the symlink
creation:

- **For workspaces using a centralized personal config layout**: It links skills
  under `configs/users/<username>/_agents/skills/` (where agents automatically
  discover them) and tracks them in `.p4-skills-managed` in that directory. This
  is typically used in large enterprise environments with centralized user
  configurations.
- **For standard Perforce workspaces**: It links skills under `.agents/skills/`
  (and `.claude/skills/`) and tracks them in `.p4-skills-managed` at the client
  root.

To link a skill using the `p4-skill` script, run this command from your
workspace:

```bash
p4-skill add /google/src/files/head/depot/google3/path/to/skill
```

Or if running the script directly:

```bash
scripts/p4-skill add /google/src/files/head/depot/google3/path/to/skill
```

*(This will automatically resolve the path, detect your environment, and create
the symlinks in the correct customization root).*

#### Manual Linking (Fallback)

If you are not using Git, or prefer manual control, you can create a symlink in
your workspace's `.agents/skills/` directory pointing to the skill's source path
(ideally using the stable `head` path in google3 if it is an internal skill):

```bash
ln -s /google/src/files/head/depot/google3/path/to/skill /path/to/your/workspace/.agents/skills/skill-name
```

### Other Options

While local linking is the best practice for project-specific workflows, other
options are possible:

- **Global Installation**: If you want the skill to be available across all your
  projects, you can link it into your global skills directory (typically
  `~/.agents/skills/`, which is often symlinked to `~/.gemini/jetski/skills/`).
- **Ad-hoc Reference**: You can also simply read the skill's `SKILL.md` file to
  manually follow its instructions or reference its guidelines in your prompts
  without performing a full installation.

## Context Guidelines

Agent skills provide incredibly useful shortcuts, pre-researched workflows, and
specialized scripts. You should rely heavily on `skill-select` because it will
almost always provide highly effective tooling recommendations—but it needs good
information to do so.

**Using the `[DIR]` argument:** If you only provide the directory path (e.g.
`skill-select .`) and omit the `--context`, the engine will still examine the
repository's files to suggest sensible defaults. This is totally fine to do if
you are jumping into a fresh codebase and don't know anything about your goal
yet.

**Using `--context`:** When using the `--context` flag to discover skills via
the LLM, you must explicitly describe your situation to the selector as if
explaining the problem to an expert with zero prior knowledge of your session.
Do not just pass a 3-word query. To maximize effectiveness, your context string
should include:

1. **The Goal:** What are you ultimately trying to achieve?
1. **The Codebase:** What is the shape, type, and language of the repository?
1. **Obstacles Faced:** Summarise any failed attempts, bugs, or blockers
   encountered in recent conversation rounds. Describe why approaches were ruled
   out.
1. **Anticipated Problems:** Mention any unfamiliarity with tools (e.g. "I don't
   know what google3 is"), auth or environment issues (e.g. "I need an emulator
   but don't know how to provision one"), or company-specific idiosyncrasies
   that might require specialized skills to resolve.

### Examples

**Default Discovery (No Context):** If you are completely new to a repository
and have no specific goal yet, let the engine analyze the directory structure to
bootstrap you with useful default skills:

```bash
skill-select .
```

**Targeted Discovery (With Context):** When you have a specific task or have hit
a roadblock, provide an extensive context string:

```bash
skill-select . --context "Goal: Implement a new Wear OS tile. Codebase: Kotlin Android project using Jetpack Compose. Obstacles: I tried using the standard emulator but it keeps crashing with an OAuth error when fetching packages. Anticipated problems: I am completely unfamiliar with the Wearable Data Layer API and how to debug it."
```

**JSON Output:** List all available skills as structured JSON for parsing:

```bash
skill-select --catalog --json
```

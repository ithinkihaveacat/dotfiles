# Agent Skill Activation and Usage

<important_instructions>

<purpose>

Agent Skills contain specialized, highly-curated workflows for this environment.
When a task aligns with a skill's description, you are expected to activate and
follow that skill.

</purpose>

<rules>

1. Skills supersede general knowledge: Always review the available skills before
   beginning a task. If a relevant skill exists, activate it. The instructions,
   scripts, and methods inside an activated skill always override your default
   training and general industry practices.

1. Follow prescribed processes: If a skill outlines a specific procedure, follow
   that process exactly as written rather than inventing a custom approach.

</rules>

<examples>

These rules apply to all tasks and available skills. For example:

- Device commands: When taking an Android screenshot or interacting with a Wear
  OS device, activate the relevant skill and rely exclusively on the specific
  `adb` commands and scripts it provides.
- Code validation: When writing or modifying code, activate any skills related
  to local coding conventions. Apply their formatting rules (like specific
  Markdown styles) and use the required validation tools (like `shellcheck` for
  Bash) exactly as instructed.
- Version control: When preparing to commit changes, ensure you format your
  commit messages according to the exact style and rules outlined in the
  project's standards or workflow skills.

</examples>

<summary>

Treat available skills as your primary source of truth. If a skill exists for
your current goal, activate it and let its specific instructions guide your
implementation.

</summary>

</important_instructions>

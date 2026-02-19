# Prompt: Audit and Update Agent Skills

Perform a periodic audit of the Agent Skills in this repository. This audit
ensures skills remain aligned with the latest specification, best practices, and
the scripts they wrap.

## Artifact Relationships

Understanding how the pieces fit together:

- **Skills** (`skills/*/SKILL.md`): The actual skill files used by agents. These
  are the primary deliverable.

- **Prompts** (`prompts/*-skill.md`): Instructions that were used to generate
  each skill initially. A capable agent following a prompt should produce a
  skill very similar to the current one on disk. Prompts encode decisions and
  conventions that may not be obvious from the specification alone.

- **Specification** (`context skills` output): The current Agent Skills standard
  and best practices. This is the external authority on how skills should be
  structured.

The prompts serve as both a regeneration mechanism and a sanity check. If the
specification suggests a change but the prompt contradicts it, pause and
consider carefully—the prompt may encode a deliberate decision or a convention
specific to these skills.

## Goal

Review and update all skills in `skills/` to ensure:

1. Skills accurately document the scripts they wrap
2. Skills follow the current Agent Skills specification and best practices
3. Prompts remain capable of regenerating the current skills
4. Prompts and specification are not in unexamined conflict

This audit should be performed monthly or after significant changes to either
the skills specification or the underlying scripts.

## Phase 1: Gather Context

### 1.1 Read the Latest Documentation

Run `context skills` to collect the current Agent Skills documentation. This
aggregates:

- The Agent Skills specification (agentskills.io)
- Best practices for skill authoring
- Claude Code skills documentation

Review the collected documentation carefully. Look for any differences from what
you already know about the specification—changelogs, new fields, updated
recommendations, or changed guidance. The documentation may not have explicit
dates, but differences from your prior knowledge indicate recent changes.

### 1.2 Inventory Skills and Prompts

For each skill in `skills/`:

1. Read the `SKILL.md` file
2. List all scripts in the `scripts/` subdirectory
3. Read the corresponding prompt in `prompts/<skill-name>-skill.md`

Keep the prompt in mind as you evaluate the skill—it represents the intended
design and any deliberate choices made when the skill was created.

## Phase 2: Validate Scripts Match Skills

For each skill, verify bidirectional consistency between the skill documentation
and the actual scripts.

### 2.1 Scripts Exist

Check that every script referenced in `SKILL.md` (in Quick Start, Script Index,
or body text) exists in `scripts/`:

```bash
# Example: List scripts in a skill
ls -la skills/adb/scripts/
```

If a script is referenced but doesn't exist, either:

- Restore/add the missing script file under `skills/<skill>/scripts/`
- Ensure a matching `bin/` symlink exists
- Remove the reference (if the script was deleted)

### 2.2 Scripts Are Documented

Check that every script in `scripts/` is documented in `SKILL.md` and
`references/command-index.md`:

```bash
# Compare scripts to documentation
ls skills/adb/scripts/ | sort > /tmp/scripts.txt
grep -oE 'scripts/[a-z0-9-]+' skills/adb/SKILL.md \
  | sed 's|scripts/||' | sort -u > /tmp/documented.txt
diff /tmp/scripts.txt /tmp/documented.txt
```

If a script exists but isn't documented:

- Add it to the appropriate section in `SKILL.md`
- Add detailed documentation to `references/command-index.md`

**For monolithic scripts (like `jetpack` or `emumanager`):** Check that all
available subcommands are documented. Run the script with `--help` to see the
full list, and verify each one is covered in `SKILL.md` and
`references/command-index.md`.

### 2.3 Check for New Scripts

Look for new scripts in `skills/*/scripts/` (canonical sources) and ensure they
are reflected consistently in both skills and `bin/` entrypoints:

- `skills/adb/scripts/adb-*` and `skills/adb/scripts/wearableservice-*` → adb
  skill
- `skills/jetpack/scripts/jetpack` subcommands → jetpack skill
- AI analysis scripts → ai-analysis skill
- `skills/emumanager/scripts/emumanager` subcommands → emumanager skill

For each new script found:

1. Add it to the appropriate `scripts/` directory as a real executable file
2. Add/update the corresponding `bin/<script>` symlink
3. Add documentation to `SKILL.md` and `references/command-index.md`
4. Update the generating prompt if needed

### 2.4 Check Script Functionality

For scripts that have changed significantly, verify the skill documentation
still accurately describes their behavior:

```bash
# Check script help
skills/adb/scripts/adb-screenshot --help
```

Update skill documentation if script capabilities have changed.

## Phase 3: Validate Skills Against Specification

Compare each skill against the current Agent Skills specification and best
practices (from `context skills` output).

Use your judgment to identify gaps or inconsistencies. The specification defines
requirements for frontmatter fields, description quality, body structure, and
reference files. Check that each skill adheres to the current requirements.

Pay particular attention to:

- Frontmatter field requirements and constraints
- Description conventions (person, content, discovery keywords)
- Body structure recommendations (length, sections, progressive disclosure)
- Reference file expectations

**Specific check for progressive disclosure:** Verify that `SKILL.md` explicitly
links to every file in the `references/` directory (e.g., in a "Reference
Material" section). This ensures agents can discover these files without needing
to list the directory.

**Before making changes based on the specification**, check whether the skill's
generating prompt addresses the same topic. If the prompt specifies something
different from the current spec, this may indicate a deliberate choice. Consider
whether:

- The prompt should be updated to match the new spec guidance
- The difference is intentional and should be preserved
- The conflict needs human input to resolve

## Phase 4: Validate Skills Match Prompts

The prompts in `prompts/` serve two purposes:

1. **Regeneration**: If a skill needs to be rebuilt from scratch, the prompt
   should produce something very close to the current skill.
2. **Validation**: The prompt represents accumulated decisions about how these
   skills should be structured. It's a check against blindly applying spec
   changes.

Read both the skill and its prompt. Consider whether an agent following the
prompt would produce something substantially similar to the current skill. The
prompt doesn't need to specify every detail—a capable agent will make reasonable
decisions based on the scripts and specification. However, the prompt should
capture:

- The current structure and sections of the skill
- Conventions specific to these skills (e.g., "Triggers:" format)
- Guidance that has proven necessary based on past experience

**Keeping prompts in sync:**

- If you updated a skill in Phase 3, update the prompt to reflect those changes
- If the skill has evolved in ways the prompt doesn't capture, update the prompt
- If the prompt specifies approaches no longer used, update it to match reality

The goal is that regenerating a skill from its prompt would produce the current
skill (or something very close to it).

## Phase 5: Make Updates

Apply necessary changes, keeping modifications minimal and focused.

### 5.1 Update Skills

For each skill needing updates:

1. Make the minimal edit to address the issue
2. Run `markdown-format` on modified files
3. Verify the skill still reads coherently

### 5.2 Update Prompts

For each prompt needing updates:

1. Update the prompt to reflect current skill structure and conventions
2. Run `markdown-format` on modified files

Do not commit changes automatically. Present the changes for review.

## Output

After completing the audit, provide a summary:

1. **Skills audited**: List of skills reviewed
2. **Scripts validated**: Count of scripts checked
3. **Issues found**: List of discrepancies discovered
4. **Changes made**: List of files modified
5. **Recommendations**: Any larger changes that need human decision

## Example Audit Findings

**Minor adjustments (make automatically):**

- Missing "Triggers:" suffix in description
- Script location not clarified in "Use Scripts First" section
- New script added to `skills/*/scripts/` but not documented in skill
- Prompt missing guidance that has proven necessary

**Requires discussion (report but don't change):**

- Major restructuring needed due to spec changes
- Script removed from `skills/*/scripts/` but still documented
- Skill scope unclear (should script X be in skill Y?)
- Specification recommends X but prompt explicitly specifies Y

## Checklist

Before completing the audit:

- [ ] All skills in `skills/` reviewed
- [ ] All scripts in each skill's `scripts/` verified
- [ ] All skills compared against latest specification
- [ ] All skills compared against their generating prompts
- [ ] Modified files formatted with `markdown-format`
- [ ] Summary provided

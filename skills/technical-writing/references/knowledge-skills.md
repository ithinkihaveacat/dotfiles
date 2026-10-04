# Knowledge Skill Guidelines

This guide covers authoring, reorganizing, and maintaining knowledge skills. A
knowledge skill records facts about particular things the user owns, operates,
or deals with: machines, services, accounts, domains, devices, households,
people, and places. Any agent in any workspace can load it by topic. Skills that
teach how to do a class of task are capability skills; see
[Capability Skill Guidelines](capability-skills.md).

## Intent and Audience

- **Goal:** Keep facts current, findable, and cheap to load. An agent should
  reach the one fact it needs without reading the whole skill.
- **Audience:** AI agents (as primary readers) and the owner (as maintainer and
  occasional reader).
- **Scope:** Knowledge skills are almost always strictly personal and live in a
  private or employer overlay, never a public repository. They are exempt from
  the portability rules for reusable skills, but any bundled scripts follow
  them.

## What Belongs in a Knowledge Skill

A fact belongs in a knowledge skill when it is true of the thing regardless of
any particular project or task, and more than one piece of work may need it.

| Belongs here                                                 | Belongs elsewhere                                       |
| ------------------------------------------------------------ | ------------------------------------------------------- |
| What a machine or service is, where it runs, how to reach it | How a codebase works (its own repository)               |
| Where a credential is stored, how to renew or rotate it      | The credential's value (a secrets store)                |
| Accounts, registrars, providers, and their recovery paths    | Work in progress and plans (a project tracker)          |
| People, households, and places, to the extent needed         | The history of how things changed (version control)     |
| Standing preferences that apply across many requests         | Decisions specific to one project (that project's docs) |

## Structure

Organize by entity, so each lookup lands on one small file:

- **`SKILL.md` is an index.** State the scope in a sentence or two, the privacy
  policy, a quick-access table for the most frequent lookups, and a list of
  entities linking to their reference files. Detail belongs in the references.
  When `SKILL.md` grows beyond a short index (roughly 150 lines), move sections
  out.
- **`references/` holds one file per entity**, or per small group of similar
  entities (one per machine, one per provider, one per street). Name the file
  after the entity and open it with a one-line statement of what the entity is.
- **Procedures that span entities** (provisioning a server, rotating every key
  of one kind) get their own reference file rather than being split across
  entity files.
- **`resources/`** holds verbatim captured material, such as configuration files
  copied from a host. Record where each file came from (host and path).
- **`scripts/`** holds automation, written to the capability skill rules. List
  destructive scripts in `permissions/unsafe`.

Within an entity file, keep three kinds of content distinct:

- **Inventory:** what exists and its properties. Tables suit this well.
- **Procedures:** how to do something to the entity (set up, renew, recover,
  rebuild), as numbered steps with their failure modes.
- **Rationale:** why it is set up this way. Keep a short reason next to the fact
  it explains. When a rationale runs to several paragraphs or governs several
  entities, give it its own section and link to it.

## Current State, Not History

- **Rewrite facts in place.** Version control keeps earlier states. Avoid
  changelog sections, "Update:" paragraphs, and "previously…" trails.
- **Keep a former state only while it still matters operationally**, for example
  a fallback copy of data on a retired host.
- **Do not add administrative metadata** such as `updated:` or `last_reviewed:`
  fields; version control records when a file changed.
- **Date an observation when its age affects trust in it**: "moved in Feb 2026",
  "the console offered no expiry option (2026-07)". Expiry and renewal dates are
  facts in their own right and always belong.

## Uncertainty

- **Mark unconfirmed facts explicitly and consistently**, for example
  "(unconfirmed)", with the source where useful: "(per the street group chat)".
  A bare `?` is easy to miss and ambiguous.
- **Do not present an inference as a fact.** Record what was observed and,
  separately, what it suggests.
- **Correct wrong facts in place** rather than appending a correction.

## Privacy and Sensitivity

- **State what the skill must never contain** in `SKILL.md`, for example secret
  values, full identity document numbers, or exact dates of birth. Record where
  a secret is stored, not the secret.
- **Choose the repository by sensitivity:** personal facts go in the private
  overlay, employer facts in the employer overlay, and neither in a public
  repository.
- **Record only what the purpose needs about other people.** A neighbour's name
  and household help with remembering who is who; sensitive details such as
  health or finances rarely serve that purpose.

## Description and Scope Boundaries

- **The description lists the entities and trigger terms**: hostnames, provider
  names, people's names, street names. Knowledge skills load by topic, so a fact
  whose terms are missing from the description is effectively hidden.
- **Keep one domain per skill.** Split a skill when its parts load on disjoint
  triggers (travel profiles, shopping preferences, and neighbours rarely share a
  request). Keep parts together when the same lookups routinely need both.

## Relationship to Projects and Other Sources

- **One owner per fact; everywhere else links.** A project document, code
  repository, or other skill that depends on a fact names the knowledge skill
  and the topic rather than copying the fact. Copies drift; pointers go stale
  more slowly.
- **A knowledge skill can be the artifact of a project.** When a system has
  enough ongoing work to track, a project tracker can hold the work while the
  knowledge skill holds the current description. Completing a task then includes
  updating the skill to the new current state.

## Maintenance and Drift

- **Reality wins.** When a skill disagrees with the system or person it
  describes, the skill is wrong. Check volatile facts against the source when it
  is cheap to do so (for example, list live hosts before relying on a recorded
  address) and correct the skill.
- **Repair opportunistically.** When you touch a file and find content in the
  wrong place, move it to its owner. A large reorganization is rarely needed to
  make progress.
- **Reorganize without changing meaning.** Moving content between files should
  preserve every fact; check internal links afterwards.

## Summary Checklist

- [ ] `SKILL.md` is a short index: scope, privacy policy, quick access, and
  links to entity references.
- [ ] Each reference file covers one entity or a small group of similar
  entities, with inventory, procedures, and rationale kept distinct.
- [ ] Content describes current state; no changelogs or administrative metadata.
- [ ] Unconfirmed facts are marked consistently.
- [ ] No secret values or prohibited personal data; the skill lives in an
  overlay that matches its sensitivity.
- [ ] The description names the entities and trigger terms covered.
- [ ] Facts owned elsewhere are linked, not copied.

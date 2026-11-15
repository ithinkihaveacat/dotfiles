# taskgo Model

Read this when you decide where a fact or file belongs, create or restructure a
project, write a project README or an ADR, or set scheduling fields
(`blocked_by`, `wait_for`, `due`, `stale_after`).

## Control and Artifact Repositories

A **control repository** (also called the control repo or tracker) holds private
task tracking, plans, decisions, and project working files for one or more
external **artifact repositories**. Artifact repositories hold the product code,
libraries, and their tests. Their commits never carry tracker metadata.
Reference or fetch very large artifacts (cloned repositories, heavy binary test
data) on demand rather than checking them into the control repository.

A project grows only as far as it needs. A light project is `README.md`,
`STATUS.md`, and `tasks/`; a long initiative adds `PLAN.md`, `decisions/`,
`references/`, and so on. Unsorted notes go in the root `INBOX.md`.

## Directory Layout

```text
AGENTS.md          # taskgo-managed block plus this repo's local policy
INBOX.md           # zero-ceremony capture; no schema
README.md          # optional landing page; frontmatter may set timezone:
<project>/
  README.md        # identity, map, standing rules (frontmatter: skills, etc.)
  STATUS.md        # current situation, generated task block, next actions
  PLAN.md          # intended route forward (optional)
  tasks/           # one record per task
  decisions/       # ADRs for private or cross-artifact decisions
  references/      # compounding reference pages, playbooks, domain notes
  scripts/         # repeatable project helpers (queries, audits, reports)
  results/         # run logs, benchmark telemetry, audit outputs
  reports/         # authored reports and other prose deliverables
```

Other directories (`docs/`, `data/`, and so on) are fine when a project needs
them; name them in the project README's map. `PROJECT.md` is a legacy name for
the project README; the CLI still reads it when `README.md` is absent.

**`references/`** holds topic and entity pages that outlive single tasks: domain
syntheses, capability matrices, playbooks, and catalogues of external resources.
When a task uncovers durable facts or disproves an earlier claim, fold the
result into the right page in place. Link sources; keep observations,
interpretations, and untested proposals apart; date observations when their age
matters. Revise maintained pages, but keep the historical meaning of task
outcomes, captured evidence, and dated reports. Link every page from the README
map, directly or through a short index. Promote material to a skill only when
other projects keep needing it.

**`scripts/`** holds repeatable helpers so later sessions reuse them instead of
rewriting them. They need not meet the packaging bar of skill scripts. Raw run
evidence belongs in `results/`. Label material imported from elsewhere and kept
for history as such in the README map.

## Non-Code and System Projects

Not every project has a code repository; some have nothing outside the tracker.
A **system project** tracks work on something the user operates, such as
machines, services, or a household. Its durable description lives in a
**knowledge skill**: a private skill that records current facts about particular
systems, accounts, people, or places. The knowledge skill plays the role of the
artifact repository. A task changes the system and finishes by updating the
skill to the new state, with the skill commit in a `Ref:` trailer. The project
README names the skill in its map and its `skills:` frontmatter instead of
copying its facts.

## Where Knowledge Lives

Each fact has one owner; other places link to it. Choose the owner by who needs
the fact and how often it changes:

| Kind of fact                                                 | Owner                                               |
| ------------------------------------------------------------ | --------------------------------------------------- |
| How the code works and is built; code-level rules and ADRs   | Artifact repository                                 |
| What a system, account, person, or place is; how to reach it | Knowledge skill                                     |
| Authored reports, specs, guides, bug reports, reviews        | External canonical copy, or `<project>/reports/`    |
| Repeatable project queries, probes, report helpers           | `<project>/scripts/` (or a skill once promoted)     |
| Why the project exists, scope, map, standing rules           | Project `README.md`                                 |
| Reasoning behind a private or cross-artifact rule            | Project `decisions/`                                |
| Intended route                                               | `PLAN.md`                                           |
| Current situation and next actions                           | `STATUS.md`                                         |
| A unit of work, its outcome, and findings                    | `tasks/`                                            |
| Domain notes, playbooks, syntheses across tasks              | Project `references/`, linked from the README       |
| Run evidence and benchmark telemetry                         | Project `results/`                                  |
| Repo-wide local policy (time zone, reports, environment)     | Root `AGENTS.md`, outside the managed block         |
| What changed, when, and why                                  | Git history (commit prose, `Ref:`, `Conversation:`) |

The project files differ mainly in how often they change: `README.md` over
months, `PLAN.md` over weeks, and `STATUS.md` nearly every commit.

Layouts drift, and old layouts persist. Work with them rather than reorganising
everything at once:

1. **One owner per fact; everywhere else links.** Pointers go stale more slowly
   than copies.
1. **Repair as you go.** When you touch a file, replace a copied fact with a
   link to its owner, or move misplaced content to where it belongs.
1. **The artifact wins.** When a description disagrees with the code or system
   it describes, the description is wrong.
1. **Declare exceptions instead of forcing moves.** An in-repository `TODO.md`,
   an imported planning document, or a project that departs from these defaults
   can stay; the project README map says what it is and whether it is canonical.

## Project README

The project `README.md` is the stable, private description of the project. An
artifact repository's README describes the code to anyone who has it. The
project README describes the user's stewardship of it: things that are true
because this project exists, and that a stranger with only the code would not
need or should not see. It has three roles:

- **Identity:** why the project exists, whom it serves, what success looks like,
  and what is in and out of scope ("not the in-repository backlog", "no paid
  APIs").
- **Map:** where everything lives: checkouts, remotes and forks, deployments,
  data, `references/` and `scripts/`, related projects, and the knowledge skills
  for the systems it runs on. Give one-line summaries, and say which source is
  canonical where several overlap.
- **Standing rules:** constraints that outlast any task, especially private ones
  such as data-safety rules, spending limits, and publication boundaries. State
  each rule briefly and link the ADR that explains it, if there is one.

To test a sentence, ask whether it will still be true after the next five tasks
finish. If not, it belongs in `STATUS.md`, `PLAN.md`, or a task. Code facts,
system facts, the reasoning behind rules, and history belong to the owners in
the table above; the README links to them.

Optional frontmatter holds project configuration. `skills` lists the agent
skills to use on the project, named as the `skill` CLI resolves them (a catalog
short name, optionally `namespace:name`). `taskgo skills <project>` prints the
list, `taskgo handoff` carries it, and `taskgo doctor` warns about unknown
names. A `**Domain / Stakeholders:**` line anchors thematic grouping in
[activity reports](activity-reports.md).

Suggested skeleton (existing headings such as `## Artifacts` or `## Boundaries`
serve the map role and need not be renamed):

```markdown
---
skills:
  - <skill needed when working on this project>
---

# Project Name

One or two sentences on what the project is and why it exists.

## Scope

In scope, and explicitly out of scope.

## Map

- Repository: <https://github.com/owner/repo>; local checkout: `~/workspace/repo`
- Deployment and host details: the `<knowledge-skill>` skill
- Reference notes: [`references/topic.md`](references/topic.md) — one-line summary
- Backlog: this tracker owns <X>; the in-repository `TODO.md` owns <Y>
- Related projects: [other](../other/README.md) owns <Z>

## Constraints

- Standing rule, briefly ([ADR](decisions/001-rule.md)).
```

## Task Records

Completed tasks stay in `tasks/` as permanent records with `status: done`.
`STATUS.md` keeps context bounded: its generated block lists only `In progress`,
`Blocked`, `Due soon` (open tasks due within 7 days), and active `Decisions`,
with state counts. `## Summary` says where the project stands now in a few
sentences; it is rewritten whole, not appended to, and finished work leaves it
(done tasks and Git history keep that). `## Next` is the next few concrete
actions. If a record is ever removed from the working tree, `taskgo history`
reads it from Git.

## ADR Lifecycle

Projects with durable architectural rules keep Nygard-style ADRs in
`<project>/decisions/NNN-slug.md`, with `## Status`, `## Context`,
`## Decision`, and `## Consequences` sections.

- **Superseding:** when a newer ADR replaces an older decision, record
  `supersedes: [001-old-decision.md]` (filename, stem, or numeric prefix such as
  `001`) in the *newer* ADR's frontmatter. Do not rewrite the older file. Edit
  an accepted ADR in place only for typos, status updates, broken links, or
  implementation notes, never to change its decision.
- **Projection:** `taskgo sync` lists only active (not superseded) ADRs in the
  `### Decisions` part of the generated `STATUS.md` block.
- **Checks:** `taskgo doctor` checks `supersedes` targets and cycles. For active
  ADRs it warns about citations of superseded ADRs and broken relative links. A
  superseded ADR's old links are exempt.

## Scheduling Fields

Most tasks need none of these. Use them when something outside the task's own
work decides when it can start or end:

```yaml
blocked_by: [TASK-1627D]
wait_for: [issue/123, 2026-10-13]
due: 2026-10-15
stale_after: 2026-11-01
```

- **`blocked_by`:** other `TASK-XXXXX` IDs only. Record the edge on the task
  that is *held*, never on the blocker. When `taskgo doctor` reports a resolved
  blocker, remove it, or re-plan if the blocker was cancelled.
- **`wait_for`:** external or time gates that keep a task off the ready list.
  Use a typed gate where one fits: an ISO date (`YYYY-MM-DD`, resolved once
  today reaches it), an issue reference (`issue/123`, `gh:owner/repo#12`), a
  handle (`@reviewer`), or an `http(s)` URL. Otherwise write the condition as
  one line of free text (`ShellCheck release with SC2337`). `taskgo check`
  resolves dates and polls `gh:` issues with the `gh` CLI. It polls a `WORD/ID`
  gate only when `TASKGO_GATE_CHECK_<WORD>` names a checker command, which it
  runs as `COMMAND ID`; the command prints `status: STATE` and optionally
  `modified: TIMESTAMP` and `resolved: yes|no`. Without a checker, `check` notes
  the gate and leaves it holding. Handles, URLs, and free text hold the task
  until someone removes them. The CLI refuses free text that contains a task ID
  or a gate it would rather see as its own entry, and says why.
- **`due`:** a committed deadline. `taskgo doctor` reports `[FAIL]` when it has
  passed and `[INFO]` within 48 hours; `taskgo list --state ready` sorts near
  deadlines first.
- **`stale_after`:** a relevance cutoff. After it, `taskgo doctor` warns so you
  re-scope or cancel the task.

`status: blocked` needs no warning while `blocked_by` or `wait_for` has an
unresolved entry. Run `taskgo check [PROJECT]` to list only the open tasks whose
dates have passed, deadlines are near, or upstream issues moved.

On `create` and `update`, `--add-blocked-by` and `--add-wait-for` add one entry;
on `update`, `--remove-blocked-by` and `--remove-wait-for` remove one, and
`--set-wait-for` replaces the whole `wait_for` list. Repeats and absent values
are no-ops. `--due` and `--stale-after` set the dates. `update` refuses a
blocker that is unknown, the task itself, or closes a cycle. `taskgo schema`
lists every field and section.

**Dates** are calendar days with no time zone. Only "today" depends on a zone:
`TASKGO_TODAY=YYYY-MM-DD` wins, then an IANA `timezone:` (such as
`Europe/London`) in the root `README.md` frontmatter, then the machine's local
date. Set the repository zone so cloud sessions on UTC agree with local ones.
`taskgo doctor` fails on an unknown zone.

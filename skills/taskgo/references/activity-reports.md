# Activity Reports

Read this when the user asks for a weekly, monthly, or quarterly summary of
tracked work. An **activity report** turns the private tracker (`tasks/`, Git
history, `STATUS.md`) into a short, outward-facing summary of what was achieved,
why it matters to the reader, and what comes next.

A control repository may set its own audience, scope, grouping, and layout in
the local-policy part of its root `AGENTS.md`. Follow that when it exists; the
guidance below is the default.

## Audience and Extraction

A private tracker mixes **outward-facing outcomes** (work shipped, unblocked,
discovered, or decided that matters to the report's readers) with **personal
workbench upkeep** (maintaining private scripts or agent skills, tracker
hygiene, local environment or account/access setup, and private admin or career
notes). Know who the report is for before extracting work:

- **Filter for the Audience:** Unless the user asks for a personal log, include
  tooling, query, or setup work only when the tool itself was shared with the
  audience; otherwise report the downstream finding or deliverable it enabled
  and drop the scaffolding.
- **Read Task Outcomes:** Read `## Outcome` and `## Findings` in relevant `done`
  and `cancelled` task records—do not summarize from task titles or `STATUS.md`
  alone.
- **Check Live Blockers:** Before listing `blocked` work, check `wait_for` gates
  (`taskgo check`, plus any external trackers `taskgo check` does not poll) so
  items that already landed are reported as shipped or unblocked rather than
  held.
- **Strip Private and Sensitive Data:** Remove conversation and session URIs
  (`<agent>://`, `conversation://`), `TASK-XXXXX` IDs, local branch names,
  control-repository paths, credentials, API keys, and embargoed names.
- **Keep Notes Outside the Report:** Leave the report itself ready to share. Put
  any notes for the user—what was omitted, how themes were grouped, or which
  tracker records have stale gates—in your chat reply unless asked otherwise.

## Shaping the Report

- **Plain English Over Internal Mechanics:** State what changed or was learned
  and why it matters in plain, everyday English. Translate internal class names,
  table schemas, and check codes into clear domain terms, and mention how
  something was tested only when the method itself is the point (such as
  hardware power measurement rather than unit-test assertion counts).
- **Impact Over Effort:** Report outcomes rather than intermediate steps, dead
  ends, or routine plumbing. Roll all tasks for one initiative into a single
  primary bullet (with incidental fixes in a brief clause or `Also, ...`
  bullet), and track a bug's whole progression in one bullet naming the furthest
  state it reached (reported, acknowledged, fix in progress, shipped).
- **Honest, Optional Links:** Link an external artifact (PR, issue, published
  doc, or dashboard) only when the reader can open it and it represents what the
  author produced, changed, or is tracking as a real product or upstream
  dependency—at most one canonical URL per deliverable. Leave unlinked work
  unlinked rather than attaching an input reference document the author read, a
  personal repository outside the audience's scope, or an administrative/access
  ticket.
- **Group by Domain or Stakeholder:** Group by problem domain or stakeholder
  rather than repository folders, using the project README's
  `**Domain / Stakeholders:**` line where present. Scale detail to the horizon:
  tactical milestones and active blockers for weekly or biweekly reports;
  consolidated milestones for monthly reports; systemic outcomes (dropping
  individual bug fixes) for quarterly reports.
- **Non-Terminal Work:** Keep `in-progress` milestones and genuinely unresolved
  `blocked` dependencies brief under a forward-looking section; include a
  `cancelled` task only when its conclusive finding saves the audience future
  effort.

## Coherence Pass

Bottom-up extraction across many projects—especially when split across parallel
subagents or workers—creates local tunnel vision and orphaned fragments. Once
the draft is assembled and stripped of private identifiers, **step back from the
tracker files** (or run a fresh reader pass given only the draft report and
target audience, without the intermediate extraction notes) and read the whole
report cold:

1. **Reader relevance (*"Why am I reading this?"*):** Drop bullets that survived
   only because a project folder had commits—especially enabling queries,
   scripts, or setup left behind after the substantive study they supported was
   merged into another bullet.
1. **Proportion and precision:** Check that wording stripped of code jargon does
   not overstate blast radius (for example, saying a release *"breaks"* when
   only a secondary path fails), and that minor chores do not get equal billing
   with major deliverables.
1. **Attribution and link sanity:** Spot-check cited links and issue IDs against
   their underlying tasks to confirm each is an audience-relevant output or
   upstream bug rather than input reading material or administrative plumbing.

## Example Layout

One possible layout for a team snippet grouped by domain and stakeholder. Adapt
the structure and length to fit the audience and `AGENTS.md`:

```markdown
- [Author Name / Handle]
    - Last [Week | Two Weeks | Month]
        - **[Domain 1]**
            - **[Stakeholder or Area]**
                - **[Outcome or Milestone]**: [Plain-English summary of what shipped or was found and why it matters, linking the deliverable when published].
                - **[Bug or Investigation]**: [Finding, impact, and furthest upstream state reached].
        - **[Domain 2]**
            - **[Outcome]**: [What changed and who or what it unblocks].
            - Also [concise secondary fix or upstream bug filed along the way].
    - Next
        - **[Domain 1]**: [Immediate handoff, review follow-up, or active external dependency].
```

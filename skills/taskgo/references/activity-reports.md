# Activity Reports

An **Activity Report** synthesizes the private, operational taskgo ledger
(tasks, git history, and `STATUS.md`) into a concise, outward-facing summary of
accomplishments, partner/stakeholder impact, and immediate next steps.

Activity reports serve external audiences: team standups, weekly sync documents,
1:1 check-ins, monthly stakeholder updates, and quarterly reviews.

______________________________________________________________________

## 1. Principles of Transformation

The primary failure mode when reporting on a control repository is reciting
internal labor ("I spent 3 hours debugging X", "Created task Y", "Refactored
folder Z"). An activity report requires an active perspective shift:

### I. Impact & External Deliverables Over Inward Labor

- **Report what shipped, unblocked, or published:** Prioritize merged pull
  requests/CLs, deployed artifacts, shared specifications, partner unblockers,
  and verified bug resolutions.
- **De-emphasize inward maintenance:** Omit internal task tracker housekeeping,
  file reorganizations, exploratory dead ends, and routine test runs unless the
  methodology itself is the primary deliverable.
- **Inclusion bias with tight phrasing:** Because a human editor will review and
  tailor the report, err on the side of including more candidate accomplishments
  rather than fewer. However, keep each individual bullet point extremely
  concise (at most 2 sentences / ~40 words).

### II. Track Downstream Momentum (The Issue Lifecycle)

Work does not stop when an issue, ticket, or pull request is filed. A major
indicator of impact is forward movement across the broader ecosystem:

$$\\text{Filed / Reported} \\longrightarrow \\text{Acknowledged}
\\longrightarrow \\text{Reproduced by Partner/Upstream} \\longrightarrow
\\text{Fix in Progress} \\longrightarrow \\text{Release Scheduled}
\\longrightarrow \\text{Shipped to Production}$$

- **Report the furthest advanced state:** If an issue you reported has been
  acknowledged or reproduced by an external partner or upstream team, explicitly
  highlight that milestone.
- **Credit downstream velocity:** Work that *others* did because of a problem
  you identified, isolated, or requested is legitimate evidence of your impact.

### III. Group by Stakeholders & Problem Domains, Not Repository Folders

Do not mechanically mirror project directories as top-level sections. Instead,
organize around the human and organizational entities reading or affected by the
work:

- **Partners / Customers / Integrations:** External partner engagements,
  integration unblockers, and partner-reported defect triage.
- **Platform / Core Subsystems:** Low-level engine, framework, or operating
  system fixes.
- **Tools & Infrastructure:** Developer velocity improvements, testing
  harnesses, and automation.

Nest items hierarchically (e.g. `Partners` -> `[Partner Name]`) when multiple
deliverables belong to the same engagement.

### IV. Sub-linear Horizon Scaling & Quantitative Limits

As the queried time window expands, do not linearly scale bullet count; elevate
the level of abstraction:

- **Weekly ("Last week / This week"):** Include all relevant tactical
  deliverables and active partner milestone transitions. (Immediate next steps
  in "This week").
- **Monthly ("Last month / Next month"):** Maximum 3–5 bullets per Problem
  Domain. Consolidate granular tasks into strategic project milestones and
  patterns across partner engagements.
- **Quarterly:** Maximum 2–3 bullets per Problem Domain. Elevate to high-level
  themes, systemic outcomes, and organizational trajectory; drop individual bug
  fixes unless they represent architectural shifts.

### V. Clean Inlined Linking

- **Direct canonical links:** Inline hyperlinks directly on the noun
  representing the deliverable (e.g.,
  `Published [updated widget audit report](https://...)`).
- **Omit mechanical hosting trivia:** Do not waste reader attention explaining
  deployment mechanics (e.g., omit "deployed via Netlify/Zipline/S3") unless the
  deployment infrastructure itself is the deliverable.
- **Omit unlinked scratch branches:** Never cite transient local branch names
  unless they are published and accessible to the reader.
- **Avoid trailing redundant citations:** If an issue or PR link is embedded in
  the bullet header, do not repeat "Filed bug report" or duplicate ticket IDs at
  the end of the sentence.

### VI. Handling Edge Cases & Non-Terminal States

- **In-Progress Work:** Do not report "Continued working on X." Instead, report
  the current active milestone: "Drafted initial specification for X; pending
  partner review."
- **Blocked Tasks:** Never report idle time. Expose the dependency: "Blocked on
  upstream authentication API release from [Partner Name]."
- **Canceled Tasks / Negative Findings:** A dead end is a deliverable if it
  saves future engineering time. If a task is `status: cancelled` with
  documented findings, report the conclusive finding: "Evaluated [Technology X]
  and ruled out adoption due to [Constraint Y]; saving 2 weeks of misdirected
  migration effort."

### VII. Confidentiality & Data Segregation

Activity reports often exit the private control repository to shared channels
(emails, Slack, team docs, public wikis).

- **Strict Redaction:** Never include API keys, internal credentials, or
  unreleased embargoed product names unless explicitly instructed.
- **Abstract Private Identifiers:** Strip all `conversation://` URLs, local
  branch names, and internal repository file paths from the final report. Link
  explicitly to published external artifacts (e.g., PRs, issue trackers,
  published documents).

______________________________________________________________________

## 2. Data Extraction Directives for Agents

To construct an accurate activity report from a taskgo repository:

1. **Target Time Window:** Query Git log
   (`git log --since="<timeframe>" --stat`) and `taskgo list [PROJECT]` to
   identify tasks touched or transitions made within the window.
1. **Read Outcomes & Findings:** You MUST actively parse the `## Outcome` and
   `## Findings` sections of relevant `status: done` and `status: cancelled`
   task files. Do not generate reports solely from task titles or `STATUS.md`
   summaries, as they often omit the downstream partner progression (e.g.
   "reproduced by OEM") that proves impact.
1. **Draft Discussion Notes:** Accompany draft activity reports with brief
   decision notes explaining thematic grouping, inclusions/omissions, and
   downstream verification rationale to assist human editing.

______________________________________________________________________

## 3. Standard Output Template

```markdown
- [Author Name / Handle]
    - Last [Week | Month]
        - **[Domain / Focus Area 1]**
            - **[Stakeholder / Partner A]**
                - **[Deliverable / Milestone]**: [1-2 sentences on core mechanism, impact, and verification. Link deliverable directly].
                - **[Downstream Milestone / Bug]**: [Root cause, empirical testbed verification, and upstream partner progression (e.g., acknowledged, reproduced, scheduled for release)].
            - **[Platform / Core Subsystem]**
                - **[Platform Fix / Investigation]**: [Empirical findings, test harness verification, and upstream tracking].
        - **[Domain / Focus Area 2 (e.g. Tools & Infrastructure)]**
            - **[Tooling Deliverable]**: [Capabilities added, CLI flags, package updates, and developer velocity impact].
            - Also, [incidental secondary fixes or upstream reports contributed along the way].
    - This [Week | Month]
        - **[Domain 1]**:
            - [Immediate actionable handoff, external review follow-up, or scheduled release].
        - **[Domain 2]**:
            - [Upcoming milestone or unblocking dependency].
```

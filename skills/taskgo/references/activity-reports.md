# Activity Reports

An **Activity Report** turns the private tracker (`tasks/`, Git history,
`STATUS.md`) into a concise, outward-facing summary of accomplishments, partner
impact, and next steps.

## 1. Extraction & Data Segregation

Before drafting a report:

- **Read Task Outcomes:** Read `## Outcome` and `## Findings` in relevant `done`
  and `cancelled` task records—do not summarize from task titles or `STATUS.md`
  alone.
- **Redact Sensitive Details:** Never include API keys or embargoed product
  names.
- **Strip Private Identifiers:** Remove conversation and session URIs
  (`<agent>://`, `conversation://`), local branch names, and control-repository
  paths. Link only to published external artifacts (PRs, CLs, issues, docs,
  dashboards).
- **Include Editorial Notes:** Append brief notes explaining thematic grouping,
  inclusions or omissions, and verification status.

## 2. Transformation Rules

1. **Impact Over Effort:** Report what shipped, unblocked, or published. Omit
   tracker upkeep, dead ends, intermediate scaffolding, and routine plumbing;
   fold intermediate findings into the deliverable bullet.
1. **One Initiative, One Primary Bullet:** Roll all tasks for a milestone into a
   single primary bullet. Put prerequisite plumbing or incidental fixes in a
   trailing clause or compact `Also, ...` sibling bullet—never split one
   initiative into four or five bullets.
1. **One Bug, One Bullet:** Track a bug's full progression (Reported ->
   Acknowledged -> Reproduced by Partner -> Fix in Progress -> Scheduled ->
   Shipped) in a single bullet, naming its furthest downstream state.
1. **One Artifact, One Canonical Link:** Link the deliverable noun directly to
   its single most authoritative external URL; omit mirror links and hosting
   trivia.
1. **Group by Domain or Stakeholder:** Group by external stakeholder, partner,
   or problem domain rather than repository folders. Use short 2–3 word headings
   (such as `Wear Widgets` or `AI Tooling`) and nest multiple deliverables under
   each partner.
1. **Scale by Horizon:** Keep each bullet to 1–2 sentences (~40 words):
   - **Weekly:** Tactical deliverables and active partner milestone transitions.
   - **Monthly:** At most 3–5 bullets per domain, consolidating tasks into
     milestones.
   - **Quarterly:** At most 2–3 bullets per domain focused on systemic outcomes;
     drop individual bug fixes.
1. **Non-Terminal Work:** For `in-progress` tasks, report the active milestone;
   for `blocked` tasks, name the dependency; for `cancelled` tasks, report the
   conclusive finding when it saves future effort.

## 3. Output Template

```markdown
- [Author Name / Handle]
    - Last [Week | Month]
        - **[Domain / Focus Area 1 (e.g., Wear Widgets)]**
            - **[Stakeholder / Partner A]**
                - **[Deliverable / Milestone]**: [1-2 sentences on core mechanism, impact, and verification. Link deliverable directly].
                - **[Downstream Milestone / Bug]**: [Root cause, empirical testbed verification, and upstream partner progression (e.g., acknowledged, reproduced, scheduled for release)].
            - **[Platform / Core Subsystem]**
                - **[Platform Fix / Investigation]**: [Empirical findings, test harness verification, and upstream tracking].
        - **[Domain / Focus Area 2 (e.g., Tools & Infrastructure)]**
            - **[Tooling Deliverable]**: [Capabilities added, CLI flags, package updates, and developer velocity impact].
            - Also, [incidental secondary fixes or upstream reports contributed along the way].
    - This [Week | Month]
        - **[Domain 1]**:
            - [Immediate actionable handoff, external review follow-up, or scheduled release].
        - **[Domain 2]**:
            - [Upcoming milestone or unblocking dependency].
```

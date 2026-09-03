# Activity Reports

An **Activity Report** synthesizes the private operational ledger (tasks, git
history, `STATUS.md`) into a concise, outward-facing summary of accomplishments,
partner impact, and next steps for external audiences.

______________________________________________________________________

## 1. Extraction & Segregation Directives (Strict)

Agents MUST execute the following before generating the report:

- **Deep Extraction:** Actively parse the `## Outcome` and `## Findings`
  sections of relevant `status: done` and `status: cancelled` task files. Do not
  generate reports solely from task titles or `STATUS.md` summaries.
- **Strict Redaction:** Never include API keys or unreleased embargoed product
  names.
- **Abstract Private Identifiers:** Strip all `conversation://` URLs, local
  branch names, and internal repository file paths. Link exclusively to
  published external artifacts (PRs, issues, dashboards).
- **Draft Discussion Notes:** Append brief decision notes explaining thematic
  grouping, inclusions/omissions, and downstream verification rationale.

______________________________________________________________________

## 2. Golden Rules of Transformation

Follow these imperative constraints to convert inward tracker data into outward
impact:

1. **Impact Over Effort:** Report deliverables (what shipped, unblocked, or
   published). Omit inward labor, tracker housekeeping, exploratory dead ends,
   intermediate scaffolding, and background calculations. Fold intermediate
   findings directly into the final deliverable.
1. **1 Initiative = 1 Primary Bullet (Anti-Fragmentation):** Package all tasks
   belonging to a single milestone into ONE primary deliverable bullet. Relegate
   prerequisite plumbing or incidental harness fixes to a trailing clause or
   compact sibling bullet (e.g., "Also, ..."). *Never emit 4–5 bullets for a
   single initiative.*
1. **1 Bug = 1 Bullet (Track Downstream Momentum):** Track the complete
   lifecycle (Reported $\\to$ Acknowledged $\\to$ Reproduced by Partner $\\to$
   Fix in Progress $\\to$ Scheduled $\\to$ Shipped) in a single bullet.
   Explicitly report the furthest advanced downstream state to prove ecosystem
   momentum.
1. **1 Artifact = 1 Canonical Link:** Inline direct canonical links on the noun
   representing the deliverable. Pick the single most authoritative target and
   never include multiple mirror URLs. Omit mechanical hosting trivia.
1. **Crisp Grouping:** Group strictly by external stakeholder, partner, or
   problem domain. Do not mirror repository folders. Use crisp 2–3 word headings
   (e.g., `Wear Widgets`, `AI Tooling`). Nest items hierarchically for multiple
   deliverables per partner.
1. **Quantitative Tightness:** Limit each bullet to a maximum of 1–2 sentences
   (~40 words). Apply sub-linear horizon scaling:
   - **Weekly:** Include all relevant tactical deliverables and active partner
     milestone transitions.
   - **Monthly:** Maximum 3–5 bullets per domain. Consolidate granular tasks
     into strategic milestones.
   - **Quarterly:** Maximum 2–3 bullets per domain. Elevate to systemic outcomes
     and organizational trajectory; drop individual bug fixes.
1. **Handle Non-Terminal States:** For in-progress work, report the current
   active milestone. For blocked work, expose the dependency. For cancelled
   tasks, report the conclusive finding if it saves future engineering time.

______________________________________________________________________

## 3. Standard Output Template

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

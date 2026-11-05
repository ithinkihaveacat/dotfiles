# Analytical Report Guidelines

This guide covers authoring and editing data-backed engineering investigations,
telemetry and UX studies, empirical one-pagers, and findings-and-recommendations
memos, including documents that aim to persuade readers toward a concrete
product or architectural change.

## Intent and Audience

When an investigation points toward a clear conclusion, writers often feel torn
between a passive data report and an overt position paper. In engineering
organizations, persuasion works best when those roles are separated between
structure and tone:

<!-- markdownlint-disable MD013 -->

| Form                     | Structure                                 | Tone                         | Typical Reader Reaction                                          |
| ------------------------ | ----------------------------------------- | ---------------------------- | ---------------------------------------------------------------- |
| **Raw Data Report**      | Tables and dashboards without a thesis    | Neutral, detached            | *"Interesting numbers, so what should we do?"*                   |
| **Overt Position Paper** | Argument-first, selective evidence        | Forceful, rhetorical, urgent | Skepticism and defensiveness, especially from system maintainers |
| **Analytical Report**    | Controlled comparisons leading to actions | Matter-of-fact, understated  | High trust; readers arrive at the conclusion alongside the data  |

<!-- markdownlint-enable MD013 -->

- **Goal:** Align peers, partner teams, or leadership around an empirical
  finding, its underlying mechanism, and practical next steps.
- **Audience:** Engineers, product managers, and maintainers, often including
  the teams who built or operate the system under study.
- **Tone:** Calm, collegial, and understated. Let the study design carry the
  argument so the prose stays neutral.

## Core Principles

### Persuade Through Structure, Not Prose

When a report pairs the right comparisons, includes a baseline control, and
shows concrete artifacts, the evidence makes the case on its own. Loaded verbs,
dramatic headlines, and rhetorical transitions weaken an empirical finding by
making it read like a pitch.

- **Drop editorial intensifiers and LLM flourishes:** Avoid dramatic verbs and
  idioms (*"floods"*, *"hits a wall"*, *"completely broken"*), rhetorical pivots
  (*"Worse, ..."*, *"Even more alarming..."*), coined conceptual labels (*"The
  Volume Paradox"*, *"Law 1 / Law 2"*), and em-dash cliffhangers in headings or
  leads (*"— and Why 78% Fail"*).
- **Keep section leads brief:** Introduce each section or chart in one or two
  declarative sentences that state what is being compared and the headline
  result. Do not write multi-paragraph prose narrating every bar or row visible
  in the graphic directly below.

### Literal Titles and Personal Attribution

- **Name the subject, not the verdict:** Use tight, descriptive titles and
  headings that state what is being examined (*"An Analysis of Setup Recommended
  Extensions"*, *"Install Source and 7-Day Retention"*, *"First-Open Bounce:
  Setup Wizard vs. Explicit Search"*). Favor a clean single-line title over
  exhaustive qualification.
- **Use personal, accountable attribution:** Credit the actual author and date
  (`Jane Doe (jane@example.com) · November 4, 2026`). Avoid synthetic
  institutional eyebrows or whitepaper series badges (*"DEVELOPER ACQUISITION &
  FIRST-RUN UX STUDY · NOV 2026"*), which read as artificial branding and
  obscure who stands behind the analysis.

### Charitable System Context

Systems rarely end up in an awkward state because their maintainers were
careless. Before proposing changes to a flag, API, or curation surface, explain
the historical or architectural reason it behaves the way it does.

- Replace accusatory framing (*"The `offlineReady` manifest flag doesn't tell
  the truth"*) with factual history (*"The `offlineReady` flag was introduced
  for cached template bundles and is not checked during package review, so it
  does not predict whether a cold install can launch without network access"*).
- Charitable context keeps partner and platform owners receptive to your
  recommendations and shows you have accounted for existing constraints.

### Contrasts, Controls, and Primary Evidence

Data by itself is empty. Dumping wide multi-metric tables or regression outputs
pushes the analytical work onto the reader. Organize the evidence around
comparisons that isolate one variable at a time:

- **Matched or within-subject contrasts:** Compare the same item across two
  entry points (such as explicit store search vs. passive setup checklist
  installs), or compare two peers in the same category with different
  acquisition mixes. Curated comparison presets with a one-sentence takeaway
  help readers explore interactive views without getting lost.
- **Natural controls:** Include a comparison case where the suspected cause is
  absent (for example, a standalone tool that needs no companion service).
  Showing that the gap shrinks on the control rules out generic channel bias.
- **Mechanism cohorts:** Group items into two or three intuitive buckets by
  exposure to the root cause (such as *Companion Present*, *Mixed*, and
  *Companion Missing*) rather than reporting raw correlation coefficients or
  p-values in the main text.
- **Primary UX or system artifacts:** Pair aggregate telemetry with concrete
  observations from hands-on testing (such as first-launch screenshots, CLI
  transcripts, or configuration snippets) so readers see what users actually
  experience behind a bounce or drop-off rate.
- **Plain-English domain labels:** Translate internal table names, pipeline
  enums, and metric codes into clear labels across headings, axes, and prose
  (*"Setup Checklist"* and *"Kept (2+ opens)"* rather than `OOBE_MERCH` and
  `7d_uRUC`). Keep raw SQL table or pipeline lineage in an appendix, footnote,
  or companion query note if needed for reproducibility.

### Strategic Number Discipline

When every card, node, axis, and caption repeats the same numbers at full
decimal precision, none of them stand out. Give each visual element one job:

- **Separate volume from rate:** Put absolute counts in summary KPI headers
  (`Installs: 84,200`, `Active Users: 4,900`) and show flow shares or conversion
  rates on the chart itself (`88%`, `12%`), rather than printing both on every
  label.
- **Round to whole percentages by default:** Use rounded integers (`89%`, `78%`,
  `29% -> 71%`) in headlines, prose, and chart annotations unless tenths of a
  percent materially affect the conclusion.
- **Ensure displayed math reconciles:** Check that rounded figures and their
  displayed differences add up cleanly (`29%` baseline + `42 pp` gap = `71%`),
  computing displayed deltas from the rounded endpoints when needed.

### Proportional, Scoped Recommendations

- **Place recommendations at the end:** Let the funnel data, mechanism charts,
  and on-device or system observations establish *why* the problem happens
  before proposing what to change.
- **Scope each action to a concrete lever:** Tie each recommendation to a
  specific surface or owner (*Setup Flow*, *Catalog Curation*, *Partner
  Guidance*) and describe the concrete behavioral change rather than calling for
  broad strategic reviews. Offering two or three complementary levers across
  layers avoids prescribing a single brittle fix.

## Recommended Structure

Whether published as a Markdown document or an interactive HTML report, an
analytical report typically follows this arc:

1. **Byline and Title:** Author name/contact, date, and a concise, neutral
   subject title.
1. **Lead and Summary Metrics:** Two sentences stating the system behavior and
   headline empirical outcomes, optionally paired with three summary metric
   cards (for example: unopened share, first-launch block rate, and first-open
   bounce rate).
1. **Acquisition or Funnel Comparison:** Side-by-side flows or a focused
   comparison table showing how top-line volume translates into retained usage
   across representative examples.
1. **Mechanism and Control Charts:** Simple visual comparisons (such as a
   within-item dumbbell chart and a grouped cohort column chart) isolating the
   causal factor against an explicit-intent or standalone control.
1. **Hands-On System Audit:** Concrete evidence from testing the items directly
   (first-run screenshots, manifest/config breakdown, and historical context for
   any misleading flags).
1. **Recommendations:** Two to four short, scoped recommendations grounded in
   the preceding sections.

## Before and After Examples

### Title, Attribution, and Lead

**DON'T (Synthetic branding, magazine headline, and loaded prose):**

> **CLOUD IDE ACQUISITION & FIRST-RUN UX STUDY · NOV 2026**
>
> **Volume vs. Intent: How Extensions Reach the Editor — and Why 76% of Setup
> Picks Hit a Wall**
>
> Promoting an extension on the first-run **Recommended ("Merch")** checklist
> floods workspaces with passive installs that **88.4% of developers never
> activate**. Worse, checking a recommended box installs **only the UI
> plugin**—and when users open those plugins without the local language daemon,
> **19 of the 25 featured extensions (76.2% of selections) hit an immediate
> configuration or sign-in wall**.

**DO (Personal attribution, literal title, and factual mechanics):**

> Jane Doe (jane@example.com) · November 4, 2026
>
> **An Analysis of Onboarding Recommended Extensions**
>
> Selecting a **Recommended** extension during workspace setup installs only the
> editor plugin, not its local language daemon. **Roughly 88% of these installs
> go unused in the first week, 76% require a local daemon or account sign-in on
> first open, and up to 69% of setup openers bounce after a single session.**

### Explaining a Misleading System Signal

**DON'T (Accusatory framing):**

> ### The `standalone` Manifest Flag Doesn't Tell the Truth
>
> Eight featured extensions claim `standalone: true` in their package manifests
> even though they immediately block users on a sign-in or companion-daemon
> screen. Developers routinely mislabel this flag, making manifest metadata
> useless for onboarding curation.

**DO (Charitable historical and system context):**

> ### The `standalone` Manifest Flag
>
> The `standalone` manifest field was originally introduced for browser-only
> sandboxes and is no longer checked during marketplace review. Because it is
> unverified and permits external browser sign-in even when `true`, it does not
> predict whether a cold onboarding install works on its own: 8 of the 15
> extensions with `standalone: true` still block on first launch.

### Chart Framing and Number Economy

**DON'T (Pipeline jargon, competing precision, and prose repeating the table):**

> ### Law 2: `OOBE_MERCH` vs. `MARKETPLACE_SEARCH` `7d_bounce_rate`
>
> Across `ext_telemetry.engagement_by_source_7d`, OLS regression confirms
> `daemon_missing_share` predicts `oobe_bounce` (`r = 0.78, p = 0.002`).
> `CodeLint` has 84,219 total installs (73,186 `OOBE_MERCH`, 86.9%) with a
> `60.4%` setup bounce rate (5,112 bounced of 8,463 openers) versus `30.8%` on
> `MARKETPLACE_SEARCH` (+29.6 pp).

**DO (Plain-English labels, one job per element, and reconciled integers):**

> ### First-Open Bounce: Workspace Setup vs. Explicit Search
>
> Opening a blocked setup extension records one activation followed by zero
> repeat sessions within 7 days. Across all 25 setup extensions, median
> first-open bounce rises from **27%** on Marketplace Search to **43%** from
> Workspace Setup, and reaches **60%–69%** when the local daemon is usually
> missing (for example, **CodeLint** rises from **31%** on Search to **60%**, a
> **+29 pp** gap).

## Summary Checklist

Before finalizing an analytical report, verify that:

- [ ] Title and section headings name the subject and variables literally,
  without magazine hooks, coined "laws/paradoxes", or em-dash cliffhangers.
- [ ] Attribution names the real author and date rather than a synthetic "study"
  or institutional eyebrow.
- [ ] Prose is concise and understated, free of loaded verbs (*"floods"*, *"hits
  a wall"*) and multi-paragraph narration of visible chart values.
- [ ] Misleading flags, APIs, or workflows are explained with charitable
  historical/system context rather than blame.
- [ ] Claims are demonstrated through matched comparisons, natural controls, and
  concrete UX/system artifacts rather than raw metric dumps or statistical
  jargon.
- [ ] Internal table names and pipeline codes are translated into plain English
  across titles, axes, and body text.
- [ ] Each visual element has one numerical job, percentages are rounded to
  integers where appropriate, and displayed deltas reconcile cleanly.
- [ ] Recommendations appear at the end and are scoped to concrete surfaces and
  owners.

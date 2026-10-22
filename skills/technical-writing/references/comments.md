# Comment Guidelines

This document provides guidelines for writing clear, collegial, and empirically
grounded comments in code reviews and issue trackers.

## Intent and Audience

Technical comments generally fall into two arenas, each benefiting from a
tailored posture:

<!-- markdownlint-disable MD013 -->

| Aspect       | Code Review Comments                                                 | Issue Tracker Comments                                                    |
| :----------- | :------------------------------------------------------------------- | :------------------------------------------------------------------------ |
| **Goal**     | Resolve questions or clarify a diff with minimal cognitive overhead. | Advance an investigation, evaluate a proposed fix, or clarify bug impact. |
| **Audience** | Reviewers and collaborators who already have the diff in context.    | Maintainers, triagers, and future readers investigating a defect.         |
| **Scope**    | Targeted line-level explanations and trade-off summaries.            | Quick status notes to detailed technical justifications of a report.      |
| **Tone**     | Direct, concise, and conclusion-first.                               | Understated, inquisitive, collegial, and empirically grounded.            |

<!-- markdownlint-enable MD013 -->

## Core Principles

### 1. Calm Restraint and Understatement

Avoid alarmist, emotional, or hyperbolic language (*"critical blocker"*,
*"completely broken"*, *"unacceptable regression"*). Forceful phrasing triggers
defensiveness and shifts focus away from the technical facts. Calm, clinical
understatement makes empirical evidence more persuasive:

- Prefer measured observations: *"This appears to have regressed"*, *"This
  behavior is surprising given X"*, *"Changing the wire format probably isn't
  worth the churn"*.
- Keep peripheral corrections low-friction: *"Minor note: commit `a1b2c3d`
  applies this timeout across all workers, not just local runs."*

### 2. Demonstrate Severity via Causal Mechanics

Rather than asserting severity with adjectives or priority demands, lay out the
causal chain from trigger to cost:

`[Trigger]` $\\rightarrow$ `[Mechanism]` $\\rightarrow$ `[Observable Symptom]`
$\\rightarrow$ `[User / Developer Cost]`

Focus on concrete systemic impacts when explaining the cost:

- **Observability Gaps:** Show how a silent failure or generic error masks the
  root cause and misdirects debugging (e.g., an invalid archive entry silently
  truncating a lookup path so later calls fail with a misleading error).
- **Blast Radius:** Contrast localized degradation with broad failure (e.g., one
  oversized item aborting an entire batch payload rather than skipping only the
  offending item).
- **Expectation Mismatches:** Note where behavior diverges from sibling APIs or
  documented contracts.

### 3. Socratic Framing and Intellectual Humility

Approach investigations and architectural critiques with curiosity and clear
boundaries around what you have verified:

- **Open with appreciation:** Acknowledge the maintainer's time (*"Thanks for
  checking!"*, *"Thanks for looking into this."*).
- **Declare blind spots upfront:** State what you have not tested or cannot
  access (*"I'm less familiar with the auth middleware, but..."*). Bounding what
  you do not know increases trust in what you have verified.
- **Use clarifying questions for incomplete fixes:** Rather than declaring a
  proposed fix inadequate, ask questions that surface the unaddressed path
  (*"Just so I understand—this validates static configs at startup, right? How
  does it handle configs reloaded dynamically at runtime?"*).

### 4. Trade-offs Over Dictation

Avoid prescribing a single mandatory fix, especially when changing core engines
or wire protocols carries high migration churn:

- **Acknowledge ecosystem constraints:** Note existing callers or tests that
  rely on current behavior before proposing changes.
- **Offer pragmatic options:** Suggest 2–3 paths with different cost/benefit
  profiles (e.g., automatic handling, graceful fallback with a warning, or
  clearer error messages/docs), or close with an open question (*"Is there a
  reasonable way to extend this to cover the runtime path?"*).

### 5. Candor and Closing the Loop

- **Attribute unverified AI/agent analysis:** Distinguish personal empirical
  verification from automated hypotheses (*"Agent analysis (unverified): ..."*).
- **Concede and narrow scope promptly:** If further testing shows a narrower
  reproduction scope (e.g., test harnesses rather than production), update the
  thread promptly and suggest lowering priority.
- **Confirm fixes:** When a maintainer lands a fix, verify it and reply to close
  the loop.

## Code Review Comments

Code review comments should minimize cognitive load for reviewers who already
have the diff in context:

- **Lead with the conclusion:** Answer the question in the first sentence
  (*"Yes, this is expected."*).
- **Trim narrative buildup:** Merge sentences and omit chronological backstory
  unless needed to explain a non-obvious constraint.
- **State the technical contrast directly:** Contrast old vs. new behavior in a
  single clause (*"The mock client ignored pagination limits, whereas the real
  adapter enforces them"*).

### Example: Explaining a Behavioral Change in a Diff

**DON'T (Verbose and conclusion-last):**

> Hi @reviewer, yes, this is expected. In the real layout engine, the header
> container coordinates with the scroll controller to collapse the toolbar when
> the list scrolls. Previously, our test harness used a stub wrapper that didn't
> simulate scroll events, so the toolbar stayed visible in every snapshot.
> Because this PR migrates the test to the standard container and scrolls before
> the second capture, the header now collapses as it does in production.

**DO (Concise and conclusion-first):**

> @reviewer I believe this is expected. The standard container automatically
> collapses the header during scrolling to maximize content space. The legacy
> test stub didn't simulate this, so migrating to the standard component makes
> the post-scroll snapshot match actual runtime behavior.

## Issue Tracker Comments

Issue tracker comments range from quick drive-by notes (sharing a workaround,
linking a related commit, or confirming a fix) to considered technical responses
that clarify boundary conditions or justify a report's severity.

### Evaluating a Partial Fix

When a proposed change fixes a static or build-time scenario but leaves dynamic
runtime paths vulnerable, acknowledge what the fix improves before outlining the
remaining operational hurdles.

**DON'T (Confrontational and hyperbolic):**

> This PR doesn't actually fix the bug. Throwing `PayloadTooLargeException` in
> local dev mode is useless in production when apps fetch user-generated images
> over the network! Unlike the v1 renderer, which isolated image failures to a
> single node, bundling raw image bytes into one IPC payload means a single
> large asset breaks the entire screen. Worse, the background worker swallows
> the exception so callers can't even catch it. You need to auto-downsample.

**DO (Socratic, understated, and causally grounded):**

> Just so I understand—this fix surfaces `PayloadTooLargeException` for static
> assets during local preview builds, right? It doesn't appear to cover images
> fetched over the network at runtime whose encoded sizes aren't known ahead of
> time.
>
> Unlike v1 (which referenced assets by ID and isolated decode failures to the
> individual image node), v2 bundles layout ops and compressed image bytes into
> a single IPC payload, so one oversized runtime image aborts the entire view
> update. Even with the new exception, runtime recovery seems difficult:
>
> 1. **Unpredictable compressed size:** Callers can't reliably predict from raw
>    bitmap dimensions whether the encoded payload will exceed the budget.
> 1. **Swallowed on background pulls:** The worker catches the exception and
>    drops the callback, so callers cannot catch it to retry with a fallback.
>
> Is there a reasonable way to augment this—for example, by downsampling
> automatically or omitting only the offending image node?

### Navigating "Works for Me" Pushback

When an assignee cannot reproduce a defect, avoid arguing. Instead, explain why
their test succeeded, isolate the structural difference, and provide a minimal
reproduction.

**DON'T (Dismissive and repetitive):**

> @assignee Your test only worked because your text node was at the root level.
> As stated in the description, ellipsis truncation is broken whenever text is
> placed inside a narrower child container. Please test with a fixed-width box.

**DO (Collaborative, isolating the delta, and reproducible):**

> @assignee Thanks for checking! Your test passes because the text element sits
> directly inside the full-width root container, where the layout pass receives
> the outer bounds and computes the ellipsis (`"Hello Wor..."`).
>
> The issue here specifically affects **nested fixed-width containers** (such as
> a `Box(width = 80.dp)` inside a row). When `maxLines = 1` and `Ellipsis` are
> set on a nested child, the renderer clips the canvas to the child bounds
> before measuring the ellipsis glyph, slicing the text mid-character:
>
> ```kotlin
> Row { Box(width = 80.dp) { Text("Long label text", maxLines = 1, overflow = Ellipsis) } }
> ```

### Polite Firmness on Workarounds and Closures

When a valid issue is closed prematurely or deflected with a local workaround,
stay collegial while keeping focus on the underlying defect:

<!-- markdownlint-disable MD013 -->

| Situation                    | DON'T (Reactive / Frustrated)                                               | DO (Polite, Factual, and Firm)                                                                                                                                                  |
| :--------------------------- | :-------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Premature closure**        | *"Why was this closed? This is still broken and crashes in production."*    | *"Reopening this. To summarize the impact, this throws a runtime exception whenever a batch request contains an empty filter list."*                                            |
| **Local workaround offered** | *"I already know how to work around it locally. The tool itself is buggy."* | *"Thanks—I've unblocked my local setup with the workaround noted in the report. I filed this hoping we could fix the CLI default so others don't hit the same trap."*           |
| **Suggested fix fails**      | *"That flag doesn't work at all. Did you test this?"*                       | *"That flag doesn't seem to resolve it in my environment—could you share the command sequence you used? When I pass `--reset`, the lockfile remains stale (see output below)."* |

<!-- markdownlint-enable MD013 -->

## Summary Checklist

Before submitting a technical comment, verify that:

- [ ] **Code Reviews:** The direct answer or conclusion appears in the first
  sentence, with unnecessary backstory trimmed.
- [ ] **Tone:** Phrasing is calm, collegial, and understated, free of alarmist
  or hyperbolic labels (*"blocker"*, *"completely broken"*, *"unacceptable"*).
- [ ] **Severity:** Impact is shown through a factual causal chain (trigger
  $\\rightarrow$ mechanism $\\rightarrow$ symptom $\\rightarrow$ cost) rather
  than adjectives.
- [ ] **Framing:** Critiques of incomplete fixes open with clarifying questions
  and offer pragmatic trade-offs rather than ultimatums.
- [ ] **Pushback:** Replies to *"works for me"* explain why the maintainer's
  test passed, isolate the failing delta, and include a minimal reproduction.
- [ ] **Provenance:** Any unverified AI/agent analysis is explicitly labeled.

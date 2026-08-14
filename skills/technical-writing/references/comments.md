# Comment Guidelines

This document outlines the standard for writing effective, concise, and factual
comments in technical discussions (e.g., code reviews, bug trackers).

## Intent and Audience

Comments explain technical decisions, answer reviewer questions, or provide
clarifying context on specific diffs.

- **Goal:** Resolve reviewer questions with minimum cognitive overhead.
- **Audience:** Code reviewers and engineering collaborators.
- **Tone:** Direct, concise, and factual.

## Code Review Comments

Code review comments should be tight and direct to respect the reviewer's time
and keep the discussion focused.

### Example: Refining a Response

**DON'T (Too verbose and detailed):**

> Hi @username, yes, this is expected. In Wear Compose Material 3,
> ScreenScaffold is designed to coordinate with AppScaffold to handle
> transitions for TimeText and ScrollIndicator. When a scrollState is provided
> to ScreenScaffold (as is the case in ListScreen), it automatically hides the
> TimeText during scrolling to maximize screen space for the content. The reason
> this appeared as a change is that the previous test harness using Horologist's
> AppScaffold did not accurately reflect this on-device behavior in screenshot
> tests. By migrating to native Material 3 components in the test, the
> screenshot tests now correctly show the time text disappearing on scroll,
> which matches how the app actually behaves on a physical device. Since the
> ListScreenTest performs a scroll before capturing the second screenshot
> (\_end), the TimeText disappears as intended.

**DO (Tight and effective):**

> @username I believe this is expected. In Wear Compose Material 3,
> ScreenScaffold automatically hides the TimeText during scrolling to maximize
> content space. Horologist's AppScaffold didn't simulate this, but the native
> Material 3 components do, and so the screenshot tests now correctly reflect
> the actual behavior on a physical watch.

**Key Takeaways:**

- **State the conclusion first** ("I believe this is expected").
- **Merge sentences** to remove transitions and filler.
- **State the contrast directly** ("Horologist didn't... but Material 3 does").

## Summary Checklist

Before submitting a review comment, verify that:

- [ ] The conclusion or direct answer is stated in the very first sentence.
- [ ] Filler transitions and narrative histories are edited out.
- [ ] Technical claims are factually grounded in component behavior.

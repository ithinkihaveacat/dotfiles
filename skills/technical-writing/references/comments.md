# Writing Comments

Guidelines for writing effective, concise, and factual comments across different
contexts.

## General Principles

- **Be Direct and Concise:** Avoid unnecessary filler words. State the
  conclusion first.
- **Factual and Objective:** Explain _why_ something is happening based on
  technical facts, not assumptions.
- **Acknowledge Context:** Reference the specific behavior or tool being
  discussed.

---

## Code Review Comments

Code review comments should be tight and direct to respect the reviewer's time
and keep the discussion focused.

### Example: Refining a Response

Here is an example of refining a response to a reviewer's question about a
change in behavior.

#### Original Response (Too long and detailed)

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

#### Refined Version (Tighter and more direct)

> Hi @username, yes, this is expected. In Wear Compose Material 3,
> ScreenScaffold automatically hides the TimeText during scrolling to maximize
> content space. The previous Horologist test harness did not accurately
> simulate this on-device behavior. By migrating to native Material 3
> components, the screenshot tests now correctly reflect the actual behavior on
> a physical watch. Since ListScreenTest scrolls before capturing the \_end
> screenshot, the TimeText disappears as intended by the scaffold design.

#### Final Version (Tightest and most effective)

> @username I believe this is expected. In Wear Compose Material 3,
> ScreenScaffold automatically hides the TimeText during scrolling to maximize
> content space. Horologist's AppScaffold didn't simulate this, but the native
> Material 3 components do, and so the screenshot tests now correctly reflect
> the actual behavior on a physical watch.

**Key Takeaways:**

- **State the conclusion first** ("I believe this is expected").
- **Merge sentences** to remove transitions and filler.
- **State the contrast directly** ("Horologist didn't... but Material 3 does").

---

## Bug Report Comments

_(Placeholder for future guidelines on commenting on bug reports, e.g.,
providing logs, reproduction steps, or status updates.)_

# Web Development

## State and Navigation

Web sites must preserve state and scroll position during browser navigation
(browser back/forward buttons, as well as any on-page back/forward navigation).

This includes:

- **Scroll Position:** The exact scroll position must be maintained when
  returning to a page.
- **Dynamic State:** State changes, such as an expanded list (e.g., if a "more"
  button has been clicked on a search results page), must be preserved so the
  user returns to the exact view they left.

**Exceptions and Relaxations:**

- **Visual Correctness:** It is acceptable if some elements need to be reloaded
  or re-fetched as the user scrolls, provided that the result is visually
  correct and the scroll bar position does not jump.
- **Transient In-Component State:** For carousel-like components, persist only
  the resting position (e.g. via `replaceState`, so it survives reload and is
  shareable); do not push a history entry per intermediate step, as that hijacks
  the back button into rewinding the component instead of leaving the page.
- **Hard Reloads:** The requirements are reduced if the user explicitly reloads
  the page. While preserving scroll position on reload can be difficult, you
  should still preserve as much state as reasonably possible (e.g., maintaining
  search box inputs by pulling them from the URL).

We only care about supporting this behavior in modern browsers; legacy browsers
are explicitly out of scope. The overarching goal is to provide the very best
reasonably possible behavior regarding preserving state on browser navigation
(often referred to as leveraging the bfcache or History API state restoration).

## Keyboard Navigation

Keyboard navigation must be generally well supported, prioritizing practical
usability over exhaustive, visually disruptive focus indicators on every DOM
node.

- **Focus Management:** Utilize `:focus-visible` to restrict focus rings
  strictly to keyboard navigation contexts, avoiding visual clutter for pointer
  users.
- **Spatial Navigation:** Implement roving `tabindex` and arrow key navigation
  for composite UI patterns (such as image carousels, data grids, and
  listboxes). Users should be able to `Tab` into a widget and seamlessly use
  arrow keys to navigate its internal items.
- **Link Collections:** A grid of independent navigational links (e.g. search
  results) is exempt — expose each link as its own tab stop in source order. The
  test is semantic, not visual: widgets whose items select shared in-place state
  (carousels, listboxes, tabs) remain roving.

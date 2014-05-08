# center-line package

Scrolls the cursor to the center of the screen.  Repeat to cycle between the center, top, and
bottom of the screen.

This is similar to the built-in Editor:Scroll To Cursor but adds the support for scrolling to
the top and bottom.  Also, as of Atom 0.84, Editor:Scroll To Cursor does not scroll the cursor
to the center of the screen if the cursor is already visible.

It is bound to `ctrl-l` which overrides the built-in.

Once Atom's core is in a public repository, I'd like to propose this get moved into the core to replace Scroll To Cursor since it is a simple but useful superset of it.

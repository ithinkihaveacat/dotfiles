# Git Operations

Agents must not commit changes automatically unless explicitly requested. When
tasked with modifying code (e.g., fixing a bug, adding a feature), apply the
changes to the working directory but refrain from committing them. Only proceed
with `git commit` when explicitly commanded to do so.

## Commit Messages

When generating git commit messages, use the following specification (copied
from [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)):

### Specification

The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”,
“SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be
interpreted as described in [RFC 2119](https://www.ietf.org/rfc/rfc2119.txt).

1. Commits MUST be prefixed with a type, which consists of a noun, `feat`,
   `fix`, etc., followed by the OPTIONAL scope, OPTIONAL `!`, and REQUIRED
   terminal colon and space.
1. The type `feat` MUST be used when a commit adds a new feature to your
   application or library.
1. The type `fix` MUST be used when a commit represents a bug fix for your
   application.
1. A scope MAY be provided after a type. A scope MUST consist of a noun
   describing a section of the codebase surrounded by parenthesis, e.g.,
   `fix(parser):`
1. A description MUST immediately follow the colon and space after the
   type/scope prefix. The description is a short summary of the code changes,
   e.g., _fix: array parsing issue when multiple spaces were contained in
   string_.
1. A longer commit body MAY be provided after the short description, providing
   additional contextual information about the code changes. The body MUST begin
   one blank line after the description.
1. A commit body is free-form and MAY consist of any number of newline separated
   paragraphs.
1. One or more footers MAY be provided one blank line after the body. Each
   footer MUST consist of a word token, followed by either a `:<space>` or
   `<space>#` separator, followed by a string value (this is inspired by the
   [git trailer convention](https://git-scm.com/docs/git-interpret-trailers)).
1. A footer's token MUST use `-` in place of whitespace characters, e.g.,
   `Acked-by` (this helps differentiate the footer section from a
   multi-paragraph body). An exception is made for `BREAKING CHANGE`, which MAY
   also be used as a token.
1. A footer's value MAY contain spaces and newlines, and parsing MUST terminate
   when the next valid footer token/separator pair is observed.
1. Breaking changes MUST be indicated in the type/scope prefix of a commit, or
   as an entry in the footer.
1. If included as a footer, a breaking change MUST consist of the uppercase text
   BREAKING CHANGE, followed by a colon, space, and description, e.g., _BREAKING
   CHANGE: environment variables now take precedence over config files_.
1. If included in the type/scope prefix, breaking changes MUST be indicated by a
   `!` immediately before the `:`. If `!` is used, `BREAKING CHANGE:` MAY be
   omitted from the footer section, and the commit description SHALL be used to
   describe the breaking change.
1. Types other than `feat` and `fix` MAY be used in your commit messages, e.g.,
   _docs: update ref docs._
1. The units of information that make up Conventional Commits MUST NOT be
   treated as case sensitive by implementors, with the exception of BREAKING
   CHANGE which MUST be uppercase.
1. BREAKING-CHANGE MUST be synonymous with BREAKING CHANGE, when used as a token
   in a footer.

### Formatting Requirements

In addition to the Conventional Commits specification, all commit messages MUST
adhere to the following formatting rules:

1. **Subject Line Limit:** The first line (type, scope, and description) MUST
   NOT exceed 50 characters in length. Do not add redundant words like "feat" or
   "bug" to the description if they are already present in the type prefix. Use
   the imperative mood (e.g., "add feature" not "added feature" or "adds
   feature").
2. **Body Wrapping:** All text within the commit body and footers MUST be
   hard-wrapped at 72 characters. This ensures that the commit message renders
   cleanly in standard `git log` output and other terminal-based tools that
   indent the commit body.

### The Commit Body

While the conventional commit prefix and description provide a concise summary
of _what_ changed, the commit body is a crucial tool for explaining the _why_.
Both human reviewers and future AI agents rely heavily on the commit body to
understand the context and rationale behind a modification. Therefore, you are
strongly encouraged to utilize the commit body to its fullest extent.

Use the commit body to clearly convey the overarching goals and motivations of
the change. If the problem being solved is complex, or if the constraints that
shaped the final implementation are not immediately obvious from reading the
code itself, explain them in detail here.

Furthermore, the commit body is an excellent place to document alternative
approaches that were considered and ultimately rejected. By discussing these
alternatives and the reasons for discarding them, you provide additional
information that prevents future contributors (both human and machine) from
second-guessing the chosen path or attempting to reimplement a flawed
alternative. Always err on the side of providing more information rather than
less; verbose, well-reasoned explanations are vastly preferable to sparse
commitments when dealing with non-trivial architectural or logical shifts.

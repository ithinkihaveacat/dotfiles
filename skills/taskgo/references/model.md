# taskgo rationale

This is a prototype; remove conventions that become ceremony.

The main reason for current-state Markdown is **context economics**: append-only
journals grow with project age, while rewritten state grows mainly with current
complexity. Historical reads may be expensive because they happen only on
demand.

This is not strict event sourcing. Markdown at `HEAD` is primary current state.
Git retains earlier states, diffs, ancestry and recorded-at metadata; commit
prose is explanation, not a validated event payload.

For enumerable fields, derive transitions by comparing historical blobs.
`status` can yield `(none) -> todo -> in-progress -> blocked -> done` without an
`Event:` claim that might disagree with the tree. Project/task identity normally
comes from paths/frontmatter. `Ref:` remains useful because an external commit,
PR, document revision or deployment is not derivable locally.

Commit bodies still matter for what fields cannot recover: evidence, rejected
hypotheses, and reasons a plan changed.

Git ancestry defines recorded sequence. Committer time is useful recorded-at
metadata, not necessarily real-world event time. A deliberate `reviewed:` date
is allowed when verification freshness itself matters. Shallow clones lack some
history; warn rather than invent it.

ADRs use the Nygard pattern: Status, Context, Decision, Consequences. A changed
accepted decision gets a replacement ADR; the old one remains readable at HEAD
and becomes superseded.

`STATUS.md` intentionally mixes hand-written semantic summary with a generated
task block. Mechanical status drift can therefore be detected; prose drift still
requires an agent. Privacy instructions are policy, not hard isolation:
sensitive workflows may need execution/tool boundaries between this private repo
and public destinations.

Prototype questions: Is history actually queried and answered correctly? Does
STATUS prose drift? Which metadata becomes ceremony? How often do concurrent
agents conflict? Does the commit helper justify its friction? Are stronger
privacy controls needed?

References:

- https://adr.github.io/
- https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions
- https://git-scm.com/docs/git-log
- https://git-scm.com/docs/git-interpret-trailers

The bundled `history` helper is deliberately path-oriented. Stable paths make it
reliable; after an exceptional rename, an agent may need raw `git log --follow`
archaeology rather than assuming the helper reconstructed pre-rename blobs.

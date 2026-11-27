# Criterion Skill Guidelines

This guide covers authoring, refactoring, and reviewing criterion skills
(`SKILL.md` files and their accompanying reference guides). A criterion skill
defines a verifiable quality or engineering bar that an app or system should
satisfy, explains how to check whether it holds across environments, and offers
guidance on how to build toward it.

Criterion skills are one of three skill types in this taxonomy:

- **Workflow skills** teach how to perform a class of task or operate a tool;
  see [Workflow Skill Guidelines](workflow-skills.md).
- **Criterion skills** (this guide) define a target bar an artifact should meet,
  how to verify it, and how to design for it (for example, energy-efficient
  sensor usage, smooth frame pacing, permission resilience across OS versions,
  or UX guideline conformance).
- **Knowledge skills** record current facts about particular systems, accounts,
  people, and places; see [Knowledge Skill Guidelines](knowledge-skills.md).

Criterion skills are reusable skills and follow the same shared rules as
workflow skills: the frontier-model bar, standalone portability and decoupling,
capability-first exemplars, anti-overfitting, outward-rounded empirical claims,
and bundled script conventions. See
[Workflow Skill Guidelines](workflow-skills.md) for those shared rules.

This guide clarifies and expands on the canonical Agent Skills specification and
authoring documentation at [agentskills.io](https://agentskills.io/); it is not
intended to conflict with it, and you do not need to read `agentskills.io` to
follow this guide. If an unintentional discrepancy arises, prefer
`agentskills.io` unless a deliberate practical amendment is explicitly noted
here.

## Intent and Audience

- **Goal:** Organize guidance around the end-user or system outcome an artifact
  must satisfy—spanning design, implementation, code review, and verification—so
  agents check and build for the bar from the start rather than treating testing
  as an afterthought.
- **Audience:** AI agents (as primary executors and reviewers) and engineers (as
  authors and maintainers).
- **Tone:** Direct, plain-English, and falsifiable. Lead with what must hold
  true and how to check it; leave room for multiple valid implementations.

## When to Write a Criterion Skill

Use a criterion skill when the target outcome cuts across the full development
lifecycle and frontier models routinely miss either the verification method or
non-obvious platform traps.

| Write a criterion skill for                                                  | Put elsewhere                                                                               |
| ---------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| Observable app or system bars (power efficiency, frame pacing, sync safety)  | Pure tool or test-harness procedures (booting emulators, OOBE, pairing) → workflow skill    |
| Cross-version OS behavior shifts where runtime failures happen silently      | Rules a compiler or linter already enforces deterministically (e.g. plain deprecation bans) |
| Traits that co-occur on the same code surface (e.g. Watch UI, gestures, AOD) | Single-metric micro-skills that force loading five skills for one screen                    |
| Verification gaps across emulator, debug, and retail devices                 | Facts about one specific repo, host, or account → knowledge skill                           |

Do not duplicate test-harness setup (such as emulator booting or device pairing)
inside a criterion skill. State the environment precondition using the
capability-first pattern (for example, *"On a provisioned device or paired
emulator..."*) and keep harness plumbing in a dedicated workflow skill.

## Structure: Goal, Verification, Implementation

Organize every criterion skill in three sections of decreasing prescriptiveness,
mirroring the `Goal → Criteria → Sketch` arc used in [TODO Items](todos.md):

1. **The Criterion (Goal):** State what a conforming app or system does in
   observable, falsifiable terms. Avoid vague aspirations (*"uses sensors
   sensibly"*, *"scrolling feels smooth"*). If a reviewer or agent could not
   check whether the bar is met, tighten the statement—or say what evidence
   would settle it.
1. **Verification (Most Prescriptive):** Give concrete, reliable ways to test,
   inspect, simulate, and measure whether the criterion holds.
   - **Distinguish environment tiers:** Explicitly separate what works on
     emulators, debug/development builds, and retail consumer devices. A test
     command that works only on an emulator or rooted device should never be
     presented as universal.
   - **Document platform blind spots with a fallback:** When an environment
     cannot verify a property natively (for example, retail devices blocking
     OS-level sensor injection or direct hardware power-rail reads), state the
     limitation neutrally and immediately name the best observable proxy,
     positive control, or debug-build seam. Leaving a gap without a fallback
     causes agents to invent non-existent commands or skip verification.
   - **Call out observer effects and false-positive traps:** Highlight checks
     that distort the state under test or mask a broken underlying path (such as
     shell mocks filtered out by anti-spoofing checks, or diagnostic commands
     that wake a frozen process).
1. **Implementation Guidance (Least Prescriptive):** Help agents build toward
   the criterion without locking them into one rigid design.
   - **Decision rules over tutorials:** Lead with power, reliability, or UX
     trade-off trees (for example, choosing the lowest-power platform API that
     fits the user journey) rather than textbook API syntax that frontier models
     already know.
   - **Explain platform asymmetries once:** When models routinely pick the wrong
     default or hit subtle lifecycle bugs, explain the underlying mechanism once
     with its *why* instead of scattering repeated all-caps bans.
   - **Close retail verification gaps with testability seams:** Show lightweight
     architectural seams (such as abstracting hardware providers behind an
     interface or debug-only replay hook) that make the criterion testable on
     real consumer hardware.

## Naming and Triggering

- **Name after the outcome or surface, not the SDLC phase:** Use names like
  `wear-sensor-efficiency` or `wear-background-connectivity`, not
  `wear-sensor-testing` or `android-audit`. Phase-named skills stay dormant when
  an agent is designing or implementing a feature.
- **Trigger across the full lifecycle:** State the engineering bar and domain
  surfaces in the YAML `description`, then close with a broad developer action
  clause—for example: *"Use when designing, implementing, reviewing, debugging,
  or verifying..."*
- **Keep triggers anchored on developer work:** Pair technical surfaces and
  developer verbs so removing words like *"testing"* does not cause the skill to
  fire on unrelated consumer or general-knowledge questions.

## Summary Checklist

Before publishing or committing a criterion skill, verify that:

- [ ] Every shared reusable-skill check in
  [Workflow Skill Guidelines](workflow-skills.md#summary-checklist) passes
  (frontier-model bar, standalone portability, anti-overfitting, approximate
  empirical figures, and script rules).
- [ ] The opening criterion states observable, falsifiable conditions rather
  than vague aspirations.
- [ ] Verification distinguishes environment tiers (such as emulator, debug
  build, and retail consumer device) and pairs every platform blind spot with an
  observable proxy, positive control, or debug seam.
- [ ] Implementation guidance focuses on decision rules, non-obvious platform
  traps, and testability seams rather than textbook API tutorials.
- [ ] Rules enforceable deterministically by a compiler or linter are left to
  tooling rather than prose.
- [ ] The skill name and `description` reflect the outcome or domain and trigger
  across design, implementation, review, debugging, and verification.

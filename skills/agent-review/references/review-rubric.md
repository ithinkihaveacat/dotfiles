# Review Rubric

## Finding threshold

Report an issue only when all of these are true:

1. The change introduced it; do not report pre-existing defects.
1. It has a concrete impact on correctness, security, performance, reliability,
   or maintainability.
1. It is discrete and actionable.
1. A specific input, environment, or execution path demonstrates the impact.
1. The affected code or invariant is identifiable from repository evidence, not
   speculation about possible callers.
1. It is not merely an intentional behavior change described by the request or
   repository instructions.
1. The author would probably fix it after seeing the evidence.

Do not report:

- Style, formatting, naming, or documentation nits unless they create a real
  behavioral or maintenance defect.
- Broad refactoring preferences.
- Missing tests without an accompanying behavior risk introduced by the change.
- Hypothetical compatibility problems without an affected caller or supported
  environment.
- Findings outside the requested diff.

Do not stop after the first issue. Return every independent issue that clears
the threshold, then deduplicate findings that share the same defect and remedy.

## Repository rules

Apply the root and scoped instruction files governing each changed file.
More-specific rules win. A rule supports a finding only when it supplies a
repository-specific invariant, scope, remedy, or validation requirement beyond
generic correctness advice.

When a rule materially supports a finding, cite the smallest useful line range
from that instruction file in the finding body. Do not invent citations or
report an issue solely because a rule exists.

## Review comments

For each finding:

- Start the title with a priority tag.
- Use an imperative title of at most 80 characters.
- Explain the concrete failure and the conditions that trigger it.
- Keep the body to one compact paragraph.
- Use the shortest changed-line range that identifies the defect, normally no
  more than 5–10 lines.
- Put location metadata in the location field, not redundantly in the body.
- Do not include praise, filler, or a patch.

Priority meanings:

- **P0:** Universal release blocker or severe data/security impact requiring
  immediate action.
- **P1:** Urgent defect that should be fixed in the next cycle.
- **P2:** Normal actionable defect.
- **P3:** Low-impact defect that is still clearly worth fixing.

## Output

Return findings first, ordered by priority, then an overall verdict.

```text
1. [P1] <imperative title>
   <path>:<start-line>
   <one-paragraph explanation>

2. [P2] <imperative title>
   <path>:<start-line>
   <one-paragraph explanation>

Overall verdict: patch is correct | patch is incorrect
Explanation: <one to three sentences>
Confidence: <0.0–1.0>
```

If no finding qualifies, return:

```text
No findings.

Overall verdict: patch is correct
Explanation: <one to three sentences>
Confidence: <0.0–1.0>
```

"Patch is correct" means existing behavior and tests should continue to work and
no qualifying defect was found. Ignore non-blocking nits when choosing the
verdict.

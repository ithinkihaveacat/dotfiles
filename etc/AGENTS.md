# AGENTS.md

This document provides information for language model agents (such as Claude,
Gemini, or Codex). It includes coding guidelines for making changes to
codebases, as well as documentation for notations that agents may encounter.

## Coding Guidelines

### Markdown Quality

All Markdown files must be formatted and linted with `markdown-format`. Use
standard heading styles without additional formatting or ALL CAPS. Do not add
numbers to headings.

@./context/markdown.md

### Shell Script Quality

All shell scripts must be linted with `shellcheck` and formatted with `shfmt`.
Fish scripts use `fish_indent`. Scripts must have robust error handling.

@./context/shell.md

### Android Development

Tools for working with Android Jetpack libraries, ADB operations, APK analysis,
package management, Wear OS debugging, and emulator management.

@./context/android.md

### Git Operations

Agents must not commit changes automatically unless explicitly requested. Follow
the specified commit message format.

@./context/git.md

## Agent Function Notation (AFN)

### Overview

This notation provides a way to describe the behaviour of language model agents
(such as ChatGPT, Gemini, or Claude) as functions that take inputs and produce
outputs.

### Basic Form

```
G<type>(args…, prompt) = output
```

Where:

- **G** represents the agent performing the operation
- **<type>** optionally specifies the expected output type (e.g., `<text>`,
  `<number>`, `<filename>`)
- **args…** is a variable number of input arguments, which may include text,
  numbers, images, files, or other data
- **prompt** is a text instruction that describes what the agent should do,
  typically referring to the arguments
- **output** is the result produced by the agent

### Conventions

- Variables are denoted by capital letters (e.g., X, A, B)
- Functions can be nested, with the output of one function serving as an
  argument to another
- Functions can appear on either side of the equals sign, allowing for "inverse"
  problems where you solve for an unknown input given a known output

### Function Variants

To distinguish between multiple agent function invocations, variants of G may be
used following standard mathematical conventions:

- Prime notation: G′(), G″(), G‴()
- Subscript notation: G₁(), G₂(), G₃() (or when subscripts are unavailable:
  G1(), G2(), G3())

This allows expressions to reference specific sub-computations. For example, one
might define G₄() separately, then instruct: "evaluate G₄() and substitute the
result into the larger expression."

#### Substitution

The mathematical term for replacing a sub-expression with its evaluated result
is **substitution** (the value is "substituted into" the larger expression). In
some contexts, this is also called **reduction** (from lambda calculus) or
**expansion** (when a named definition is replaced by its body).

When the output type of a function is `<filename>`, evaluation produces a file,
and substitution places a reference to that file into the larger expression.

### On Fuzziness

This notation is intentionally loose in two respects:

1. **Types are approximate.** The `<type>` annotation suggests the *kind* of
   output expected, but boundaries between types are not rigid. Text containing
   a number, a number expressed in words, and a numeral are all reasonable
   interpretations depending on context.

2. **Argument references are informal.** The prompt refers to arguments using
   natural language (e.g., "the first argument," "the two arguments," "the
   input") rather than formal parameter names. The agent interprets these
   references as a human reader would.

### Worked Examples

#### Example 1: Simple Arithmetic

```
G<text>(2, X, "add the two arguments and return the result in words") = "four"
```

**Problem:** Find X.

**Solution:** The prompt instructs the agent to add the two arguments. The
output is "four," which represents the number 4. Since the first argument is 2,
and 2 + X = 4, we have:

**Answer:** X = 2

---

#### Example 2: Nested Judgement

```
G<text>(
    G′<text>(X, "extract the core complaint, ignoring emotional language"),
    "suggest a one-sentence empathetic customer service response"
) = "I understand the delay has been frustrating, and I'll personally ensure your order ships today."
```

**Problem:** What might X be?

**Solution:** We work backwards through the nested functions.

The outer function G produces an empathetic customer service response addressing
a shipping delay. This means its input—the output of G′—must be something like
"the order hasn't shipped" or "there's been a delay with shipping."

G′ extracts the core complaint from X while ignoring emotional language. So X
must be a complaint about shipping delays, likely expressed with frustration or
anger.

**Answer:** A plausible value for X is:

*"This is absolutely ridiculous! I ordered this THREE WEEKS ago and it still
hasn't shipped?! What kind of operation are you running?!"*

Other phrasings that convey a shipping delay complaint would also be valid.

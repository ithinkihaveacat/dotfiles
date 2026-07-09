# CLI Design Standard

The baseline for every CLI tool in this repo is
[clig.dev](https://clig.dev/) (see also <https://clig.dev/llms.txt>). Read
that document first — it already covers argument parsing, help text content,
output streams, color/`NO_COLOR`, progress indication, prompting, signals,
configuration precedence, environment variables, and naming. This file does
not restate any of it.

What follows is the **local delta**: amendments that clig.dev does not cover,
plus the few places this repo deliberately diverges from clig.dev's
recommendation. Where this delta is silent, follow clig.dev.

## Command Structure: Fixed Verb-Noun Order

clig.dev permits either `noun verb` (`docker container create`) or
`verb noun`, as long as a tool is internally consistent. This repo fixes one
order for its `kubectl`-style tools: **`tool [verb] [noun] [flags]`**.

- **Verbs** describe the action (e.g., `list`, `create`, `delete`, `update`).
- **Nouns** describe the resource being acted upon (e.g., `user`, `config`,
  `database`).
- **Verb Consistency:** Do not switch verbs for similar actions. If `list` is
  used for users, do not use `get` for databases.

| ✅ **Do This**                    | ❌ **Avoid This**                                           |
| --------------------------------- | ------------------------------------------------------------ |
| `tool create user --name="alice"` | `tool create-user --name="alice"` (hyphenated commands)      |
| `tool list databases`             | `tool show-dbs` (inconsistent verb/abbreviation)              |
| `tool delete config --id=5`       | `tool remove config -i 5` (synonyms like remove vs. delete)   |

For simpler, focused tools that don't warrant the full `kubectl` structure,
use one of the two specialized patterns in Appendix A instead.

## Vocabulary Standard

clig.dev doesn't prescribe domain vocabulary. This repo does, so that once a
user learns one tool's verbs they transfer to every other tool:

### Listing: Local vs. Available State

When a tool manages resources that can be installed or configured locally from
a larger set of obtainable resources, use distinct commands:

- **`list`**: Shows resources currently active, installed, or managed locally
  (on-disk state).
- **`catalog`**: Shows all resources available to be obtained or installed
  (remote/registry state).
- **Vocabulary Rule**: Never use the word "available" to describe resources
  that are already locally present or installed.
- **Single-List Exception**: If obtainable and installed resources are views of
  one underlying list, use a single list command with a state column (e.g.,
  `adb-tiles` marking carousel members with `C`) and a filter flag (e.g.,
  `--carousel-only`).

This applies to tools exposing both an installed set and an obtainable set. A
single-set utility that only enumerates the obtainable set should still call
it `catalog` (as a subcommand or `--catalog` flag), not `list`/`--list`, to
stay consistent with tools like `skill`.

### Diagnostics: `doctor` vs. `status`

Distinguish between environmental health and resource progress:

- **`doctor`**: Use for diagnostics, environment checks, and drift detection
  (e.g., "is my environment set up correctly?").
  - `doctor` must be read-only and must exit non-zero if it finds problems.
  - If a legacy `status` command exists for diagnostics, keep it as a hidden
    alias to avoid breaking callers, but advertise `doctor` as canonical.
- **`status`**: Reserve for reporting the state or progress of a specific
  named resource (e.g., `socrates status <db>` showing progress of a run).
- **Avoid** using `check`, `verify`, or `validate` as command names for these
  operations.

#### Canonical `doctor` Output Style

Every `doctor` command renders findings the same way: bracketed, uppercase,
plain-ASCII tags — `[OK]`, `[INFO]`, `[WARN]`, `[ERROR]` — left-padded to a
common width so lines align, e.g.:

```text
[OK]    Workspace: Git repository
[WARN]  Low disk space: 3.2G available at ANDROID_HOME
[ERROR] Required Skills: Mismatched skill configuration (1 missing)
```

- Tags are greppable and fully legible with color stripped (`... | grep
  '^\[WARN\]'`), which satisfies clig.dev's `NO_COLOR`/non-TTY rule for free.
  Never use glyph-only tags (`✓`/`!`/`✗`) as the sole carrier of status —
  glyphs degrade to ambiguous punctuation once color is removed.
- Color may still be layered onto the tags when stdout is a TTY, as an
  enhancement, per clig.dev's color rules — never as the only signal.
- **Remediation placement:** attach the fix directly under the finding it
  belongs to (indented detail lines), not collected into a trailing summary
  section — findings scroll off-screen away from a trailing "how to fix"
  block otherwise. A one-line closing success/failure summary is fine.
- Exit contract: read-only, non-zero exit on any `WARN`/`ERROR` finding.

### Resource Management Verb Pairs

Choose command verbs that accurately reflect the operation and domain:

- **`create` / `delete`**: Use for resources the tool **authors or destroys**
  (e.g., AVD instances).
- **`add` / `remove`**: Use for managing **membership in a set** (e.g., tiles
  in a carousel, skills in a repo). Always support **`rm`** as an alias for
  `remove`.
- **`install` / `uninstall`**: Use for **packages** or software installations.
- **`set`**: Use for **single-slot replacement** of an active selection (e.g.,
  the active watch face). Do not use `add` if there is only one slot.

## Exit Codes: Local Extensions

clig.dev only requires zero-on-success, non-zero-on-failure. This repo fixes
specific non-zero values:

- `0`: success, including an explicit help request (`--help`, `-h`, `help`, or
  bare `tool` for complex subcommand tools).
- `1`: general/usage errors.
- `127`: a required command-line dependency is missing (see `require()` in
  `shell.md`).
- `130` / `143`: SIGINT / SIGTERM, with a single newline written to stderr
  first (guarded against write errors) so the TTY-echoed `^C` doesn't mangle
  the next shell prompt, and no stack trace or crash dump. A unified handler
  that always exits `130` is acceptable.

## Output Format Defaults

clig.dev asks for human-readable-by-default output and a way to opt into
machine-readable output, but doesn't prescribe a house style. This repo's
interpretation:

- **State changes:** report them git-style — brief, one line per
  changed/created/deleted thing, to stderr unless it's the requested data.
- **Long-running operations:** rsync-style single updating line (`\r`, no
  trailing newline until completion), format `[Progress Bar] 45% | 12.5MB/s |
  ETA: 00:15`; fall back to periodic log lines (e.g., every 10%) when stdout
  is not a TTY.
- **`doctor` output:** the canonical tag style above.

## `--output`/`-o` Contract

Any script that produces a new file or directory as output must support an
`--output` switch (clig.dev's standard flag name is `-o`; support both) so
callers can redirect it, e.g. to a temp directory:

- If the specified path does not exist, the tool creates it.
- If the output is a directory, the tool must not delete it on success —
  cleanup is the caller's responsibility. Only delete a temp directory the
  tool created itself, and only on failure.

## Where This Repo Follows clig.dev (previously did not)

The following clig.dev rules are now this repo's rule, superseding the prior
local standard:

- **`-h` is a help alias.** Every script accepting `--help` also accepts `-h`
  with identical output and exit code (unless `-h` is already claimed for
  `--human-readable`, in which case clig.dev's rule wins and the
  human-readable flag gets a different letter — no script in this repo
  currently has that collision).
- **Concise help on missing required arguments.** A tool invoked without
  required arguments prints a brief description, one or two examples, and a
  pointer to `--help` — not full help text, and not only "Try --help".
- **Pagers are permitted**, guarded per clig.dev (`less -FIRX`, only when
  stdout is a TTY), though rarely warranted for these tools' output sizes.

## Not Applicable

Treated as not applicable to this repo's personal utility scripts, per
clig.dev's own guidance to adapt to context: `--version` and support/docs
links in help text (no versioned releases or public support channel), and the
distribution/analytics sections (single-machine dotfiles, not installed
packages).

## Appendix A: Specialized Patterns for Focused Tools

While the **Standard Pattern** (`tool [verb] [noun]`) is ideal for complex
platforms (like `kubectl` or `aws`), it is often too verbose for focused
tools. For these, we recognize two valid simplified patterns.

### Type 1: The Domain-Centric Tool (The "Manager" Pattern)

_Use this when your tool manages a **single domain** but supports **multiple
actions**._

- **Concept:** The tool's name acts as the **Noun**. The first argument is the
  **Verb**.
- **Syntax:** `[Noun-Tool] [Verb] [Instance]`
- **Example:** `packagename launch com.foo`
- **Implicit Meaning:** "(On the domain of) **packagename**, **launch** the
  instance **com.foo**."

The first argument must be a verb; the `[Instance]` may be omitted, as in
`skill doctor`.

#### Reference Implementation: `packagename`

```text
Usage: packagename <command> [arguments]

Commands:
  Process/Lifecycle:
    launch               Launch an application's main activity
    force-stop           Force stop an application
  Information:
    dumpsys              Display dumpsys package information
    version              Get the version name and code
  Package Management:
    pull                 Pull the APK file from the device
    uninstall            Uninstall a package

Options:
  --help                 Display this help message and exit

```

### Type 2: The Action-Centric Tool (The "Utility" Pattern)

_Use this when your tool performs exactly **one primary action**._

- **Concept:** The tool's name acts as the **Verb**. The first argument is the
  **Target/Noun**.
- **Syntax:** `[Verb-Tool] [Instance] [Arguments]`
- **Example:** `apk-cat-file app.apk AndroidManifest.xml`
- **Implicit Meaning:** "**Extract and display** from `app.apk` the file `AndroidManifest.xml`."

#### Reference Implementation: `apk-cat-file`

```text
Usage: apk-cat-file APK_FILE FILE_PATH

Extracts and displays a file from an Android APK or app bundle.

The script supports both standalone APKs and ZIP archives containing split APKs.
It automatically formats XML files for readability.

Arguments:
  APK_FILE    Path to an APK file or ZIP archive.
  FILE_PATH   Path to the file within the APK to extract.

Options:
  --help  Display this help message and exit
```

# CLI Design Specification: "The Predictable Standard"

## 1. Core Command Structure: The "Verb-Noun" Pattern

To ensure predictability and discoverability, the primary standard for new tools is the hierarchical **Verb-Noun** syntax found in Kubernetes (`kubectl`).

### 1.1 The Rule

Every standard command must follow the format:
`tool [verb] [noun] [flags]`

* **Verbs** describe the action (e.g., `list`, `create`, `delete`, `update`).
* **Nouns** describe the resource being acted upon (e.g., `user`, `config`, `database`).

### 1.2 Rationale

This structure reduces the cognitive load on the user. Once a user learns how to `list` one type of resource, they intuitively know how to `list` any other resource.

### 1.3 Examples

| ✅ **Do This (Kubectl Style)** | ❌ **Avoid This (Legacy Style)** |
| --- | --- |
| `tool create user --name="alice"` | `tool create-user --name="alice"` (Hyphenated commands) |
| `tool list databases` | `tool show-dbs` (Inconsistent verb/abbreviation) |
| `tool delete config --id=5` | `tool remove config -i 5` (Synonyms like remove vs delete) |

### 1.4 Contextual Consistency

* **Global Flags:** Flags that apply to the binary itself (e.g., `--verbose`, `--config`) must be parsed *before* the verb or accepted globally.
* **Verb Consistency:** Do not switch verbs for similar actions. If `list` is used for users, do not use `get` for databases. Pick one (e.g., `list` for summaries, `get` for single items) and stick to it.

---

## 2. The Help System

The help system allows users to learn the tool without leaving the terminal. It prioritizes immediate utility over exhaustive documentation.

### 2.1 The "Dual Mode" Standard

We follow the modern consensus (seen in `docker` and `cargo`) where `help` is a first-class command, but we **reject** the `git` distinction between summary and manual.

**Behavior:**

1. **Interchangeable Invocation:**
    * `tool help` and `tool --help` must produce **identical output**.
    * `tool help [command]` and `tool [command] --help` must produce **identical output**.

2. **No Pagers:**
    * **Negative Example:** Unlike `git`, the tool generally **must not** launch a pager (`less`) or open a browser (`man` page).
    * **Rationale:** Help output should be printed to `stdout` so it can be grepped (e.g., `tool help list | grep -- --json`).

3. **Context Aware:**
    * `tool --help`: Shows available **verbs**.
    * `tool [verb] --help`: Shows available **nouns** for that verb.
    * `tool [verb] [noun] --help`: Shows specific flags for that operation.

### 2.2 The `-h` Constraint (The GNU Convention)

We strictly follow the GNU Coreutils philosophy regarding the short flag `-h`.

* **Rule:** **`-h` DOES NOT trigger help.**
* **Rationale:** In the Unix ecosystem (e.g., `ls`, `du`, `df`), `-h` stands for "Human Readable" (converting bytes to KB/MB). Using `-h` for help creates dangerous ambiguity.
* **Implementation:**
    * If the command involves sizes or data, reserve `-h` for `--human-readable`.
    * If the command does not involve sizes, leave `-h` **undefined** or return an error suggesting `--help`.
    * **Negative Example:** Do not behave like `git commit -h` (which prints a summary).

---

## 3. Exit Codes: The "Explicit vs. Implicit" Rule

The tool must communicate success or failure clearly via exit codes to support scripting and CI/CD pipelines.

### 3.1 Scenario A: Explicit Request (Success)

If the user *asks* for help, the tool has successfully fulfilled the request.

* **Input:** `tool --help` OR `tool help`
* **Output:** Help text to `stdout`.
* **Exit Code:** `0` (Success)
* **Why:** This allows users to pipe help text (e.g., `tool help | grep "version"`).

### 3.2 Scenario B: Implicit Failure (User Error)

If the tool displays help because the user typed a command incorrectly, the tool has failed.

* **Input:** `tool --invalid-flag`
* **Output:**
    1. Short error message to `stderr` ("Unknown flag: --invalid-flag").
    2. Brief usage summary (or "Try 'tool --help' for details").
* **Exit Code:** `> 0` (e.g., `1` or `127`).
* **Why:** This ensures scripts stop executing if a command is malformed.

---

## 4. Output, Logging & Progress

The tool must respect the user's terminal space and distinguish between "data" and "information."

### 4.1 Long-Running Operations (The `rsync` Standard)

For operations taking longer than 2 seconds (e.g., `download`, `backup`, `sync`), do not flood the console with new lines for every percentage point.

* **Behavior:** Use a **single updating line** (carriage return `` without newline `
`) to show progress.
* **Format:** `[Progress Bar] 45% | 12.5MB/s | ETA: 00:15`
* **Completion:** When the task finishes, print a newline so the cursor moves to the next line, preserving the final stats.
* **Non-TTY Fallback:** If the tool detects it is being piped (not a TTY), disable the progress bar and print periodic log lines instead (e.g., every 10%).

### 4.2 Data vs. Logging

* **Stdout:** Strictly for the *requested data* (e.g., the JSON output of a resource, the list of items).
* **Stderr:** All logs, progress bars, status messages, and errors.
* **Benefit:** This allows users to cleanly pipe data without cleaning up logs:
`tool list users > users.json` (Progress bars and "Fetching users..." logs appear on screen but are not saved to the file).

---

## Appendix A: Specialized Patterns for Focused Tools

While the **Standard Pattern** (`tool [verb] [noun]`) is ideal for complex platforms (like `kubectl` or `aws`), it is often too verbose for focused tools. For these, we recognize two valid simplified patterns.

### Type 1: The Domain-Centric Tool (The "Manager" Pattern)

*Use this when your tool manages a **single domain** but supports **multiple actions**.*

* **Concept:** The tool's name acts as the **Noun**. The first argument is the **Verb**.
* **Syntax:** `[Noun-Tool] [Verb] [Instance]`
* **Example:** `packagename launch com.foo`
* **Implicit Meaning:** "(On the domain of) **packagename**, **launch** the instance **com.foo**."

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

*Use this when your tool performs exactly **one primary action**.*

* **Concept:** The tool's name acts as the **Verb**. The first argument is the **Target/Noun**.
* **Syntax:** `[Verb-Tool] [Instance]`
* **Example:** `context gemini-api`
* **Implicit Meaning:** "**Generate context** for **gemini-api**."

#### Reference Implementation: `context`

```text
Usage: context <topic> [options]

Generate aggregated context for a specific topic.

Topics:
  gemini-api             Gemini API documentation and examples
  mcp-server             MCP server documentation and specification

Options:
  --help                 Display this help message and exit
  --force                Force cache rebuild

```

---

## Summary Checklist for Developers

| Feature | Implementation Requirement | Reference |
| --- | --- | --- |
| **Structure** | `tool [verb] [noun]` (Unless specialized). | `kubectl` |
| **Short Help** | `-h` is **FORBIDDEN** for help. | GNU Coreutils |
| **Long Help** | `--help` prints to `stdout`. | `docker` |
| **Help Cmd** | `help` is an alias for `--help`. | `cargo` |
| **Pager** | Never launch `less` or `man`. | Anti-`git` |
| **Exit Code** | `0` for requested help, `1` for syntax error. | POSIX |
| **Progress** | Single updating line (CR), no scrolling logs. | `rsync` |
| **Streams** | Data to `stdout`, Logs/Progress to `stderr`. | Standard Unix |

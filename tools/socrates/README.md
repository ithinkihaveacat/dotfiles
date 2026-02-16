# Socrates

Identify **validated knowledge gaps** in large language models.

Socrates analyzes reference material and generates questions designed to expose
information that an LLM genuinely doesn't know. It uses a SQLite-backed
workflow to decouple generation, answering, and evaluation, allowing for
flexible testing scenarios including offline and human-in-the-loop workflows.

## Workflow

Socrates uses a multi-stage pipeline:

1.  **Generate**: An advanced model (Gemini 3 Pro) analyzes source text to extract
    likely novel facts and generates questions. These are stored in a local
    SQLite database.
2.  **Answer**: Questions are answered by a target. This can be an LLM (e.g.,
    Gemini 2.5 Flash), a shell script, or a human (interactive mode).
3.  **Score**: An advanced judge model evaluates the answers against the ground
    truth.
4.  **Report**: A markdown report is generated from the database.

## Installation & Usage

### 1. System Integration (Recommended)

If you are using the dotfiles environment, simply run the update script. This
will build the tool and install it to `~/.local/bin/socrates`.

```bash
./update
```

### 2. Standalone Installation

If you only want to install this specific tool globally on your system:

```bash
npm install -g .
```

### 3. Local Execution

To run the tool directly from the source directory without installing it:

```bash
npm install
npm run build
node dist/index.js --help
```

> **Note:** The `socrates` tool relies on the `better-sqlite3` native module,
> which cannot be bundled. Therefore, the `node_modules` directory must be
> present and populated (via `npm install`) for `dist/index.js` to work.

## Usage

```text
socrates <command> [OPTIONS]
```

### Commands

| Command    | Description                                      |
| ---------- | ------------------------------------------------ |
| `generate` | Generate questions from stdin into a new DB.     |
| `answer`   | Answer questions (accepts DB path or Session ID).|
| `score`    | Evaluate answers (accepts DB path or Session ID).|
| `status`   | Show progress (accepts DB path or Session ID).   |
| `report`   | Generate Report (accepts DB path or Session ID). |

### Examples

#### 1. Generate Questions
Read documentation and generate questions.
This creates a new SQLite database and prints the Session ID.

```bash
cat documentation.md | socrates generate "Security"
# Output: /path/to/db/5fb15139-Security.db
# Session ID: 5fb15139-Security
```

If no topic is provided, an AI-generated slug is used:

```bash
cat documentation.md | socrates generate
# Session ID: 5fb15139-wear-os-security
```

#### 2. Answer Questions
You can refer to the database by its full path or its Session ID (e.g. `5fb15139-Security` or even just `5fb15139`).

Use an LLM to answer the questions:

```bash
socrates answer 5fb15139 --mode model:gemini-2.5-flash
```

Use a shell script (e.g., to test a CLI tool):

```bash
socrates answer 5fb15139 --mode shell:./my-tool-wrapper.sh
```

Manually answer questions:

```bash
socrates answer 5fb15139 --mode interactive:manual
```

#### 3. Score Answers
Evaluate the accuracy of the answers using the judge model:

```bash
socrates score 5fb15139
```

#### 4. Generate Report
Output the final analysis to Markdown:

```bash
socrates report 5fb15139 > analysis.md
```

### Environment Variables

| Variable         | Description                    |
| ---------------- | ------------------------------ |
| `GEMINI_API_KEY` | Required. Your Gemini API key. |
| `XDG_DATA_HOME`  | Optional. Base directory for DB storage (default: `~/.local/share`). |

## Output

The `report` command outputs a markdown report to stdout with:

- **Summary Table**: Overview of pass/fail rates.
- **Detailed Analysis**: Per-question breakdown with ground truth, rationale, and the model's response and critique.

Progress messages are written to stderr.

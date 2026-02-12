# Socrates

Identify **validated knowledge gaps** in large language models.

Socrates analyzes reference material and generates questions designed to expose
information that an LLM genuinely doesn't know. It validates each question by
testing it against a target model, then uses a judge model to evaluate whether
the response was correct.

## How It Works

Socrates uses a three-stage "Socratic" pipeline to identify genuine knowledge
gaps:

1. **Hypothesis Generation (The Miner):** An advanced model (Gemini 3 Pro)
   analyzes the source text to extract facts that are likely novel,
   counter-intuitive, or "gotchas." It generates questions targeting these
   specific facts. It does _not_ verify the gaps; it only hypothesizes that they
   exist.

2. **Blind Testing (The Subject):** The target model (Gemini 2.5 Flash) attempts
   to answer these questions _without_ access to the source text. This tests the
   model's intrinsic knowledge.

3. **Adjudication (The Judge):** The advanced model compares the Subject's
   answer against the Ground Truth (from step 1). If the Subject fails to answer
   correctly, the fact is confirmed as a "Validated Unknown."

4. **Report**: Outputs a markdown report categorizing questions into "Confirmed
   Unknowns" (the model failed) and "False Alarms" (the model knew the answer).

## Installation & Usage

There are three ways to use Socrates:

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

## Usage

```text
socrates [OPTIONS] [TOPIC_FOCUS] < INPUT_FILE
```

### Options

| Option          | Description                                  |
| --------------- | -------------------------------------------- |
| `-h, --help`    | Display help message and exit                |
| `--questions N` | Number of questions to generate (default: 7) |

### Arguments

| Argument      | Description                                      |
| ------------- | ------------------------------------------------ |
| `TOPIC_FOCUS` | Optional. A specific area to focus questions on. |

### Environment Variables

| Variable         | Description                    |
| ---------------- | ------------------------------ |
| `GEMINI_API_KEY` | Required. Your Gemini API key. |

## Examples

Analyze documentation for knowledge gaps:

```bash
cat documentation.md | socrates "Security"
```

Quick test with fewer questions:

```bash
cat api-spec.md | socrates --questions 2 "Error Handling"
```

## Output

The tool outputs a markdown report to stdout with two sections:

- **Confirmed Unknowns**: Questions the model answered incorrectly, proving the
  information is novel to the model.
- **False Alarms**: Questions the model answered correctly, meaning this
  information is already known.

Progress messages are written to stderr.

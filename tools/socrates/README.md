# Socrates

Identify **validated knowledge gaps** in large language models.

Socrates analyzes reference material and generates questions designed to expose
information that an LLM genuinely doesn't know. It validates each question by
testing it against a target model, then uses a judge model to evaluate whether
the response was correct.

## How It Works

1. **Question Generation**: An evaluator model (Gemini 3 Pro) analyzes your
   input text and generates "gotcha" questions—questions where an expert relying
   on standard knowledge would likely answer incorrectly, but the correct answer
   is in your text.

2. **Testing**: Each question is asked to a target model (Gemini 2.5 Flash)
   without any context from your input.

3. **Validation**: A judge evaluates each response against the ground truth from
   your text, identifying genuine knowledge gaps vs false alarms.

4. **Report**: Outputs a markdown report categorizing questions into "Confirmed
   Unknowns" (the model failed) and "False Alarms" (the model knew the answer).

## Installation

```bash
npm install
npm run build
```

For global installation:

```bash
npm install -g .
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

## Development

Build the project:

```bash
npm run build
```

Run directly after building:

```bash
node dist/index.js --help
```

The TypeScript compiler is configured with `strict: true`, so the build will
fail on type errors.

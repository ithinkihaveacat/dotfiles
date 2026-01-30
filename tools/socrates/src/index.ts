#!/usr/bin/env node

import { GoogleGenAI, Type } from "@google/genai";

// Type definitions
interface Question {
  question: string;
  answer: string;
  rationale: string;
}

interface EvalResult {
  is_correct: boolean;
  summary: string;
  critique: string;
}

interface ValidationResult {
  question: Question;
  candidateAnswer: string;
  evalResult: EvalResult;
}

// Constants
const TARGET_MODEL = "gemini-2.5-flash";
const EVALUATOR_MODEL = "gemini-3-pro-preview";
const DEFAULT_QUESTION_COUNT = 7;

const SCRIPT_NAME = "socrates";

// CLI helpers
function usage(): void {
  console.log(`Usage: ${SCRIPT_NAME} [OPTIONS] [TOPIC_FOCUS]

Identifies "Validated Unknowns": Information in the input text that is strictly
novel and provably unknown to the target model (Gemini 2.5 Flash).

Arguments:
  TOPIC_FOCUS       Optional. A specific area to focus the questions on.

Input:
  stdin             The reference material (text) to analyze.

Options:
  -h, --help        Display this help message and exit
  --questions N     Number of questions to generate (default: ${DEFAULT_QUESTION_COUNT})

Environment:
  GEMINI_API_KEY    Required. Your Gemini API key.

Examples:
  cat documentation.md | ${SCRIPT_NAME} "Security"
  cat docs.md | ${SCRIPT_NAME} --questions 3 "API Design"`);
  process.exit(0);
}

function error(message: string): never {
  console.error(`${SCRIPT_NAME}: ${message}`);
  process.exit(1);
}

// Parse CLI arguments
function parseArgs(): { topicFocus: string; questionCount: number } {
  const args = process.argv.slice(2);
  let questionCount = DEFAULT_QUESTION_COUNT;
  let topicFocus = "Generate challenging questions based on novel information.";

  for (let i = 0; i < args.length; i++) {
    const arg = args[i];

    if (arg === "-h" || arg === "--help") {
      usage();
    } else if (arg === "--questions") {
      const next = args[++i];
      if (!next || isNaN(parseInt(next, 10))) {
        error("--questions requires a numeric argument");
      }
      questionCount = parseInt(next, 10);
      if (questionCount < 1) {
        error("--questions must be at least 1");
      }
    } else if (arg.startsWith("-")) {
      error(`unknown option: ${arg}`);
    } else {
      topicFocus = arg;
    }
  }

  return { topicFocus, questionCount };
}

// Read all stdin
async function readStdin(): Promise<string> {
  // Check if stdin is a TTY (no piped input) - show help
  if (process.stdin.isTTY) {
    usage();
  }

  return new Promise((resolve, reject) => {
    let data = "";
    process.stdin.setEncoding("utf8");
    process.stdin.on("data", (chunk) => (data += chunk));
    process.stdin.on("end", () => resolve(data));
    process.stdin.on("error", reject);
  });
}

// Generate questions using the evaluator model
async function generateQuestions(
  ai: GoogleGenAI,
  inputData: string,
  topicFocus: string,
  questionCount: number
): Promise<Question[]> {
  console.error("Thinking... (Generating candidate questions)");

  const systemInstruction = `Analyze the provided reference material and generate exactly ${questionCount} questions that verify whether the text contains genuinely novel, unexpected, or counter-intuitive information.

### Core Task
Generate questions that satisfy the "Gotcha" condition:
**An expert in the general field relying on standard industry knowledge would likely answer incorrectly, but the correct answer is explicitly contained in the provided text.**

### CRITICAL: Context & Fairness
*   **Self-Contained Questions:** The questions will be asked to a model *without* the provided text. You MUST include all necessary context in the question itself.
*   **Specify Versions/Platforms:** If the information is specific to "Wear OS 5" or "Jetpack Tiles 1.4", you **must** explicitly state this in the question.
    *   *Bad:* "What is the limit for animated elements?" (Which system? Which version?)
    *   *Good:* "In Wear OS Tiles API v1.4, what is the hard limit on simultaneously animated elements?"

### Constraints & Mandates
1.  **Source Material Restrictions:**
    *   **Ignore Code Snippets:** Do not formulate questions based on code blocks, variable names, or syntax.
    *   **Ignore Illustrative Examples:** Do not use "For example..." scenarios or sample values.
    *   **Focus on Normative Text:** Derive questions only from the main narrative defining core rules, architecture, and behaviors.

2.  **Question Quality:**
    *   **Concept over Trivia:** Ask about architectural patterns, data flow, logical constraints, or counter-intuitive behaviors.
    *   **The "Gotcha" Factor:** The question should be difficult because it contradicts standard intuition.
    *   **Prioritization:** Select the ${questionCount} questions MOST likely to result in an incorrect response from an expert.

If the text contains only general knowledge, return an empty list.`;

  const response = await ai.models.generateContent({
    model: EVALUATOR_MODEL,
    contents: [
      {
        role: "user",
        parts: [
          { text: `Reference Material:\n\n${inputData}` },
          { text: `\n\nTask:\n${topicFocus}` },
        ],
      },
    ],
    config: {
      systemInstruction,
      responseMimeType: "application/json",
      responseSchema: {
        type: Type.ARRAY,
        items: {
          type: Type.OBJECT,
          properties: {
            question: { type: Type.STRING },
            answer: {
              type: Type.STRING,
              description: "The correct answer based strictly on the text.",
            },
            rationale: {
              type: Type.STRING,
              description: "Why this is counter-intuitive.",
            },
          },
          required: ["question", "answer", "rationale"],
        },
      },
      temperature: 0.5,
    },
  });

  const text = response.text;
  if (!text) {
    error("failed to generate questions: empty response");
  }

  try {
    return JSON.parse(text) as Question[];
  } catch {
    error(`failed to parse questions JSON: ${text}`);
  }
}

// Test a question against the target model (no context)
async function testQuestion(
  ai: GoogleGenAI,
  question: string
): Promise<string> {
  const response = await ai.models.generateContent({
    model: TARGET_MODEL,
    contents: question,
  });

  return response.text || "I do not know.";
}

// Evaluate the candidate answer against ground truth
async function evaluateAnswer(
  ai: GoogleGenAI,
  question: string,
  groundTruth: string,
  candidateAnswer: string
): Promise<EvalResult> {
  const systemInstruction =
    "You are an impartial judge. Evaluate the Candidate Answer against the Ground Truth.";

  const prompt = `Question: ${question}
Ground Truth: ${groundTruth}
Candidate Answer: ${candidateAnswer}

Your Task:
1. Summarize the key points of the Candidate Answer.
2. Compare it to the Ground Truth.
3. specific failures:
    - Direct contradiction.
    - Missing the core 'gotcha' fact.
    - Technically correct but misleading emphasis (e.g., burying the real answer in a footnote or side comment).

Output strictly in JSON.`;

  const response = await ai.models.generateContent({
    model: EVALUATOR_MODEL,
    contents: prompt,
    config: {
      systemInstruction,
      responseMimeType: "application/json",
      responseSchema: {
        type: Type.OBJECT,
        properties: {
          is_correct: {
            type: Type.BOOLEAN,
            description:
              "False if the answer is wrong, misleading, or buries the lead.",
          },
          summary: {
            type: Type.STRING,
            description: "Brief summary of what the candidate actually said.",
          },
          critique: {
            type: Type.STRING,
            description:
              "Why it is correct or incorrect, referencing the Ground Truth.",
          },
        },
        required: ["is_correct", "summary", "critique"],
      },
    },
  });

  const text = response.text;
  if (!text) {
    error("failed to evaluate answer: empty response");
  }

  try {
    return JSON.parse(text) as EvalResult;
  } catch {
    error(`failed to parse evaluation JSON: ${text}`);
  }
}

// Validate a single question (test + evaluate)
async function validateQuestion(
  ai: GoogleGenAI,
  q: Question
): Promise<ValidationResult> {
  console.error(`Validating: ${q.question}`);

  // Test: Ask target model without context
  const candidateAnswer = await testQuestion(ai, q.question);

  // Evaluate: Judge the answer
  const evalResult = await evaluateAnswer(
    ai,
    q.question,
    q.answer,
    candidateAnswer
  );

  console.error(`  Judge Verdict: Is Correct? ${evalResult.is_correct}`);

  return { question: q, candidateAnswer, evalResult };
}

// Format validation result as markdown
function formatResult(result: ValidationResult, isFailure: boolean): string {
  const { question, candidateAnswer, evalResult } = result;

  let output = `### Q: ${question.question}\n`;

  if (isFailure) {
    output += `**A (Ground Truth):** ${question.answer}\n\n`;
    output += `**Analysis (Fail):** ${evalResult.summary} ${evalResult.critique}\n`;
  } else {
    output += `\n**Analysis (Success):** ${evalResult.summary} ${evalResult.critique}\n`;
  }

  output += `<details><summary>Raw Target Response</summary>\n\n`;
  output += `${candidateAnswer}\n\n`;
  output += `</details>\n\n`;

  return output;
}

// Generate final report
function generateReport(results: ValidationResult[]): string {
  const failures = results.filter((r) => !r.evalResult.is_correct);
  const successes = results.filter((r) => r.evalResult.is_correct);

  let report = `# Validated Knowledge Gaps\nTarget Model: \`${TARGET_MODEL}\`\n\n`;

  report += "## \u2705 Confirmed Unknowns\n";
  if (failures.length > 0) {
    report += `The model FAILED to answer these correctly, proving the information is novel.\n\n`;
    for (const result of failures) {
      report += formatResult(result, true);
    }
  } else {
    report += `_None found. The model appears to know all generated facts._\n`;
  }

  report += `\n---\n\n`;

  if (successes.length > 0) {
    report += "## \u274C False Alarms (Model Answered Correctly)\n";
    report += `The model SUCCESSFULLY answered these, so they are not novel gaps.\n\n`;
    for (const result of successes) {
      report += formatResult(result, false);
    }
  }

  return report;
}

// Main
async function main(): Promise<void> {
  const { topicFocus, questionCount } = parseArgs();

  // Check for API key
  if (!process.env.GEMINI_API_KEY) {
    error("GEMINI_API_KEY environment variable not set");
  }

  // Read input
  const inputData = await readStdin();
  if (!inputData.trim()) {
    error("empty input provided");
  }

  // Initialize AI client
  const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

  // Step 1: Generate questions
  const questions = await generateQuestions(
    ai,
    inputData,
    topicFocus,
    questionCount
  );

  if (questions.length === 0) {
    console.log(
      "No questions generated. The text may contain only general knowledge."
    );
    return;
  }

  // Step 2 & 3: Validate questions in parallel
  const results = await Promise.all(
    questions.map((q) => validateQuestion(ai, q))
  );

  // Step 4: Generate and output report
  const report = generateReport(results);
  console.log(report);
}

main().catch((err) => {
  error(err instanceof Error ? err.message : String(err));
});

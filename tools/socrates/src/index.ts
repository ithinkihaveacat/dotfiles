#!/usr/bin/env node

import { GoogleGenAI, Type } from "@google/genai/node";
import pkg from "../package.json" with { type: "json" };

/**
 * Socrates Architecture
 *
 * This tool uses a three-stage "Socratic" pipeline to identify knowledge gaps:
 *
 * 1. Hypothesis Generation (The Miner): An advanced model (Gemini 3 Pro) analyzes
 *    the source text to extract facts that are likely novel, counter-intuitive,
 *    or "gotchas." It generates questions targeting these specific facts.
 *    It does *not* verify the gaps; it only hypothesizes that they exist.
 *
 * 2. Blind Testing (The Subject): The target model (Gemini 2.5 Flash) attempts
 *    to answer these questions *without* access to the source text. This tests
 *    the model's intrinsic knowledge.
 *
 * 3. Adjudication (The Judge): The advanced model compares the Subject's answer
 *    against the Ground Truth (from step 1). If the Subject fails to answer
 *    correctly, the fact is confirmed as a "Validated Unknown."
 */

// Version check - Node.js 24+ required
const REQUIRED_NODE_MAJOR = 24;
{
  const major = Number(process.versions.node.split(".")[0]);
  if (major < REQUIRED_NODE_MAJOR) {
    console.error(
      `socrates: requires Node.js ${REQUIRED_NODE_MAJOR}+ (found ${process.version})`
    );
    process.exit(1);
  }
}

// Derive parameter types from the SDK's generateContent method
type GenerateParams = Parameters<GoogleGenAI["models"]["generateContent"]>[0];

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
  candidateAnswer: string | null;
  evalResult: EvalResult | null;
  model: string;
  modelDisplayName: string;
  error?: boolean;
}

interface RetryOptions {
  maxRetries?: number;
  /**
   * Callback invoked before a retry.
   * @param attempt The current attempt number (starting at 1).
   * @param error The error that caused the failure.
   * @returns true to proceed with retry, false to abort.
   */
  onRetry?: (attempt: number, error: unknown) => boolean;
}

// Constants
const DEFAULT_MODELS = ["gemini-2.5-flash"];
const EVALUATOR_MODEL = "gemini-3-pro-preview";
const DEFAULT_QUESTION_COUNT = 7;
const MAX_RETRIES = 3;
const MAX_GLOBAL_ERRORS = 10;

const SCRIPT_NAME = "socrates";

// Helper to truncate text to fit terminal width.
// Note: does not account for wide (e.g. CJK) characters, which occupy two
// terminal columns each and may cause slight misalignment.
function truncate(text: string, maxLen: number): string {
  if (text.length <= maxLen) return text;
  return text.slice(0, maxLen - 3) + "...";
}

// Helper to generate content with robust retry logic
async function generateContentWithRetry(
  ai: GoogleGenAI,
  model: string,
  contents: GenerateParams["contents"],
  config?: GenerateParams["config"],
  retryOptions?: RetryOptions
): Promise<string | null> {
  const maxRetries = retryOptions?.maxRetries ?? MAX_RETRIES;
  let attempt = 0;
  while (true) {
    try {
      const response = await ai.models.generateContent({
        model,
        contents,
        config
      });
      return response.text ?? null;
    } catch (e: any) {
      const msg = e.message || String(e);

      // Critical Error: Model not found (404) or Quota Exceeded (429)
      if (
        msg.includes("404") ||
        e.status === 404 ||
        msg.includes("NOT_FOUND") ||
        msg.includes("429") ||
        e.status === 429 ||
        msg.includes("RESOURCE_EXHAUSTED") ||
        msg.toLowerCase().includes("quota")
      ) {
        console.error(
          `\nFATAL: Critical error encountered (Model not found or Quota exceeded).\n${msg}`
        );
        process.exit(1);
      }

      attempt++;
      if (attempt > maxRetries) {
        console.error(`\nFailed after ${attempt} attempts: ${msg}`);
        return null;
      }

      // Allow caller to control retry policy (e.g., global limits)
      if (retryOptions?.onRetry) {
        if (!retryOptions.onRetry(attempt, e)) {
          return null;
        }
      }

      // Exponential backoff with jitter
      const delay = Math.pow(2, attempt) * 1000 + Math.random() * 500;
      await new Promise((r) => setTimeout(r, delay));
    }
  }
}

// Helper to process items in parallel with a concurrency limit
async function mapConcurrent<T, R>(
  items: T[],
  limit: number,
  fn: (item: T, index: number) => Promise<R>
): Promise<R[]> {
  const results: R[] = new Array(items.length);
  let currentIndex = 0;

  const worker = async () => {
    while (currentIndex < items.length) {
      const index = currentIndex++;
      results[index] = await fn(items[index], index);
    }
  };

  const workers = Array(Math.min(limit, items.length))
    .fill(null)
    .map(() => worker());

  await Promise.all(workers);
  return results;
}

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
  -v, --version     Display version number and exit
  --questions N     Number of questions to generate (default: ${DEFAULT_QUESTION_COUNT})
  --models LIST     Comma-separated list of models to test (default: ${DEFAULT_MODELS.join(",")})
                    Append "+grounded" to a model name to enable Google Search (e.g. gemini-1.5-pro+grounded).
                    For a list of available models, see:
                    https://ai.google.dev/gemini-api/docs/models

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

function version(): void {
  console.log(`${SCRIPT_NAME} ${pkg.version}`);
  process.exit(0);
}

// Parse CLI arguments
function parseArgs(): {
  topicFocus: string;
  questionCount: number;
  targetModels: string[];
} {
  const args = process.argv.slice(2);
  let questionCount = DEFAULT_QUESTION_COUNT;
  let topicFocus = "Generate challenging questions based on novel information.";
  let topicFocusSet = false;
  let targetModels = [...DEFAULT_MODELS];
  let endOfOptions = false;

  for (let i = 0; i < args.length; i++) {
    const arg = args[i];

    if (endOfOptions) {
      if (topicFocusSet) {
        error("unexpected argument: only one TOPIC_FOCUS is allowed");
      }
      topicFocus = arg;
      topicFocusSet = true;
      continue;
    }

    if (arg === "--") {
      endOfOptions = true;
    } else if (arg === "-h" || arg === "--help") {
      usage();
    } else if (arg === "-v" || arg === "--version") {
      version();
    } else if (arg === "--questions") {
      const next = args[++i];
      if (!next || isNaN(parseInt(next, 10))) {
        error("--questions requires a numeric argument");
      }
      questionCount = parseInt(next, 10);
      if (questionCount < 1) {
        error("--questions must be at least 1");
      }
    } else if (arg === "--models") {
      const next = args[++i];
      if (!next) {
        error("--models requires a comma-separated list");
      }
      targetModels = next.split(",").map((m) => m.trim()).filter((m) => m);
      if (targetModels.length === 0) {
        error("--models list cannot be empty");
      }
    } else if (arg.startsWith("-")) {
      error(`unknown option: ${arg}`);
    } else {
      if (topicFocusSet) {
        error("unexpected argument: only one TOPIC_FOCUS is allowed");
      }
      topicFocus = arg;
      topicFocusSet = true;
    }
  }

  return { topicFocus, questionCount, targetModels };
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
  questionCount: number,
  retryOptions?: RetryOptions
): Promise<Question[]> {
  console.error("Generating questions...");

  const systemInstruction = `Analyze the provided reference material to identify specific details that are likely novel, unexpected, or counter-intuitive. Generate exactly ${questionCount} questions designed to challenge an expert model's knowledge of these facts.

### Core Task
Generate questions that satisfy the "Gotcha" condition:
**An expert in the general field relying on standard industry knowledge would likely answer incorrectly, but the correct answer is explicitly contained in the provided text.**

### CRITICAL: Context & Disambiguation
*   **Self-Contained & Unambiguous:** The questions will be asked to a model *without* the provided text. You MUST include all necessary context in the question itself.
*   **Disambiguate Overloaded Terms:** Many technical terms mean different things in different contexts. You MUST qualify these terms to avoid ambiguity.
    *   *Ambiguous:* "How do I add a tile?" (Could be Wear OS, Quick Settings, Google Maps, Windows OS...)
    *   *Fixed:* "How do I add a **Wear OS** tile to the carousel?"
    *   *Ambiguous:* "What is the limit for navigation?" (UX navigation? Jetpack Navigation component? GPS?)
    *   *Fixed:* "What is the back stack limit in **Jetpack Navigation Compose**?"
*   **Specify Versions/Platforms:** If the information is specific to "Wear OS 5" or "Jetpack Tiles 1.4", you **must** explicitly state this in the question.
    *   *Bad:* "What is the limit for animated elements?" (Which system? Which version?)
    *   *Good:* "In **Wear OS Tiles API v1.4**, what is the hard limit on simultaneously animated elements?"

### Question Types & Variety
Generate a diverse set of questions. While most should focus on positive knowledge (how things work), ensure that **a small portion (approx. 15-20%)** of the questions target **negative constraints** or **impossible actions** to test for hallucinations.

1.  **Positive Knowledge (Majority):** Counter-intuitive facts about how the system works, architectural patterns, or specific limitations of valid features.
2.  **Negative Constraints (Minority):** Ask how to perform a task that the text implies or states is impossible or inadvisable.
    *   *Example:* If the text says "Images must be PNG," ask "How do I load a JPEG image?"
    *   *Desired Answer:* "This is not possible; only PNGs are supported."
    *   *Goal:* Verify the model doesn't hallucinate a solution for something that cannot be done.

### Constraints & Mandates
1.  **Source Material Restrictions:**
    *   **Strict Grounding:** You are strictly limited to the provided Reference Material for the facts used in the questions and answers. Do not incorporate outside facts.
    *   **Ignore Code Snippets:** Do not formulate questions based on code blocks, variable names, or syntax.
    *   **Ignore Illustrative Examples:** Do not use "For example..." scenarios or sample values.
    *   **Focus on Normative Text:** Derive questions only from the main narrative defining core rules, architecture, and behaviors.

2.  **Question Quality:**
    *   **Concept over Trivia:** Ask about architectural patterns, data flow, logical constraints, or counter-intuitive behaviors.
    *   **The "Gotcha" Factor:** The question should be difficult because it contradicts standard intuition.
    *   **Prioritization:** Select the ${questionCount} questions MOST likely to result in an incorrect response from an expert.

If the text contains only general knowledge, return an empty list.`;

  const responseText = await generateContentWithRetry(
    ai,
    EVALUATOR_MODEL,
    [
      {
        role: "user",
        parts: [
          { text: `Reference Material:\n\n${inputData}` },
          { text: `\n\nTask:\n${topicFocus}` }
        ]
      }
    ],
    {
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
              description: "The correct answer based strictly on the text."
            },
            rationale: {
              type: Type.STRING,
              description: "Why this is counter-intuitive."
            }
          },
          required: ["question", "answer", "rationale"]
        }
      },
      temperature: 0.5
    },
    retryOptions
  );

  if (!responseText) {
    error("failed to generate questions: empty response");
  }

  try {
    return JSON.parse(responseText) as Question[];
  } catch {
    error(`failed to parse questions JSON: ${responseText}`);
  }
}

// Test a question against the target model (no context)
async function testQuestion(
  ai: GoogleGenAI,
  model: string,
  question: string,
  useGrounding: boolean,
  retryOptions?: RetryOptions
): Promise<string | null> {
  const config = useGrounding ? { tools: [{ googleSearch: {} }] } : undefined;
  return generateContentWithRetry(ai, model, question, config, retryOptions);
}

// Evaluate the candidate answer against ground truth
async function evaluateAnswer(
  ai: GoogleGenAI,
  question: string,
  groundTruth: string,
  rationale: string,
  candidateAnswer: string,
  retryOptions?: RetryOptions
): Promise<EvalResult | null> {
  const systemInstruction = `You are a strictly grounded impartial judge. Evaluate the Candidate Answer SOLELY against the provided Ground Truth.

### Constraints
1.  **Strict Grounding:** You must **not** access or utilize your own knowledge or common sense to evaluate the answer. Treat the provided Ground Truth (Answer + Rationale) as the absolute limit of truth.
2.  **XML Structure:** The input is provided in XML tags. Analyze the <candidate_answer> against the <ground_truth>.`;

  const prompt = `<question>
${question}
</question>

<ground_truth>
<answer>
${groundTruth}
</answer>
<rationale>
${rationale}
</rationale>
</ground_truth>

<candidate_answer>
${candidateAnswer}
</candidate_answer>

Your Task:
1. Summarize the key points of the Candidate Answer.
2. Compare it to the Ground Truth (Answer and Rationale).
3. Identify specific failures:
    - Direct contradiction.
    - Missing the core 'gotcha' fact defined in the rationale.
    - Technically correct but misleading emphasis.

  Output strictly in JSON.`;

  const responseText = await generateContentWithRetry(
    ai,
    EVALUATOR_MODEL,
    prompt,
    {
      systemInstruction,
      responseMimeType: "application/json",
      responseSchema: {
        type: Type.OBJECT,
        properties: {
          is_correct: {
            type: Type.BOOLEAN,
            description:
              "False if the answer is wrong, misleading, or buries the lead."
          },
          summary: {
            type: Type.STRING,
            description: "Brief summary of what the candidate actually said."
          },
          critique: {
            type: Type.STRING,
            description:
              "Why it is correct or incorrect, referencing the Ground Truth."
          }
        },
        required: ["is_correct", "summary", "critique"]
      }
    },
    retryOptions
  );

  if (!responseText) {
    return null;
  }

  try {
    return JSON.parse(responseText) as EvalResult;
  } catch {
    return null;
  }
}

// Validate a single question (test + evaluate)
async function validateQuestion(
  ai: GoogleGenAI,
  q: Question,
  index: number,
  total: number,
  modelRaw: string,
  modelDisplayName: string,
  retryOptions?: RetryOptions,
  onError?: () => void
): Promise<ValidationResult> {
  const cols = process.stdout.columns || 80;
  const prefix = `  [${index}/${total}] ${modelDisplayName}: `;
  const maxQuestionLen = Math.max(10, cols - prefix.length - 12); // Space for result

  const isGrounded = modelRaw.endsWith("+grounded");
  const model = isGrounded
    ? modelRaw.slice(0, -"+grounded".length)
    : modelRaw;

  // Test: Ask target model without context
  const candidateAnswer = await testQuestion(
    ai,
    model,
    q.question,
    isGrounded,
    retryOptions
  );

  if (candidateAnswer === null) {
    console.error(`${prefix}${truncate(q.question, maxQuestionLen)} error`);
    onError?.();
    return {
      question: q,
      candidateAnswer: null,
      evalResult: null,
      model,
      modelDisplayName,
      error: true
    };
  }

  // Evaluate: Judge the answer
  const evalResult = await evaluateAnswer(
    ai,
    q.question,
    q.answer,
    q.rationale,
    candidateAnswer,
    retryOptions
  );

  if (evalResult === null) {
    console.error(`${prefix}${truncate(q.question, maxQuestionLen)} eval_err`);
    onError?.();
    return {
      question: q,
      candidateAnswer,
      evalResult: null,
      model,
      modelDisplayName,
      error: true
    };
  }

  const result = evalResult.is_correct ? "correct" : "incorrect";
  console.error(`${prefix}${truncate(q.question, maxQuestionLen)} ${result}`);

  return {
    question: q,
    candidateAnswer,
    evalResult,
    model,
    modelDisplayName
  };
}

// Generate final report
function generateReport(
  results: ValidationResult[],
  questions: Question[],
  models: { model: string; displayName: string }[]
): string {
  let report = `# Model Knowledge Gap Analysis\n\n`;
  report += `Date: ${new Date().toISOString().slice(0, 16).replace("T", " ")} \\\n`;

  if (models.length === 1) {
    report += `Target Model: \`${models[0].displayName}\`\n\n`;
  } else {
    report += `Target Models: ${models.map((m) => `\`${m.displayName}\``).join(", ")}\n\n`;
  }

  // Summary Table
  report += "## Summary\n\n";
  report += "| Question | " + models.map((m) => m.displayName).join(" | ") + " |\n";
  report += "| :--- | " + models.map(() => ":---:").join(" | ") + " |\n";

  for (const q of questions) {
    const qResults = results.filter((r) => r.question === q);
    const row = [truncate(q.question, 60)];
    for (const m of models) {
      const res = qResults.find((r) => r.modelDisplayName === m.displayName);
      if (res?.error) {
        row.push("-");
      } else {
        row.push(res?.evalResult?.is_correct ? "✅" : "❌");
      }
    }
    report += "| " + row.join(" | ") + " |\n";
  }
  report += "\n---\n\n";

  // Detailed Breakdown
  report += "## Detailed Analysis\n\n";

  for (let i = 0; i < questions.length; i++) {
    const q = questions[i];
    report += `### Q${i + 1}: ${q.question}\n\n`;
    report += `**Rationale:** ${q.rationale}\n\n`;
    report += `**Ground Truth:** ${q.answer}\n\n`;

    const qResults = results.filter((r) => r.question === q);

    for (const m of models) {
      const res = qResults.find((r) => r.modelDisplayName === m.displayName);
      if (!res) continue;

      if (res.error) {
        report += `#### ⚠️ ${m.displayName}\n\n`;
        report += `**Analysis:** Failed to obtain a valid response or evaluation after retries.\n\n`;
        continue;
      }

      // Safe access because error is false
      const evalRes = res.evalResult!;
      const icon = evalRes.is_correct ? "✅" : "❌";
      report += `#### ${icon} ${m.displayName}\n\n`;
      report += `**Analysis:** ${evalRes.summary} ${evalRes.critique}\n\n`;
      report += `<details><summary>Raw Response</summary>\n\n${res.candidateAnswer}\n\n</details>\n\n`;
    }
    report += "---\n\n";
  }

  return report;
}

// Helper to get display names for models (handling duplicates)
function getModelDisplayNames(models: string[]): {
  model: string;
  displayName: string;
}[] {
  const counts: Record<string, number> = {};
  const result = [];

  // First pass to count
  for (const m of models) {
    counts[m] = (counts[m] || 0) + 1;
  }

  const current: Record<string, number> = {};
  for (const m of models) {
    let name = m;
    if (counts[m] > 1) {
      current[m] = (current[m] || 0) + 1;
      name = `${m}[#${current[m]}]`;
    }
    result.push({ model: m, displayName: name });
  }
  return result;
}

// Main
async function main(): Promise<void> {
  const { topicFocus, questionCount, targetModels } = parseArgs();

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

  // Error tracking (local to main, not a global)
  let errorCount = 0;
  const retryOptions: RetryOptions = {
    onRetry: () => errorCount < MAX_GLOBAL_ERRORS
  };
  const onError = () => {
    errorCount++;
    if (errorCount >= MAX_GLOBAL_ERRORS) {
      console.error("\nAborting: Too many errors encountered.");
      process.exit(1);
    }
  };

  // Step 1: Generate questions
  const questions = await generateQuestions(
    ai,
    inputData,
    topicFocus,
    questionCount,
    retryOptions
  );

  if (questions.length === 0) {
    console.log(
      "No questions generated. The text may contain only general knowledge."
    );
    return;
  }

  const modelConfigs = getModelDisplayNames(targetModels);

  // Prepare tasks: Cross product of questions and models
  const tasks: Array<{
    question: Question;
    qIndex: number;
    model: string;
    modelDisplayName: string;
  }> = [];
  for (let i = 0; i < questions.length; i++) {
    for (const config of modelConfigs) {
      tasks.push({
        question: questions[i],
        qIndex: i + 1,
        model: config.model,
        modelDisplayName: config.displayName
      });
    }
  }

  // Step 2 & 3: Validate questions in parallel
  console.error(
    `Validating ${questions.length} questions on ${modelConfigs.length} models (${tasks.length} total tasks)...`
  );

  const results = await mapConcurrent(tasks, 10, (task, _) =>
    validateQuestion(
      ai,
      task.question,
      task.qIndex,
      questions.length,
      task.model,
      task.modelDisplayName,
      retryOptions,
      onError
    )
  );

  // Step 4: Generate and output report
  const report = generateReport(results, questions, modelConfigs);
  console.log(report);
}

main().catch((err) => {
  error(err instanceof Error ? err.message : String(err));
});

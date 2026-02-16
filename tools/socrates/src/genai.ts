import { GoogleGenAI, Type } from "@google/genai/node";
import { CONFIG, RetryOptions } from "./config.js";
import { Question, Evaluation } from "./types.js";

type GenerateParams = Parameters<GoogleGenAI["models"]["generateContent"]>[0];

// Helper to generate content with robust retry logic
async function generateContentWithRetry(
  ai: GoogleGenAI,
  model: string,
  contents: GenerateParams["contents"],
  config?: GenerateParams["config"],
  retryOptions?: RetryOptions
): Promise<string | null> {
  const maxRetries = retryOptions?.maxRetries ?? CONFIG.MAX_RETRIES;
  let attempt = 0;
  while (true) {
    try {
      const response = await ai.models.generateContent({
        model,
        contents,
        config,
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
          `
FATAL: Critical error encountered (Model not found or Quota exceeded).
${msg}`
        );
        process.exit(1);
      }

      attempt++;
      if (attempt > maxRetries) {
        console.error(`
Failed after ${attempt} attempts: ${msg}`);
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

export async function generateQuestions(
  ai: GoogleGenAI,
  inputData: string,
  topicFocus: string,
  questionCount: number,
  retryOptions?: RetryOptions
): Promise<Omit<Question, "id" | "created_at" | "topic">[]> {
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

3.  **Self-Contained Rationale:**
    *   The rationale must explain *why* the fact is true based on the system's logic, NOT based on the document's existence.
    *   **Forbidden Phrases:** "The text says...", "According to the document...", "The reference material indicates..."
    *   *Bad:* "The text states that X is true."
    *   *Good:* "X is true because the system architecture requires Y."

If the text contains only general knowledge, return an empty list.`;

  const responseText = await generateContentWithRetry(
    ai,
    CONFIG.EVALUATOR_MODEL,
    [
      {
        role: "user",
        parts: [
          { text: `Reference Material:

${inputData}` },
          { text: `

Task:
${topicFocus}` },
        ],
      },
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
    retryOptions
  );

  if (!responseText) {
    throw new Error("Failed to generate questions: empty response");
  }

  try {
    const parsed = JSON.parse(responseText);
    return parsed.map((p: any) => ({
      text: p.question,
      ground_truth: p.answer,
      rationale: p.rationale,
    }));
  } catch (e) {
    throw new Error(`Failed to parse questions JSON: ${responseText}`);
  }
}

export async function testQuestion(
  ai: GoogleGenAI,
  model: string,
  question: string,
  useGrounding: boolean,
  retryOptions?: RetryOptions
): Promise<string | null> {
  const config = useGrounding ? { tools: [{ googleSearch: {} }] } : undefined;
  return generateContentWithRetry(ai, model, question, config, retryOptions);
}

export async function evaluateAnswer(
  ai: GoogleGenAI,
  question: string,
  groundTruth: string,
  rationale: string,
  candidateAnswer: string,
  retryOptions?: RetryOptions
): Promise<Omit<Evaluation, "question_id" | "responder" | "timestamp"> | null> {
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
    CONFIG.EVALUATOR_MODEL,
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
    retryOptions
  );

  if (!responseText) {
    return null;
  }

  try {
    return JSON.parse(responseText);
  } catch {
    return null;
  }
}

export async function generateTopicSlug(
  ai: GoogleGenAI,
  inputData: string,
  retryOptions?: RetryOptions
): Promise<string> {
  const prompt = `Analyze the following text and generate a concise, human-readable topic slug.
  
  Constraints:
  1. Use only lowercase letters, numbers, and hyphens.
  2. No other punctuation or spaces.
  3. Maximum length: 30 characters.
  4. Format: word1-word2-word3
  5. The slug should be descriptive of the main topic.
  
  Text Sample (first 2000 chars):
  ${inputData.slice(0, 2000)}
  `;

  const responseText = await generateContentWithRetry(
    ai,
    CONFIG.EVALUATOR_MODEL,
    prompt,
    {
      responseMimeType: "text/plain",
      temperature: 0.5,
    },
    retryOptions
  );

  if (!responseText) {
    return "general";
  }

  // Clean up just in case the model is chatty
  let slug = responseText.trim().toLowerCase();
  // Remove any surrounding quotes or markdown
  slug = slug.replace(/['"`]/g, "").replace(/\n/g, "");
  // Keep only safe chars
  slug = slug.replace(/[^a-z0-9-]/g, "-");
  // Remove duplicate dashes
  slug = slug.replace(/-+/g, "-");
  // Trim dashes
  slug = slug.replace(/^-|-$/g, "");
  
  return slug.slice(0, 30) || "general";
}


import { GoogleGenAI } from "@google/genai/node";
import * as path from "path";
import * as fs from "fs";
import { initDB, getUnevaluatedAnswers, addEvaluation, getAllQuestions } from "../db.js";
import { evaluateAnswer } from "../genai.js";
import { CONFIG } from "../config.js";
import { mapConcurrent, truncate } from "../utils.js";
import { resolveDBPath } from "../resolve.js";

export async function run(dbPathOrId: string) {
  const dbPath = resolveDBPath(dbPathOrId);

  if (!process.env.GEMINI_API_KEY) {
    throw new Error("GEMINI_API_KEY environment variable not set");
  }

  const db = initDB(dbPath);
  const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

  // We need the questions to get ground truth and rationale
  const allQuestions = getAllQuestions(db);
  const questionsMap = new Map(allQuestions.map((q) => [q.id, q]));

  const answers = getUnevaluatedAnswers(db);

  if (answers.length === 0) {
    console.log("No unevaluated answers found.");
    return;
  }

  console.log(`Found ${answers.length} unevaluated answers.`);

  await mapConcurrent(answers, CONFIG.MAX_CONCURRENCY, async (ans, i) => {
    const q = questionsMap.get(ans.question_id);
    if (!q) {
      console.error(`Question ID ${ans.question_id} not found for answer.`);
      return;
    }

    const prefix = `[${i + 1}/${answers.length}]`;
    try {
      const evaluation = await evaluateAnswer(
        ai,
        q.text,
        q.ground_truth,
        q.rationale,
        ans.text
      );

      if (evaluation) {
        addEvaluation(db, {
          question_id: ans.question_id,
          responder: ans.responder,
          ...evaluation,
        });
        const verdict = evaluation.is_correct ? "✅" : "❌";
        console.log(`${prefix} Scored ${verdict}: ${truncate(q.text, 50)} (${ans.responder})`);
      } else {
        console.error(`${prefix} Failed to evaluate answer for: ${truncate(q.text, 50)}`);
      }
    } catch (e) {
      console.error(`${prefix} Error evaluating answer for question ${q.id}:`, e);
    }
  });
}

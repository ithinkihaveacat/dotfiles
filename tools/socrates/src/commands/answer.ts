import { GoogleGenAI } from "@google/genai/node";
import * as path from "path";
import * as fs from "fs";
import * as readline from "readline";
import { exec } from "child_process";
import { promisify } from "util";
import { initDB, getUnansweredQuestions, addAnswer } from "../db.js";
import { testQuestion } from "../genai.js";
import { CONFIG } from "../config.js";
import { mapConcurrent, truncate } from "../utils.js";
import { Question } from "../types.js";

const execAsync = promisify(exec);

export async function run(dbPath: string, mode: string) {
  if (!fs.existsSync(dbPath)) {
    throw new Error(`Database not found: ${dbPath}`);
  }

  const db = initDB(dbPath);
  const [type, ...rest] = mode.split(":");
  const responder = mode; // Full string is the responder ID
  const subConfig = rest.join(":"); // e.g., "gemini-2.5-flash" or "script.sh"

  const questions = getUnansweredQuestions(db, responder);

  if (questions.length === 0) {
    console.log(`No unanswered questions for responder '${responder}'.`);
    return;
  }

  console.log(`Found ${questions.length} unanswered questions for '${responder}'.`);

  if (type === "model") {
    if (!process.env.GEMINI_API_KEY) {
      throw new Error("GEMINI_API_KEY environment variable not set");
    }
    const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
    const model = subConfig;
    const isGrounded = model.endsWith("+grounded");
    const modelName = isGrounded ? model.slice(0, -"+grounded".length) : model;

    await mapConcurrent(questions, CONFIG.MAX_CONCURRENCY, async (q, i) => {
      const prefix = `[${i + 1}/${questions.length}]`;
      try {
        const answerText = await testQuestion(ai, modelName, q.text, isGrounded);
        if (answerText) {
          addAnswer(db, {
            question_id: q.id,
            responder,
            text: answerText,
          });
          console.log(`${prefix} Answered: ${truncate(q.text, 50)}`);
        } else {
          console.error(`${prefix} Failed to get answer for: ${truncate(q.text, 50)}`);
        }
      } catch (e) {
        console.error(`${prefix} Error answering question ${q.id}:`, e);
      }
    });

  } else if (type === "shell") {
    const scriptCmd = subConfig;
    for (let i = 0; i < questions.length; i++) {
      const q = questions[i];
      const prefix = `[${i + 1}/${questions.length}]`;
      try {
        // Simple shell execution: script "question text"
        // We need to escape the question text to be safe in shell
        const safeQuestion = q.text.replace(/"/g, '"');
        const command = `${scriptCmd} "${safeQuestion}"`;
        
        const { stdout, stderr } = await execAsync(command);
        if (stderr) {
          console.warn(`${prefix} stderr: ${stderr.trim()}`);
        }
        
        const answerText = stdout.trim();
        if (answerText) {
          addAnswer(db, {
            question_id: q.id,
            responder,
            text: answerText,
          });
          console.log(`${prefix} Answered: ${truncate(q.text, 50)}`);
        } else {
          console.error(`${prefix} Empty stdout from script for: ${truncate(q.text, 50)}`);
        }
      } catch (e) {
        console.error(`${prefix} Error executing script for question ${q.id}:`, e);
      }
    }

  } else if (type === "interactive") {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout,
    });

    for (let i = 0; i < questions.length; i++) {
      const q = questions[i];
      console.log(`
[${i + 1}/${questions.length}] Question:`);
      console.log(q.text);
      console.log("-".repeat(40));
      
      const answerText = await new Promise<string>((resolve) => {
        rl.question("Answer > ", (answer) => {
          resolve(answer.trim());
        });
      });

      if (answerText) {
        addAnswer(db, {
          question_id: q.id,
          responder,
          text: answerText,
        });
        console.log("Answer saved.");
      } else {
        console.log("Skipped (empty answer).");
      }
    }
    rl.close();

  } else {
    throw new Error(`Unknown mode type: ${type}. Supported: model, shell, interactive.`);
  }
}

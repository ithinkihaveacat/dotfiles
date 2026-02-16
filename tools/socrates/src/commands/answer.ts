import { GoogleGenAI } from "@google/genai/node";
import * as path from "path";
import * as fs from "fs";
import { exec, spawn, execFile } from "child_process";
import { promisify } from "util";
import { initDB, getUnansweredQuestions, addAnswer, getAllResponders } from "../db.js";
import { testQuestion } from "../genai.js";
import { CONFIG } from "../config.js";
import { mapConcurrent, truncate } from "../utils.js";
import { resolveDBPath } from "../resolve.js";
import { Question } from "../types.js";

const execAsync = promisify(exec);
const execFileAsync = promisify(execFile);

export async function run(dbPathOrId: string, mode: string) {
  const dbPath = resolveDBPath(dbPathOrId);
  const db = initDB(dbPath);
  
  let responder = mode;

  // Handle auto-increment syntax "name[]"
  if (responder.endsWith("[]")) {
    const base = responder.slice(0, -2);
    const existing = new Set(getAllResponders(db));
    let i = 1;
    while (existing.has(`${base}[${i}]`)) {
      i++;
    }
    responder = `${base}[${i}]`;
    console.log(`Starting new run: ${responder}`);
  }

  const [type, ...rest] = responder.split(":");
  let subConfig = rest.join(":");
  subConfig = subConfig.replace(/\[\d+\]$/, "").replace(/\[\]$/, "");

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
    // Simplify: Assume subConfig is a simple command path without spaces or arguments.
    const cmd = subConfig.trim();
    if (!cmd) {
      throw new Error("Shell command is empty.");
    }

    for (let i = 0; i < questions.length; i++) {
      const q = questions[i];
      const prefix = `[${i + 1}/${questions.length}]`;
      try {
        // Execute directly without shell interpretation.
        // We pass the question as the ONLY argument.
        const args = [q.text];
        
        const { stdout, stderr } = await execFileAsync(cmd, args);
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
    // We don't use readline here because we want to support multi-line input
    // terminated by Ctrl+D, which is best handled by spawning a child process
    // (like 'cat') that inherits stdin. This avoids Node.js stream complexity
    // with reopening stdin.

    for (let i = 0; i < questions.length; i++) {
      const q = questions[i];
      console.log(`\n[${i + 1}/${questions.length}] Question:`);
      console.log(q.text);
      console.log("-".repeat(40));
      console.log("Enter answer (Press Ctrl+D to save):");

      const answerText = await new Promise<string>((resolve, reject) => {
        const child = spawn("cat", [], {
          stdio: ["inherit", "pipe", "inherit"],
        });
        let data = "";

        child.stdout.on("data", (chunk) => {
          data += chunk.toString();
        });

        child.on("close", () => {
          resolve(data.trim());
        });

        child.on("error", (err) => {
          reject(err);
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

  } else {
    throw new Error(`Unknown mode type: ${type}. Supported: model, shell, interactive.`);
  }
}

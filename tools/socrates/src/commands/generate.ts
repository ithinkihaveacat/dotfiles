import { GoogleGenAI } from "@google/genai/node";
import * as path from "path";
import * as fs from "fs";
import * as crypto from "crypto";
import { initDB, addQuestions } from "../db.js";
import { generateQuestions, generateTopicSlug } from "../genai.js";
import { CONFIG } from "../config.js";
import { getDataDir } from "../utils.js";
import { Question } from "../types.js";

function sanitizeSlug(s: string): string {
  return s.replace(/[^a-zA-Z0-9-]/g, "-").replace(/-+/g, "-").replace(/^-|-$/g, "").slice(0, 30);
}

// Read all stdin
function readStdin(): Promise<string> {
  // If no pipe, we probably shouldn't block indefinitely, but let's assume usage
  // implies piping.
  return new Promise((resolve, reject) => {
    let data = "";
    process.stdin.setEncoding("utf8");
    process.stdin.on("data", (chunk) => (data += chunk));
    process.stdin.on("end", () => resolve(data));
    process.stdin.on("error", reject);
  });
}

export async function run(questionCount: number) {
  if (!process.env.GEMINI_API_KEY) {
    throw new Error("GEMINI_API_KEY environment variable not set");
  }

  const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
  const inputData = await readStdin();

  if (!inputData || !inputData.trim()) {
    throw new Error("Empty input provided via stdin");
  }

  // Determine prompt topic (instruction to AI)
  const promptTopic = "Generate challenging questions based on novel information.";

  console.error("Generating topic slug...");
  const slug = await generateTopicSlug(ai, inputData);

  console.error(`Generating questions for topic: "${slug}"...`);
  const questions = await generateQuestions(ai, inputData, promptTopic, questionCount);

  if (questions.length === 0) {
    console.error("No questions generated.");
    return;
  }

  // Create unique ID: hash-slug
  const hash = crypto.randomBytes(4).toString("hex");
  const dbId = `${hash}-${slug}`;
  const filename = `${dbId}.db`;
  
  const dataDir = getDataDir();
  const dbPath = path.join(dataDir, filename);
  const db = initDB(dbPath);

  // Add topic to questions before inserting
  const questionsWithTopic = questions.map((q) => ({ ...q, topic: promptTopic }));

  addQuestions(db, questionsWithTopic);

  console.error(`Generated ${questions.length} questions.`);
  console.log(dbPath); // Print full path for pipeability/logging
  console.error(`Session ID: ${dbId}`); // Print ID to stderr for user reference
}

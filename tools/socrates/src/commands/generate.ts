import { GoogleGenAI } from "@google/genai/node";
import * as path from "path";
import * as fs from "fs";
import * as crypto from "crypto";
import { initDB, addQuestions } from "../db.js";
import { generateQuestions } from "../genai.js";
import { CONFIG } from "../config.js";
import { Question } from "../types.js";

function getDBPath(topic: string): string {
  // 8 chars of hex + topic
  const hash = crypto.randomBytes(4).toString("hex");
  const safeTopic = topic.replace(/[^a-zA-Z0-9]/g, "-").slice(0, 30);
  const filename = `${hash}-${safeTopic}.db`;

  const xdgDataHome = process.env.XDG_DATA_HOME || path.join(process.env.HOME || "", ".local", "share");
  const dataDir = path.join(xdgDataHome, "socrates");

  if (!fs.existsSync(dataDir)) {
    fs.mkdirSync(dataDir, { recursive: true });
  }

  return path.join(dataDir, filename);
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

export async function run(topic: string | undefined, questionCount: number) {
  if (!process.env.GEMINI_API_KEY) {
    throw new Error("GEMINI_API_KEY environment variable not set");
  }

  const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
  const inputData = await readStdin();

  if (!inputData || !inputData.trim()) {
    throw new Error("Empty input provided via stdin");
  }

  const promptTopic = topic || "Generate challenging questions based on novel information.";
  const fileTopic = topic || "general";

  console.error("Generating questions...");
  const questions = await generateQuestions(ai, inputData, promptTopic, questionCount);

  if (questions.length === 0) {
    console.error("No questions generated.");
    return;
  }

  const dbPath = getDBPath(fileTopic);
  const db = initDB(dbPath);

  // Add topic to questions before inserting
  const questionsWithTopic = questions.map((q) => ({ ...q, topic: promptTopic }));

  addQuestions(db, questionsWithTopic);

  console.error(`Generated ${questions.length} questions.`);
  console.log(dbPath); // Print ONLY the DB path to stdout for pipeability
}

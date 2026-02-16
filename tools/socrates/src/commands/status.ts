import * as fs from "fs";
import { initDB, getStats, getAllQuestions } from "../db.js";
import { Stats, Question } from "../types.js";
import { resolveDBPath } from "../resolve.js";

function wrapText(text: string, width: number): string {
  const words = text.split(" ");
  let lines = [];
  let currentLine = words[0];

  for (let i = 1; i < words.length; i++) {
    if (currentLine.length + 1 + words[i].length <= width) {
      currentLine += " " + words[i];
    } else {
      lines.push(currentLine);
      currentLine = words[i];
    }
  }
  lines.push(currentLine);
  return lines.join("\n");
}

export async function run(dbPathOrId: string) {
  const dbPath = resolveDBPath(dbPathOrId);

  const db = initDB(dbPath);
  const stats: Stats = getStats(db);
  const questions: Question[] = getAllQuestions(db);

  console.log(`Database: ${dbPath}`);
  console.log(`Total Questions: ${stats.totalQuestions}`);
  console.log("\nResponder Stats:");
  console.log("--------------------------------------------------");
  console.log("Responder            | Answers | Evals | Correct");
  console.log("--------------------------------------------------");

  for (const [responder, data] of Object.entries(stats.responders)) {
    const pad = (s: string | number, n: number) => String(s).padEnd(n);
    console.log(
      `${pad(responder, 20)} | ${pad(data.answers, 7)} | ${pad(data.evaluations, 5)} | ${data.correct}`
    );
  }
  console.log("--------------------------------------------------");

  if (questions.length > 0) {
    console.log("\nQuestions:");
    console.log("--------------------------------------------------");
    for (const q of questions) {
      console.log(`Q${q.id}:`);
      console.log("");
      
      console.log("QUESTION");
      console.log("");
      console.log(wrapText(q.text, 80));
      console.log("");

      console.log("ANSWER");
      console.log("");
      console.log(wrapText(q.ground_truth, 80));
      console.log("");

      console.log("RATIONALE");
      console.log("");
      console.log(wrapText(q.rationale, 80));
      console.log("");
      console.log("-".repeat(50));
    }
  }
}

import * as fs from "fs";
import { initDB, getStats } from "../db.js";
import { Stats } from "../types.js";

export async function run(dbPath: string) {
  if (!fs.existsSync(dbPath)) {
    throw new Error(`Database not found: ${dbPath}`);
  }

  const db = initDB(dbPath);
  const stats: Stats = getStats(db);

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
}

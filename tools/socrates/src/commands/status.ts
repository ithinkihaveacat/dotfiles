import * as fs from "fs";
import { initDB, getStats } from "../db.js";
import { Stats } from "../types.js";
import { resolveDBPath } from "../resolve.js";

export async function run(dbPathOrId: string) {
  const dbPath = resolveDBPath(dbPathOrId);

  const db = initDB(dbPath);
  const stats: Stats = getStats(db);

  console.log(`Database: ${dbPath}`);
  console.log(`Total Questions: ${stats.totalQuestions}`);
  
  if (Object.keys(stats.responders).length > 0) {
    console.log("\nResponder Stats:");
    console.log("--------------------------------------------------");
    for (const [responder, data] of Object.entries(stats.responders)) {
      console.log(responder);
      console.log(`  Answers: ${data.answers}   Evals: ${data.evaluations}   Correct: ${data.correct}`);
      console.log("");
    }
    console.log("--------------------------------------------------");
  } else {
    console.log("\nNo answers recorded yet.");
  }
}

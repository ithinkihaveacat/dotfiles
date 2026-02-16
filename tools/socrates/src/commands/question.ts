import { initDB, getAllQuestions } from "../db.js";
import { Question } from "../types.js";
import { resolveDBPath } from "../resolve.js";
import { wrapText } from "../utils.js";

export async function run(dbPathOrId: string) {
  const dbPath = resolveDBPath(dbPathOrId);
  const db = initDB(dbPath);
  const questions: Question[] = getAllQuestions(db);

  if (questions.length > 0) {
    console.log("Questions:");
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
  } else {
    console.log("No questions found.");
  }
}

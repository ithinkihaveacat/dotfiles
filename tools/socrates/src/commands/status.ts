import * as fs from "fs";
import { initDB, getStats } from "../db.js";
import { Stats } from "../types.js";
import { resolveDBPath } from "../resolve.js";
import { truncate } from "../utils.js";

export async function run(dbPathOrId: string) {
  const dbPath = resolveDBPath(dbPathOrId);

  const db = initDB(dbPath);
  const stats: Stats = getStats(db);

  console.log(`Database: ${dbPath}`);
  console.log(`Total Questions: ${stats.totalQuestions}`);
  
  if (Object.keys(stats.responders).length > 0) {
    console.log("");
    
    // Visual width: Model(50) | Ans(6) | Cor(6) | Inc(6) | Pen(6)
    // Emojis: 
    // 📝 (len 2, vis 2) -> padStart(6) -> "    📝" (vis 6)
    // ✅ (len 1, vis 2) -> padStart(5) -> "    ✅" (vis 6)
    // ❌ (len 1, vis 2) -> padStart(5) -> "    ❌" (vis 6)
    // ⏳ (len 1, vis 2) -> padStart(5) -> "    ⏳" (vis 6)

    const hModel = "Model".padEnd(50);
    const hAns = "📝".padStart(6);
    const hCor = "✅".padStart(5);
    const hInc = "❌".padStart(5);
    const hPen = "⏳".padStart(5);
    
    console.log(`${hModel} | ${hAns} | ${hCor} | ${hInc} | ${hPen}`);
    console.log("-".repeat(50 + 3 + 6 + 3 + 6 + 3 + 6 + 3 + 6));

    for (const [responder, data] of Object.entries(stats.responders)) {
      const name = truncate(responder, 50).padEnd(50);
      const incorrect = data.evaluations - data.correct;
      const pending = data.answers - data.evaluations;
      
      const ans = String(data.answers).padStart(6);
      const cor = String(data.correct).padStart(6);
      const inc = String(incorrect).padStart(6);
      const pen = String(pending).padStart(6);
      
      console.log(`${name} | ${ans} | ${cor} | ${inc} | ${pen}`);
    }
    console.log("");
  } else {
    console.log("\nNo answers recorded yet.");
  }
}

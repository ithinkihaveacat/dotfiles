import { initDB, deleteResponder, getAllResponders, getAnswers } from "../db.js";
import { resolveDBPath } from "../resolve.js";
import { CONFIG } from "../config.js";

export async function run(dbPathOrId: string, responder?: string, options: { cleanup?: boolean } = {}) {
  const dbPath = resolveDBPath(dbPathOrId);
  const db = initDB(dbPath);
  
  if (options.cleanup) {
    console.log("Cleaning up incomplete runs...");
    const responders = getAllResponders(db);
    let deletedCount = 0;

    for (const r of responders) {
      const answers = getAnswers(db, -1); // Check all answers for this responder?
      // Wait, getAnswers(db, questionId) gets answers for a question.
      // I need getAnswersForResponder or just filter.
      // Let's use a custom query here for efficiency.
      
      const rows = db.prepare("SELECT text FROM answers WHERE responder = ?").all(r) as { text: string }[];
      
      if (rows.length === 0) continue; // Should not happen based on getAllResponders

      // Check if ALL answers are placeholders
      const allPlaceholders = rows.every(row => row.text === CONFIG.PLACEHOLDER_TEXT);
      
      // Also check if it has very few answers compared to total questions?
      // For now, let's just delete if it ONLY has placeholders (meaning it never really started or crashed immediately).
      // Or maybe if it has ANY placeholder that is old?
      // The requirement was "delete ... runs that only have placeholder answers".
      
      if (allPlaceholders) {
        console.log(`Deleting zombie run '${r}' (only placeholders found)...`);
        deleteResponder(db, r);
        deletedCount++;
      }
    }

    if (deletedCount === 0) {
      console.log("No zombie runs found.");
    } else {
      console.log(`Cleaned up ${deletedCount} runs.`);
    }
    return;
  }

  if (!responder) {
    throw new Error("Responder argument is required unless --cleanup is specified.");
  }

  // Check if responder exists (optional, but good UX)
  const exists = db.prepare("SELECT 1 FROM answers WHERE responder = ? LIMIT 1").get(responder);
  if (!exists) {
    console.warn(`Responder '${responder}' not found in database.`);
    // We don't exit with error, just warn, as deletion is idempotent.
    return;
  }

  deleteResponder(db, responder);
  console.log(`Deleted all records for responder '${responder}'.`);
}

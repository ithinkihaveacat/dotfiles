import { initDB, deleteResponder } from "../db.js";
import { resolveDBPath } from "../resolve.js";

export async function run(dbPathOrId: string, responder: string) {
  const dbPath = resolveDBPath(dbPathOrId);
  const db = initDB(dbPath);
  
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

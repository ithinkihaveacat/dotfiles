import * as fs from "fs";
import * as path from "path";
import { getDataDir } from "./utils.js";

export function resolveDBPath(arg: string): string {
  // 1. Direct file path
  if (fs.existsSync(arg)) {
    return arg;
  }

  const dataDir = getDataDir();
  
  // 2. Try with .db extension in data dir
  const directPath = path.join(dataDir, arg.endsWith(".db") ? arg : `${arg}.db`);
  if (fs.existsSync(directPath)) {
    return directPath;
  }

  // 3. Try prefix match (ID/Hash)
  const files = fs.readdirSync(dataDir).filter(f => f.endsWith(".db"));
  const matches = files.filter(f => f.startsWith(arg));

  if (matches.length === 1) {
    return path.join(dataDir, matches[0]);
  }

  if (matches.length > 1) {
    throw new Error(`Ambiguous database reference '${arg}': matches multiple files: ${matches.join(", ")}`);
  }

  throw new Error(`Database not found: ${arg} (checked path and ID in ${dataDir})`);
}

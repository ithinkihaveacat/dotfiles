import * as path from "path";
import * as fs from "fs";

// Helper to truncate text to fit terminal width.
export function truncate(text: string, maxLen: number): string {
  if (text.length <= maxLen) return text;
  return text.slice(0, maxLen - 3) + "...";
}

export function getDataDir(): string {
  const xdgDataHome = process.env.XDG_DATA_HOME || path.join(process.env.HOME || "", ".local", "share");
  const dataDir = path.join(xdgDataHome, "socrates");

  if (!fs.existsSync(dataDir)) {
    fs.mkdirSync(dataDir, { recursive: true });
  }
  return dataDir;
}

// Helper to process items in parallel with a concurrency limit
export async function mapConcurrent<T, R>(
  items: T[],
  limit: number,
  fn: (item: T, index: number) => Promise<R>
): Promise<R[]> {
  const results: R[] = new Array(items.length);
  let currentIndex = 0;

  const worker = async () => {
    while (currentIndex < items.length) {
      const index = currentIndex++;
      results[index] = await fn(items[index], index);
    }
  };

  const workers = Array(Math.min(limit, items.length))
    .fill(null)
    .map(() => worker());

  await Promise.all(workers);
  return results;
}

import { execFile } from "node:child_process";
import { access } from "node:fs/promises";
import { delimiter, isAbsolute, join } from "node:path";
import { fileURLToPath } from "node:url";

export type Cli = (
  args: string[],
  input?: unknown,
  signal?: AbortSignal
) => Promise<string>;

export function createCli(
  options: {
    script?: string;
    env?: NodeJS.ProcessEnv;
    timeout?: number;
  } = {}
): Cli {
  const env = options.env ?? process.env;
  const bundled = fileURLToPath(
    new URL("../../../../scripts/andon", import.meta.url)
  );

  async function scriptPath(): Promise<string> {
    if (options.script) return options.script;
    try {
      await access(bundled);
      return bundled;
    } catch {
      // Copies outside the skill tree need the existing CLI on PATH.
      return "andon";
    }
  }

  async function onPath(path: string): Promise<string> {
    if (isAbsolute(path) || path.includes("/")) return path;
    for (const directory of (env.PATH ?? "").split(delimiter)) {
      const candidate = join(directory || ".", path);
      try {
        await access(candidate);
        return candidate;
      } catch {
        /* Try the next PATH entry. */
      }
    }
    return path;
  }

  function run(
    argv: string[],
    input: unknown,
    signal?: AbortSignal
  ): Promise<string> {
    return new Promise((resolve, reject) => {
      const child = execFile(
        argv[0],
        argv.slice(1),
        {
          env,
          signal,
          timeout: options.timeout ?? 15_000,
          maxBuffer: 4 * 1024 * 1024,
          killSignal: "SIGKILL",
          encoding: "utf8"
        },
        (error, stdout, stderr) => {
          if (error) {
            reject(
              Object.assign(new Error(stderr.trim() || error.message), {
                code: error.code
              })
            );
          } else resolve(stdout);
        }
      );
      // EPIPE is also reported by the process callback; never crash the host.
      child.stdin?.on("error", () => {});
      child.stdin?.end(input === undefined ? undefined : JSON.stringify(input));
    });
  }

  return async (args, input, signal) => {
    signal?.throwIfAborted();
    const script = await scriptPath();
    try {
      return await run([script, ...args], input, signal);
    } catch (error) {
      signal?.throwIfAborted();
      const code = (error as { code?: string | number }).code;
      if (code !== "ENOENT" && code !== 127) throw error;
      // Andon is standard-library Python >=3.11; uv is not required here.
      return run(["python3", await onPath(script), ...args], input, signal);
    }
  };
}

export async function cliJson<T>(
  cli: Cli,
  args: string[],
  signal?: AbortSignal
): Promise<T> {
  return JSON.parse(await cli(args, undefined, signal)) as T;
}

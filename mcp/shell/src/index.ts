#!/usr/bin/env node
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { spawn } from "child_process";
import { constants } from "os";
import { stat } from "fs/promises";

const MAX_OUTPUT_SIZE = 1024 * 1024; // 1MB cap

const server = new McpServer({
  name: "mcp-shell",
  version: "1.0.0"
});

server.registerTool(
  "run-command",
  {
    title: "Run Shell Command",
    description:
      "Runs a shell command using bash. The command is executed via `bash -c`. Arguments can be passed to the script.",
    inputSchema: {
      command: z.string().describe("The shell command or script to execute."),
      args: z
        .array(z.string())
        .optional()
        .describe(
          "Arguments to pass to the shell script (accessible as $1, $2, etc.)."
        ),
      env: z
        .record(z.string())
        .optional()
        .describe("Environment variables to set."),
      timeout: z
        .number()
        .default(300)
        .describe("Timeout in seconds. Default is 300."),
      stdin: z
        .string()
        .optional()
        .describe("Content to pass to standard input."),
      cwd: z
        .string()
        .optional()
        .describe("The working directory for execution.")
    },
    outputSchema: {
      stdout: z.string(),
      stderr: z.string(),
      exitCode: z
        .number()
        .describe(
          "The exit code of the process. 124 indicates a timeout. 128+N indicates termination by signal N."
        ),
      timedOut: z
        .boolean()
        .describe("Whether the process was terminated due to a timeout.")
    }
  },
  async ({ command, args = [], env = {}, timeout = 300, stdin, cwd }) => {
    // Validate cwd if provided
    if (cwd) {
      try {
        const stats = await stat(cwd);
        if (!stats.isDirectory()) {
          return {
            content: [
              { type: "text", text: `Error: cwd '${cwd}' is not a directory` }
            ],
            isError: true
          };
        }
      } catch (error: any) {
        return {
          content: [
            {
              type: "text",
              text: `Error resolving cwd '${cwd}': ${error.message}`
            }
          ],
          isError: true
        };
      }
    }

    return new Promise((resolve) => {
      let timedOut = false;
      let killedByTimeout = false;

      // Use detached: true to create a new process group, allowing us to kill the whole tree
      const child = spawn("bash", ["-c", command, "bash", ...args], {
        env: { ...process.env, ...env },
        cwd,
        detached: true
      });

      const killProcess = () => {
        if (child.pid) {
          try {
            // Kill the process group
            process.kill(-child.pid, "SIGTERM");
          } catch (e) {
            // Process might be already gone, try simple kill as fallback
            try {
              child.kill("SIGTERM");
            } catch (e2) {}
          }
        }
      };

      const timer = setTimeout(() => {
        timedOut = true;
        killedByTimeout = true;
        killProcess();
      }, timeout * 1000);

      let stdout = "";
      let stderr = "";

      const appendOutput = (target: string, data: string): string => {
        if (target.length >= MAX_OUTPUT_SIZE) return target;
        const newLength = target.length + data.length;
        if (newLength > MAX_OUTPUT_SIZE) {
          return (
            target +
            data.slice(0, MAX_OUTPUT_SIZE - target.length) +
            "\n... [Truncated]"
          );
        }
        return target + data;
      };

      if (child.stdout) {
        child.stdout.on("data", (data) => {
          stdout = appendOutput(stdout, data.toString());
        });
      }

      if (child.stderr) {
        child.stderr.on("data", (data) => {
          stderr = appendOutput(stderr, data.toString());
        });
      }

      if (child.stdin) {
        child.stdin.on("error", () => {
          // Ignore EPIPE
        });
        if (stdin) {
          child.stdin.write(stdin);
        }
        child.stdin.end();
      }

      let errorOccurred = false;

      child.on("error", (err: any) => {
        errorOccurred = true;
        clearTimeout(timer);
        const output = {
          stdout,
          stderr:
            stderr +
            (stderr ? "\n" : "") +
            `Error spawning process: ${err.message}`,
          exitCode: 1,
          timedOut: false
        };

        resolve({
          content: [{ type: "text", text: JSON.stringify(output) }],
          structuredContent: output,
          isError: true
        });
      });

      child.on("close", (code, signal) => {
        if (errorOccurred) return;
        clearTimeout(timer);

        let finalCode = 0;

        if (killedByTimeout) {
          finalCode = 124;
        } else if (code !== null) {
          finalCode = code;
        } else if (signal !== null) {
          const signalNumber = (constants.signals as any)[signal] || 0;
          finalCode = 128 + signalNumber;
        }

        const output = {
          stdout,
          stderr,
          exitCode: finalCode,
          timedOut: killedByTimeout
        };

        resolve({
          content: [{ type: "text", text: JSON.stringify(output) }],
          structuredContent: output
        });
      });
    });
  }
);

const transport = new StdioServerTransport();
await server.connect(transport);

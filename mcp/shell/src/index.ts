import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { z } from 'zod';
import { spawn } from 'child_process';

const server = new McpServer({
  name: 'mcp-shell',
  version: '0.1.0',
});

server.registerTool(
  'run-command',
  {
    title: 'Run Shell Command',
    description: 'Runs a shell command using bash. The command is executed via `bash -c`. Arguments can be passed to the script.',
    inputSchema: {
      command: z.string().describe('The shell command or script to execute.'),
      args: z.array(z.string()).optional().describe('Arguments to pass to the shell script (accessible as $1, $2, etc.).'),
      env: z.record(z.string()).optional().describe('Environment variables to set.'),
      timeout: z.number().default(300).describe('Timeout in seconds. Default is 300.'),
      stdin: z.string().optional().describe('Content to pass to standard input.'),
    },
    outputSchema: {
      stdout: z.string(),
      stderr: z.string(),
      code: z.number().nullable(),
      timedOut: z.boolean(),
    },
  },
  async ({ command, args = [], env = {}, timeout = 300, stdin }) => {
    return new Promise((resolve) => {
      const controller = new AbortController();
      const { signal } = controller;

      const timer = setTimeout(() => {
        controller.abort();
      }, timeout * 1000);

      const childEnv = { ...process.env, ...env };

      const child = spawn('bash', ['-c', command, 'bash', ...args], {
        env: childEnv,
        signal,
      });

      let stdout = '';
      let stderr = '';

      if (child.stdout) {
        child.stdout.on('data', (data) => {
          stdout += data.toString();
        });
      }

      if (child.stderr) {
        child.stderr.on('data', (data) => {
          stderr += data.toString();
        });
      }

      if (child.stdin) {
        child.stdin.on('error', () => {
          // Ignore stdin errors (e.g. EPIPE if the process exits early)
        });
        if (stdin) {
          child.stdin.write(stdin);
        }
        child.stdin.end();
      }

      let timedOut = false;
      let errorOccurred = false;

      child.on('error', (err: any) => {
        if (err.name === 'AbortError') {
          timedOut = true;
        } else {
          errorOccurred = true;
          clearTimeout(timer);
          const result = {
            stdout,
            stderr: stderr + (stderr ? '\n' : '') + `Error spawning process: ${err.message}`,
            code: -1,
            timedOut: false,
          };
          resolve({
            content: [{ type: 'text', text: JSON.stringify(result) }],
            structuredContent: result,
          });
        }
      });

      child.on('close', (code) => {
        if (errorOccurred) return;
        clearTimeout(timer);

        const result = {
          stdout,
          stderr,
          code: timedOut ? null : code,
          timedOut,
        };

        resolve({
          content: [{ type: 'text', text: JSON.stringify(result) }],
          structuredContent: result,
        });
      });
    });
  }
);

const transport = new StdioServerTransport();
await server.connect(transport);

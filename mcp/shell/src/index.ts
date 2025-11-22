#!/usr/bin/env node

import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { spawn } from 'child_process';
import { z } from 'zod';

const server = new McpServer({
    name: 'shell-server',
    version: '1.0.0'
});

/**
 * Execute a shell command using bash with optional environment variables, timeout, and stdin.
 *
 * The command is executed as: timeout <timeout_seconds> bash -c "<command>"
 *
 * Exit codes from the timeout command:
 * - 0: Command completed successfully
 * - 1-123: Command's actual exit code
 * - 124: Timeout expired
 * - 125: timeout command itself failed
 * - 126: Command found but not executable
 * - 127: Command not found
 * - 128+N: Command terminated by signal N (e.g., 137 = 128+9 for SIGKILL)
 *
 * The timedOut flag is true when exitCode is in the range 124-137 (timeout-related codes).
 */
server.registerTool(
    'execute_shell',
    {
        title: 'Execute Shell Command',
        description: 'Execute a shell command using bash. Supports environment variables, timeouts, and stdin input. Simple commands like "ls" or complex ones with pipes work directly.',
        inputSchema: {
            command: z.string(),
            env: z.record(z.string(), z.string()).optional(),
            timeout: z.number().optional(),
            stdin: z.string().optional()
        },
        outputSchema: {
            stdout: z.string(),
            stderr: z.string(),
            exitCode: z.number(),
            timedOut: z.boolean()
        }
    },
    async ({ command, env, timeout, stdin }: { command: string; env?: Record<string, string>; timeout?: number; stdin?: string }) => {
        const timeoutSeconds = timeout ?? 300;

        return new Promise((resolve) => {
            // Construct the command: timeout <seconds> bash -c "<command>"
            const args = [
                timeoutSeconds.toString(),
                'bash',
                '-c',
                command
            ];

            // Set up environment variables
            const processEnv = { ...process.env };
            if (env) {
                Object.assign(processEnv, env);
            }

            // Spawn the process with timeout
            const child = spawn('timeout', args, {
                env: processEnv,
                shell: false
            });

            let stdout = '';
            let stderr = '';

            // Capture stdout
            child.stdout.on('data', (data) => {
                stdout += data.toString();
            });

            // Capture stderr
            child.stderr.on('data', (data) => {
                stderr += data.toString();
            });

            // Handle stdin if provided
            if (stdin !== undefined && stdin !== '') {
                child.stdin.write(stdin);
            }
            child.stdin.end();

            // Handle process completion
            child.on('close', (code) => {
                // Pass through the actual exit code from timeout
                const exitCode = code ?? 0;

                // timeout command uses exit codes 124-137 for timeout-related statuses
                // 124: timeout expired, 125-137: various timeout/signal issues
                const timedOut = exitCode >= 124 && exitCode <= 137;

                const output = {
                    stdout,
                    stderr,
                    exitCode,
                    timedOut
                };

                resolve({
                    content: [{
                        type: 'text',
                        text: JSON.stringify(output, null, 2)
                    }],
                    structuredContent: output
                });
            });

            // Handle errors in spawning the process
            child.on('error', (error) => {
                const output = {
                    stdout: '',
                    stderr: `Failed to execute command: ${error.message}`,
                    exitCode: 1,
                    timedOut: false
                };

                resolve({
                    content: [{
                        type: 'text',
                        text: JSON.stringify(output, null, 2)
                    }],
                    structuredContent: output,
                    isError: true
                });
            });
        });
    }
);

// Connect to stdio transport
const transport = new StdioServerTransport();
await server.connect(transport);

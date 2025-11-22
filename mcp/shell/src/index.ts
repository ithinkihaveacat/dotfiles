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
 * Exit codes:
 * - null: The timeout expired (timeout command returns 124)
 * - number: The actual exit code from the command
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
            exitCode: z.number().nullable(),
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
                // The timeout command returns 124 when it times out
                const timedOut = code === 124;

                // If timed out, set exitCode to null, otherwise use the actual exit code
                const exitCode = timedOut ? null : (code ?? 0);

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
                    exitCode: null,
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

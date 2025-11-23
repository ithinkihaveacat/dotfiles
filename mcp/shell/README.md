# MCP Shell Server

A Model Context Protocol (MCP) server that enables executing shell commands via
`bash`.

## Tools

### `run-command`

Executes a shell command or script.

**Inputs:**

- `command` (string, required): The shell command or script to execute.
- `args` (array of strings, optional): Arguments passed to the script
  (accessible as `$1`, `$2`, etc.).
- `env` (object, optional): Environment variables to set.
- `timeout` (number, optional): Timeout in seconds (default: 300).
- `stdin` (string, optional): Content to pass to standard input.

**Outputs:**

- `stdout` (string): Standard output.
- `stderr` (string): Standard error.
- `exitCode` (number): Exit code.
  - `0`: Success.
  - `1-123`: Command failure.
  - `124`: Timeout.
  - `128+N`: Terminated by signal N (e.g., 143 for SIGTERM).
- `timedOut` (boolean): True if the process was terminated due to timeout.

## Usage

This server is intended to be used by MCP clients to enable agents to run shell
commands.

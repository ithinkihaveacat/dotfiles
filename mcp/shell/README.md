# MCP Shell Server

An MCP (Model Context Protocol) server for executing shell commands safely with timeouts, environment variables, and stdin support.

## Features

- **Execute shell commands** using bash
- **Environment variables** - Set custom environment variables for commands
- **Timeout support** - Commands timeout after 300 seconds by default (configurable)
- **Stdin support** - Provide input to commands via stdin
- **Comprehensive output** - Captures stdout, stderr, exit codes, and timeout status

## Installation

```bash
npm install
npm run build
```

## Usage

The server runs over stdio and provides a single tool: `execute_shell`.

### Tool: execute_shell

Execute a shell command using bash.

**Parameters:**
- `command` (string, required): The shell command to execute
  - Simple: `"ls -la"`
  - Complex: `"echo hello | grep h"`
  - Multi-line: `"for i in 1 2 3; do echo $i; done"`
- `env` (object, optional): Environment variables to set
  - Example: `{"MY_VAR": "value", "DEBUG": "true"}`
- `timeout` (number, optional): Timeout in seconds (default: 300)
- `stdin` (string, optional): Input to provide via stdin

**Returns:**
- `stdout` (string): Standard output from the command
- `stderr` (string): Standard error from the command
- `exitCode` (number | null): Exit code, or null if timeout expired
- `timedOut` (boolean): True if command was terminated due to timeout

### Examples

**Simple command:**
```json
{
  "command": "ls -la"
}
```

**Command with environment variables:**
```json
{
  "command": "echo $MY_VAR",
  "env": {"MY_VAR": "Hello World"}
}
```

**Command with stdin:**
```json
{
  "command": "grep hello",
  "stdin": "hello world\nfoo bar\nhello again"
}
```

**Command with custom timeout:**
```json
{
  "command": "sleep 10",
  "timeout": 5
}
```
This will timeout after 5 seconds, returning `exitCode: null` and `timedOut: true`.

## Testing

You can test the server using the MCP Inspector:

```bash
npx @modelcontextprotocol/inspector node dist/index.js
```

## How It Works

Commands are executed using:
```bash
timeout <seconds> bash -c "<command>"
```

- The `timeout` utility enforces the time limit
- When timeout expires, the command returns exit code 124, which is detected and reported as `timedOut: true` with `exitCode: null`
- All other exit codes are passed through normally

# MCP Shell Server

A Model Context Protocol (MCP) server that enables executing shell commands via
`bash`. Designed to be robust, secure, and easy to use for agents.

## Features

- **Execute Shell Commands**: Runs commands via `bash -c`.
- **Arguments**: Pass arguments safely to the script (accessible as `$1`, `$2`,
  etc.).
- **Environment Variables**: Set custom environment variables.
- **Input (stdin)**: Pipe content to the command's standard input.
- **Working Directory**: Specify the directory to execute the command in.
- **Timeout**: Configurable timeout (default 300s) with process group killing.
- **Standard Exit Codes**: Returns 124 for timeout, 128+N for signals.
- **Output Guard**: Caps output size to 1MB to prevent memory issues.

## Tools

### `run-command`

Executes a shell command or script.

#### Parameters

- `command` (string, required): The shell command or script to execute.
- `args` (array of strings, optional): Arguments passed to the script.
- `env` (object, optional): Environment variables to set.
- `cwd` (string, optional): The directory to run the command in.
- `timeout` (number, optional): Timeout in seconds (default: 300).
- `stdin` (string, optional): Content to pass to standard input.

#### Output

- `stdout` (string): Standard output (truncated at 1MB).
- `stderr` (string): Standard error (truncated at 1MB).
- `exitCode` (number): The exit code.
  - `0`: Success.
  - `1-123`: Command failure.
  - `124`: Timeout.
  - `128+N`: Terminated by signal N (e.g. 143 for SIGTERM).
- `timedOut` (boolean): True if the process was terminated due to timeout.

## Examples

### Simple Command

```json
{
  "name": "run-command",
  "arguments": {
    "command": "ls -la"
  }
}
```

### With Arguments

```json
{
  "name": "run-command",
  "arguments": {
    "command": "echo Hello $1",
    "args": ["World"]
  }
}
```

### With Environment Variables

```json
{
  "name": "run-command",
  "arguments": {
    "command": "echo $MY_VAR",
    "env": { "MY_VAR": "secret" }
  }
}
```

### With Stdin

```json
{
  "name": "run-command",
  "arguments": {
    "command": "grep foo",
    "stdin": "bar\nfoo\nbaz"
  }
}
```

### With Timeout

```json
{
  "name": "run-command",
  "arguments": {
    "command": "sleep 10",
    "timeout": 2
  }
}
```

## Testing

You can test this server using the
[MCP Inspector](https://github.com/modelcontextprotocol/inspector).

1. Build the server: `npm install && npm run build`
2. Run with inspector: `npx @modelcontextprotocol/inspector node dist/index.js`

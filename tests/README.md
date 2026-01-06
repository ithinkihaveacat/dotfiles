# Tests

This directory contains tests for scripts in `bin/`. Tests use TAP (Test
Anything Protocol) format.

## Directory Structure

```
tests/
├── README.md
├── script-name/
│   ├── test-basic       # TAP test file (executable)
│   └── fixtures/        # Test data (optional)
└── another-script/
    └── test-basic
```

## Running Tests

The following examples assume you are running from the `tests/` directory.

### Run All Tests

```bash
prove */test-*
```

Or with verbose output:

```bash
prove -v */test-*
```

### Run a Single Test Suite

```bash
prove jetpack-resolve/test-*
```

### Run a Single Test File

```bash
prove jetpack-resolve/test-basic
```

Or execute directly:

```bash
./jetpack-resolve/test-basic
```

## File Naming Convention

Test files are named `test-*` (e.g., `test-basic`, `test-edge-cases`) rather
than using the `.t` extension. While `.t` is prove's default extension, the
`test-*` pattern:

- Works identically with prove via `prove */test-*`
- Can be executed directly without prove
- Is more self-documenting for shell scripts

## Tests with External Dependencies

Some tests require external services or API keys. These tests use TAP's skip
mechanism to gracefully handle missing dependencies.

### screenshot-compare

Requires `GEMINI_API_KEY` environment variable. Tests are automatically skipped
if not set:

```bash
# Without key - tests are skipped
prove screenshot-compare/test-*
# Output: skipped: GEMINI_API_KEY not set

# With key - tests run (slow, incurs API costs)
GEMINI_API_KEY=your-key prove screenshot-compare/test-*
```

## Writing Tests

Tests should:

1. Output TAP format (plan line `1..N`, then `ok`/`not ok` lines)
2. Be executable (`chmod +x`)
3. Use `#!/usr/bin/env bash` shebang
4. Skip gracefully when dependencies are missing using `1..0 # SKIP reason`

Example test structure:

```bash
#!/usr/bin/env bash

set -u

# Skip if dependency missing
if [[ -z "${SOME_API_KEY:-}" ]]; then
  echo "1..0 # SKIP SOME_API_KEY not set"
  exit 0
fi

echo "1..2"

# Test 1
if some_condition; then
  echo "ok 1 - description"
else
  echo "not ok 1 - description"
fi

# Test 2
if other_condition; then
  echo "ok 2 - another test"
else
  echo "not ok 2 - another test"
fi
```

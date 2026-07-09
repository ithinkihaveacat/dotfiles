# Tests

Tests in this repository are **co-located** and **flattened** under their
respective scopes to keep them together in the directory structure.

- Tests for skills (e.g., `skills/bar/scripts/foo`) live directly under that
  skill's `tests/` folder as a flat executable file (e.g.,
  `skills/bar/tests/test-foo`).
- Tests for global utilities (scripts in `bin/`) live directly under the global
  `tests/` folder as a flat executable file (e.g., `tests/test-git-setup`).
- Test data and resources are stored in a `fixtures/` subdirectory under the
  corresponding `tests/` folder (e.g.,
  `skills/agent-tools/tests/fixtures/pacioli/`).

> [!NOTE] **Run tests selectively!** You only need to run the tests for the
> skill or script you actually touched or modified, rather than the entire test
> suite. This keeps development fast and avoids running slow or heavy
> external-dependency tests unnecessarily.

## Running Tests

Tests use the TAP (Test Anything Protocol) format and can be run using the
standard `prove` utility.

### Run All Tests in the Repo

From the repository root:

```bash
prove tests/test-* skills/*/tests/test-*
```

You can run the tests in parallel to speed up execution by using the `-j` flag:

```bash
# Run in parallel with 9 jobs
prove -j 9 tests/test-* skills/*/tests/test-*
```

### Run Tests for a Particular Skill

To run all tests for a specific skill (e.g., `coding-standards`):

```bash
prove skills/coding-standards/tests/test-*
```

### Run a Specific Test File

You can run a single test file using `prove`:

```bash
prove skills/workspace-config/tests/test-permission
```

Or execute the test script directly:

```bash
./skills/workspace-config/tests/test-permission
```

## Offline & Isolated Environments

To ensure tests run reliably in sandboxed local environments and CI, you should
utilize the following environment variables:

### 1. Registry Auth Bypass (`UV_OFFLINE=1`)

In isolated developer sandboxes (like local agent environments), `uv` may try to
query corporate Python package registries and fail with `401 Unauthorized`
errors.

- **Solution**: Run the tests with `UV_OFFLINE=1` set in the environment. This
  instructs `uv` to completely bypass network registry checks and resolve
  dependencies using only locally cached packages.
- **Usage**:
  ```bash
  UV_OFFLINE=1 prove tests/test-* skills/*/tests/test-*
  ```
- **Warming the cache**: Offline resolution only works if the packages have been
  downloaded at least once, so run the tool (or its tests) outside the isolated
  environment first. Test suites that override `HOME` or `XDG_CONFIG_HOME` for
  hermeticity hide the host cache; share it by also exporting
  `UV_CACHE_DIR=~/.cache/uv`.

### 2. Skipping External API Tests (`GEMINI_API_KEY=""`)

Some tests (like `test-pacioli` and `test-git-setup`) include integration tests
that make actual network calls to the Gemini API. These can be slow, cost quota,
and be non-deterministic.

- **Solution**: Set `GEMINI_API_KEY=""` (empty string) in the environment. These
  tests are written to detect the empty key and will gracefully skip their
  API-dependent assertions while passing the rest of the local suite. Run the
  API-dependent tests manually when making substantive changes to the tested
  script.
- **Usage**:
  ```bash
  GEMINI_API_KEY="" prove tests/test-* skills/*/tests/test-*
  ```

### Combined Command for Local Sandboxes & CI

To run the entire test suite in a completely fast, local-only, offline, and
deterministic mode:

```bash
UV_OFFLINE=1 GEMINI_API_KEY="" prove tests/test-* skills/*/tests/test-*
```

## Writing Tests

When writing new tests or modifying existing ones, follow these guidelines:

1. **Output TAP format**: The test must print a plan line (e.g., `1..N`)
   followed by `ok` or `not ok` lines for each assertion.
1. **Co-locate and flatten**:
   - If the script is part of a skill `skills/bar/scripts/foo`, its tests must
     be placed directly at `skills/bar/tests/test-foo` (as a file, not a
     directory).
   - For global utilities, place the test directly at `tests/test-foo`.
1. **Use self-contained paths**: Reference the script under test using relative
   paths (e.g., `../scripts/foo` for skill tests, or `../bin/foo` for global
   tests) rather than relying on the user's global `PATH`. This ensures tests
   are completely self-contained.
1. **Be executable**: Run `chmod +x` on test scripts.
1. **Link back from the script**: Add a `# Tests:` comment near the top of the
   script under test pointing at its test file (e.g.,
   `# Tests: tests/test-foo`), so tests are discoverable via
   `grep '# Tests:' bin/my-script`.
1. **Graceful skips**: If a test requires external dependencies or credentials
   (like `GEMINI_API_KEY`), detect their absence and skip gracefully using TAP
   skip syntax:
   ```bash
   if [[ -z "${GEMINI_API_KEY:-}" ]]; then
     echo "1..0 # SKIP GEMINI_API_KEY not set"
     exit 0
   fi
   ```
1. **Parallel-safe**: Avoid hardcoding temporary filenames or writing to shared
   global locations. Always use `mktemp -d` and clean up on exit.

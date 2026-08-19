# Troubleshooting

## Contents

- [Environment Issues](#environment-issues)
- [Dependency Issues](#dependency-issues)
- [API Errors](#api-errors)
- [File Issues](#file-issues)
- [Output Issues](#output-issues)
- [Caxton (Repository Transformation) Issues](#caxton-repository-transformation-issues)
- [Popper (Android UI) Issues](#popper-android-ui-issues)
- [Platform Differences](#platform-differences)

______________________________________________________________________

## Environment Issues

### Missing GEMINI_API_KEY

**Error:**

```text
script-name: GEMINI_API_KEY environment variable not set
```

**Solution:**

```bash
export GEMINI_API_KEY="your-api-key-here"
```

**Verify:**

```bash
echo $GEMINI_API_KEY
```

______________________________________________________________________

## Dependency Issues

### Missing curl

**Error:** `exit code 127` or `curl: command not found`

**Solution (Debian/Ubuntu):**

```bash
sudo apt-get install curl
```

**Solution (macOS):**

```bash
# curl is pre-installed on macOS
```

### Missing jq

**Error:** `exit code 127` or `jq: command not found`

**Solution (Debian/Ubuntu):**

```bash
sudo apt-get install jq
```

**Solution (macOS):**

```bash
brew install jq
```

### Missing base64

**Error:** `exit code 127` or `base64: command not found`

**Solution:** `base64` is part of coreutils and should be pre-installed. If
missing:

```bash
# Debian/Ubuntu
sudo apt-get install coreutils

# macOS - pre-installed
```

### Missing magick (ImageMagick)

**Error:** `exit code 127` or `magick: command not found`

**Solution (Debian/Ubuntu):**

```bash
sudo apt-get install imagemagick
```

**Solution (macOS):**

```bash
brew install imagemagick
```

### Missing uv

**Error:** `exit code 127` or `uv: command not found`

**Solution:**

Install `uv` according to the official instructions
(<https://docs.astral.sh/uv/>):

```bash
# macOS / Linux
curl -LsSf https://astral.sh/uv/install.sh | sh
```

**Verify installation:**

```bash
uv --version
```

______________________________________________________________________

## API Errors

### Invalid API Key

**Error:**

```text
API error: API key not valid. Please pass a valid API key.
```

**Solution:**

1. Verify your API key is correct
1. Check for extra whitespace or newlines
1. Regenerate key at [Google AI Studio](https://aistudio.google.com/apikey)

### Rate Limits

**Error:**

```text
API error: Resource has been exhausted (e.g. check quota).
```

**Solution:**

1. Wait and retry after a few seconds
1. Check your quota at Google Cloud Console
1. Consider using a different API key or project

### Quota Exceeded

**Error:**

```text
API error: Quota exceeded for quota metric
```

**Solution:**

1. Wait for quota to reset (usually daily)
1. Request quota increase in Google Cloud Console
1. Use a paid tier if on free tier

### Model Not Found

**Error:**

```text
API error: models/model-name is not found
```

**Solution:**

1. Verify the model name is correct
1. Check if model is available in your region
1. Some models require specific API access

______________________________________________________________________

## File Issues

### Image File Not Found

**Error:**

```text
script-name: path/to/image.png: No such file or directory
```

**Solution:**

1. Check file path is correct
1. Use absolute path if relative path fails
1. Verify file exists: `ls -la path/to/image.png`

### Unsupported Image Format

**Error:** ImageMagick conversion fails or produces garbled output

**Solution:**

1. Use common formats: PNG, JPEG, WebP, GIF

1. Convert manually first:

   ```bash
   magick input.bmp output.png
   ```

1. Check ImageMagick supports the format:

   ```bash
   magick identify input.file
   ```

### Image File Unreadable

**Error:** Permission denied or file locked

**Solution:**

```bash
# Check permissions
ls -la image.png

# Fix permissions
chmod 644 image.png
```

______________________________________________________________________

## Output Issues

### No Response Text from API

**Error:**

```text
script-name: no response text received from API
```

**Causes:**

1. Content was blocked by safety filters
1. Request was malformed
1. API returned empty response

**Solution:**

1. Try with a different image
1. Check if image contains sensitive content
1. Verify request format matches expected schema

### Images Are Identical (screenshot-compare)

**Error:**

```text
The images are identical.
script-name: error: input images are identical
```

**Exit code:** 2

**This is expected behavior.** The script exits with code 2 when the two images
are byte-identical after encoding.

**If images look different but report as identical:**

1. Check if difference is only in alpha channel (transparency)
1. Verify you're comparing the correct files
1. Check for invisible differences (metadata only)

### Unexpected Crop Region (photo-smart-crop)

**Cause:** The Gemini API picks the primary subject (people, food, focal
points); if it finds no specific focal point, it returns a box covering the
central compositional area, so the script always produces a crop.

**Solutions:**

1. Try with a clearer or higher-resolution image
1. Adjust `--ratio` if the subject does not fit the requested aspect ratio

### Rate Limited (photo-smart-crop)

**Exit code:** 2

**Cause:** API returned HTTP 429 (rate limit exceeded).

**Solutions:**

1. Wait and retry after a few seconds
1. Implement exponential backoff in calling scripts
1. Check your Gemini API quota

### Invalid Ratio Format (photo-smart-crop)

**Error:**

```text
photo-smart-crop: invalid ratio format: abc (expected W:H, e.g., 5:3)
```

**Solution:** Use the format `W:H` where W and H are positive integers:

```bash
scripts/photo-smart-crop --ratio 16:9 input.jpg output.jpg
scripts/photo-smart-crop --ratio 1:1 input.jpg output.jpg
```

### Truncated or Incomplete Output

**Cause:** Response exceeded token limits

**Solution for emerson:** The script uses `maxOutputTokens: 8192`. For longer
content:

1. Break input into smaller chunks
1. Process incrementally
1. Combine results

### Missing or Empty Input (token-count, satisfies)

**Error:**

```text
token-count: no input provided on stdin
satisfies: missing input from stdin
```

**Cause:** No input was piped to the script, or the input was empty.

**Solution:**

```bash
# Correct usage - pipe input
cat file.txt | scripts/token-count
cat file.txt | scripts/satisfies "condition"
echo "text" | scripts/satisfies "condition"

# Incorrect - no input
scripts/satisfies "condition"  # Will fail
```

### Unexpected Boolean Result (satisfies)

**Issue:** `satisfies` returns true/false unexpectedly

**Possible causes:**

1. Condition is ambiguous
1. Input text doesn't clearly match/contradict the condition
1. AI model interpretation differs from expectation

**Solutions:**

1. Make conditions more specific:

   ```bash
   # Vague
   cat file.txt | scripts/satisfies "is good"

   # Specific
   cat file.txt | scripts/satisfies "contains the word 'approved'"
   ```

1. Test with known inputs first

1. Use explicit phrasing like "contains", "mentions", "starts with"

______________________________________________________________________

## Caxton (Repository Transformation) Issues

### Not Inside a Git Worktree

**Error:** `caxton: error: not inside a git worktree: <dir>`

**Solution:**

Caxton runs only inside a git repository. Git decides what is ignored, and git
is the only undo a run has: `git checkout -- .` restores files it modified and
`git clean -fd` removes the ones it created. Work inside a repository, or
`git init` the directory first and commit before a mutation run.

### Uncommitted Changes Block a Mutation Run

**Error:**
`caxton: error: '<dir>' has uncommitted changes; a mutation run cannot be undone cleanly`

**Solution:**

A run that can write rewrites files with no undo of its own, so it insists on a
clean worktree — otherwise its changes cannot be told apart from yours. Commit
or stash first, drop the `--edit` to run read-only, or override:

```bash
git add -A && git commit -m wip                       # or git stash
scripts/caxton "PROMPT" --read src/                   # read-only, no guard
scripts/caxton --force "PROMPT" --edit src/           # override the guard
```

A freshly `git init`ed repository has no commits, so every file is untracked and
the worktree counts as dirty. Commit once before the first mutation run.

### PROMPT Is Required

**Error:** `caxton: error: PROMPT is required`, followed by
`PROMPT must come before --read/--edit/--inline`

**Solution:**

`--read`, `--edit` and `--inline` each take a list of paths and consume every
following argument up to the next option, so a prompt written after them is
swallowed as a path. Put the prompt first:

```bash
scripts/caxton "PROMPT" --edit docs/     # correct
scripts/caxton --edit docs/ "PROMPT"     # the prompt becomes a path
```

### A Path Cannot Be Made Writable

**Error:**
`caxton: error: N selected path(s) are ignored by git, which cannot restore them`

**Solution:**

Everything writable must be restorable. Git can undo an edit to a tracked file
and can `git clean` an untracked one, but it will do neither for an ignored
file, so caxton refuses to write one. Select it with `--read` instead, track it
with `git add`, or pass `--force` to accept that the `[caxton]` change report is
the only record of what happened.

The same rule applies during a run: `write_file` refuses to create a path git
would ignore.

### Expected Files Are Missing From the Context

**Symptom:** the report says a file does not exist, or a transformation skips
files that are plainly there.

**Solution:**

Only what you selected is visible. With no `--read`/`--edit` the selection is
the current directory, and paths outside it are invisible to every tool, not
merely absent from the initial prompt. On top of that, git decides what is
ignored (`git ls-files --cached --others --exclude-standard`), so anything
covered by a nested `.gitignore` or by `core.excludesFile` is excluded unless
you name it explicitly on the command line. Symlinks, submodules and non-regular
files are never included. Confirm what a run will actually see:

```bash
scripts/caxton --dry-run "PROMPT" --edit src/
git ls-files --cached --others --exclude-standard   # the same ignore rules
```

If the selection leaves nothing at all, caxton exits with
`no files to work with` rather than sending an empty tree to the model.

### A Credential File Is Missing From the Context

**Symptom:** a `.npmrc`, `.netrc`, `*.pem` or `.ssh/` path is absent from the
resolved file list, or naming one is an error.

**Solution:**

This is deliberate: caxton never sends credential paths to the model, even when
they are not gitignored, and naming one explicitly is a hard error rather than a
silent omission. `--dry-run` lists them under "Excluded (credential patterns)".
There is no flag to override it — copy the specific file you really need
transformed to another name and run caxton on that.

### Refusing to Edit a File

**Error:** `'<path>' is not valid UTF-8; refusing to edit it`

**Solution:**

The file is text-like but not UTF-8 (often legacy Latin-1). Rewriting it would
replace every undecodable byte with U+FFFD, so caxton declines. Convert the file
first (`iconv -f latin1 -t utf-8`) or leave it out of the selection.

### Timed Out (Exit Code 2)

**Error:** `caxton: timed out after N seconds`

**Solution:**

The run is bounded by `--timeout` (default 1800s) and `--max-steps` (default
100), and the timeout covers directory traversal as well as the agent loop. A
timeout during a mutation run leaves a partly transformed tree; the `[caxton]`
footer on stderr lists every file modified, created, and deleted. Undoing it
takes two steps, because files the run created are untracked:

```bash
git checkout -- .   # restore files the run modified
git clean -n -d     # review what it created
git clean -f -d     # remove those
```

Raise `--timeout` for large selections, or narrow the prompt.

### Context Exceeds the 1MB Threshold

**Error:** `inlined text (N MB) exceeds 1MB threshold`

**Solution:**

The threshold counts only what is inlined, so narrowing the initial context is
usually enough: `--inline PATH...` inlines a subset of what is visible, and
`--no-inline` sends only the file tree so the agent reads on demand. Selecting
fewer paths works too, and `--force` inlines anyway. A `--dry-run` over the
threshold still prints the full resolved file list before reporting the error,
so it shows which files consumed the budget.

______________________________________________________________________

## Popper (Android UI) Issues

### Device Not Found

**Error:** `uiautomator2.exceptions.DeviceNotFoundError` or ADB device missing

**Solution:**

Ensure a device or emulator is running and accessible via ADB:

```bash
# Check connected devices
adb devices
```

If multiple devices are connected, set `ANDROID_SERIAL`:

```bash
export ANDROID_SERIAL="your-device-id"
scripts/popper "goal"
```

### uiautomator2 Server Error

**Error:** `uiautomator2` fails to start or connect

**Solution:**

`uiautomator2` installs a background server on the device. Sometimes this needs
to be reinitialized:

```bash
uv run python -m uiautomator2 init
```

### Leaving Application Boundaries

**Error:** Task fails after using `--stay-in-app`

**Solution:**

The agent left the restricted application package. If the goal requires
interacting with system dialogs or other apps, run `popper` without the
`--stay-in-app` flag. If you want to start in a specific app and keep the run
inside it, combine `--launch PACKAGE --stay-in-app`.

______________________________________________________________________

## Platform Differences

### base64 Flag Differences

**Linux:**

```bash
base64 -w 0  # Wrap at 0 (no wrapping)
```

**macOS:**

```bash
base64 -b 0  # Break at 0 (no line breaks)
```

The scripts detect and handle this automatically. For raw API commands, use the
appropriate flag for your platform.

### Path Differences

**Linux/macOS:** Use forward slashes

```bash
scripts/screenshot-describe ./images/screenshot.png
```

**Windows (WSL):** Convert paths if needed

```bash
scripts/screenshot-describe /mnt/c/Users/name/screenshot.png
```

______________________________________________________________________

## Network Issues

### Connection Timeout

**Error:** curl timeout or connection refused

**Solution:**

1. Check internet connectivity

1. Verify firewall allows HTTPS to `generativelanguage.googleapis.com`

1. Try with explicit timeout:

   ```bash
   curl --connect-timeout 30 ...
   ```

### SSL/TLS Errors

**Error:** SSL certificate problem

**Solution:**

1. Update CA certificates:

   ```bash
   # Debian/Ubuntu
   sudo apt-get update && sudo apt-get install ca-certificates
   ```

1. Check system time is correct

1. Verify no proxy is interfering

______________________________________________________________________

## Large Image Handling

### Request Too Large

**Cause:** Image file size too large for API limits

**Solution:**

1. Resize before processing:

   ```bash
   magick large.png -resize 2048x2048\> resized.png
   ```

1. Increase compression (lossy):

   ```bash
   magick large.png -quality 85 compressed.jpg
   ```

### Processing Timeout

**Cause:** Large images take longer to encode and transmit

**Solution:**

1. Resize images to reasonable dimensions (2048px max recommended)
1. Use JPEG for photos (smaller than PNG)
1. Process in batches if comparing many images

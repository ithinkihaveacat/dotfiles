# Troubleshooting

## Contents

- [Environment Issues](#environment-issues)
- [Dependency Issues](#dependency-issues)
- [API Errors](#api-errors)
- [File Issues](#file-issues)
- [Output Issues](#output-issues)
- [Platform Differences](#platform-differences)

---

## Environment Issues

### Missing GEMINI_API_KEY

**Error:**

```
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

---

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

**Verify installation:**

```bash
magick --version
```

---

## API Errors

### Invalid API Key

**Error:**

```
API error: API key not valid. Please pass a valid API key.
```

**Solution:**

1. Verify your API key is correct
2. Check for extra whitespace or newlines
3. Regenerate key at [Google AI Studio](https://aistudio.google.com/apikey)

### Rate Limits

**Error:**

```
API error: Resource has been exhausted (e.g. check quota).
```

**Solution:**

1. Wait and retry after a few seconds
2. Check your quota at Google Cloud Console
3. Consider using a different API key or project

### Quota Exceeded

**Error:**

```
API error: Quota exceeded for quota metric
```

**Solution:**

1. Wait for quota to reset (usually daily)
2. Request quota increase in Google Cloud Console
3. Use a paid tier if on free tier

### Model Not Found

**Error:**

```
API error: models/model-name is not found
```

**Solution:**

1. Verify the model name is correct
2. Check if model is available in your region
3. Some models require specific API access

---

## File Issues

### Image File Not Found

**Error:**

```
script-name: path/to/image.png: No such file or directory
```

**Solution:**

1. Check file path is correct
2. Use absolute path if relative path fails
3. Verify file exists: `ls -la path/to/image.png`

### Unsupported Image Format

**Error:** ImageMagick conversion fails or produces garbled output

**Solution:**

1. Use common formats: PNG, JPEG, WebP, GIF
2. Convert manually first:

   ```bash
   magick input.bmp output.png
   ```

3. Check ImageMagick supports the format:

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

---

## Output Issues

### No Response Text from API

**Error:**

```
script-name: no response text received from API
```

**Causes:**

1. Content was blocked by safety filters
2. Request was malformed
3. API returned empty response

**Solution:**

1. Try with a different image
2. Check if image contains sensitive content
3. Verify request format matches expected schema

### Images Are Identical (screenshot-compare)

**Error:**

```
The images are identical.
script-name: error: input images are identical
```

**Exit code:** 2

**This is expected behavior.** The script exits with code 2 when the two images
are byte-identical after encoding.

**If images look different but report as identical:**

1. Check if difference is only in alpha channel (transparency)
2. Verify you're comparing the correct files
3. Check for invisible differences (metadata only)

### No People Found (photo-smart-crop)

**Error:**

```
photo-smart-crop: no people found in image: photo.jpg
```

**Exit code:** 1

**Cause:** The Gemini API did not detect any people in the image.

**Solutions:**

1. Verify the image actually contains people
2. Try with a clearer or higher-resolution image
3. Ensure faces are visible (not obscured or too small)
4. The API may miss people in unusual poses or partial views

### Rate Limited (photo-smart-crop)

**Exit code:** 2

**Cause:** API returned HTTP 429 (rate limit exceeded).

**Solutions:**

1. Wait and retry after a few seconds
2. Implement exponential backoff in calling scripts
3. Check your Gemini API quota

### Invalid Ratio Format (photo-smart-crop)

**Error:**

```
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
2. Process incrementally
3. Combine results

### Missing Input (satisfies)

**Error:**

```
satisfies: missing input from stdin
```

**Cause:** No input was piped to the script.

**Solution:**

```bash
# Correct usage - pipe input
cat file.txt | scripts/satisfies "condition"
echo "text" | scripts/satisfies "condition"

# Incorrect - no input
scripts/satisfies "condition"  # Will fail
```

### Unexpected Boolean Result (satisfies)

**Issue:** `satisfies` returns true/false unexpectedly

**Possible causes:**

1. Condition is ambiguous
2. Input text doesn't clearly match/contradict the condition
3. AI model interpretation differs from expectation

**Solutions:**

1. Make conditions more specific:

   ```bash
   # Vague
   cat file.txt | scripts/satisfies "is good"

   # Specific
   cat file.txt | scripts/satisfies "contains the word 'approved'"
   ```

2. Test with known inputs first
3. Use explicit phrasing like "contains", "mentions", "starts with"

---

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

---

## Network Issues

### Connection Timeout

**Error:** curl timeout or connection refused

**Solution:**

1. Check internet connectivity
2. Verify firewall allows HTTPS to `generativelanguage.googleapis.com`
3. Try with explicit timeout:

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

2. Check system time is correct
3. Verify no proxy is interfering

---

## Large Image Handling

### Request Too Large

**Cause:** Image file size too large for API limits

**Solution:**

1. Resize before processing:

   ```bash
   magick large.png -resize 2048x2048\> resized.png
   ```

2. Increase compression (lossy):

   ```bash
   magick large.png -quality 85 compressed.jpg
   ```

### Processing Timeout

**Cause:** Large images take longer to encode and transmit

**Solution:**

1. Resize images to reasonable dimensions (2048px max recommended)
2. Use JPEG for photos (smaller than PNG)
3. Process in batches if comparing many images

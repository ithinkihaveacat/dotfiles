# Screenshot Compare

Identify **visual differences** between two screenshots using the Gemini API.

Screenshot Compare serves as an intelligent UI QA engineer. It performs a
pixel-by-pixel mental comparison of two images to detect subtle layout shifts,
styling variations, padding changes, and font discrepancies that might indicate
regressions.

## How It Works

1. **Preprocessing:** Uses ImageMagick to flatten images against a magenta
   background. This ensures correct interpretation of transparent areas (common
   in Wear OS or rounded UI elements).
2. **Analysis:** Sends both images to **Gemini 3 Flash**, a multimodal model
   optimized for speed and visual reasoning.
3. **Comparison:** The model executes a structured inspection protocol:
   - Verifies container dimensions and alignment.
   - Checks padding and margins.
   - Inspects font properties (weight, size, style).
   - Looks for "layout shifts" or text rendering changes.
4. **Report:** Outputs a detailed, paragraph-form description of the
   differences, concluding with a concise summary.

## Installation & Usage

There are three ways to use Screenshot Compare:

### 1. System Integration (Recommended)

If you are using the dotfiles environment, simply run the update script. This
will build the tool and install it to `~/.local/bin/screenshot-compare`.

```bash
./update
```

### 2. Standalone Installation

If you only want to install this specific tool globally on your system:

```bash
npm install -g .
```

### 3. Local Execution

To run the tool directly from the source directory without installing it:

```bash
npm install
npm run build
node dist/index.js --help
```

## Usage

```text
screenshot-compare [OPTIONS] IMAGE1 IMAGE2 [PROMPT]
```

### Arguments

| Argument | Description                                            |
| -------- | ------------------------------------------------------ |
| `IMAGE1` | Path to the first screenshot (baseline/before).        |
| `IMAGE2` | Path to the second screenshot (comparison/after).      |
| `PROMPT` | Optional. Custom instruction for specific focus areas. |

### Options

| Option          | Description                      |
| --------------- | -------------------------------- |
| `-h, --help`    | Display help message and exit.   |
| `-v, --version` | Display version number and exit. |

### Environment Variables

| Variable         | Description                    |
| ---------------- | ------------------------------ |
| `GEMINI_API_KEY` | Required. Your Gemini API key. |

### Dependencies

- **ImageMagick**: Must be installed and available in your PATH as `magick`.

## Examples

Basic comparison:

```bash
screenshot-compare before.png after.png
```

Focus on specific elements:

```bash
screenshot-compare v1.png v2.png \
  "Check strictly for font weight changes in the header."
```

## Output

The tool outputs a text description to stdout:

- **Detailed Analysis:** A paragraph describing specific visual deltas (e.g.,
  "The primary button has shifted 4px to the right...").
- **Summary:** A concluding sentence summarizing the overall impact.
- **Identical Images:** If images are binary identical, the tool exits with code
  2 and prints "The images are identical."

## Exit Codes

- `0`: Success (differences found and described).
- `1`: General error (missing files, API failure, missing ImageMagick).
- `2`: Images are identical (no AI analysis performed).

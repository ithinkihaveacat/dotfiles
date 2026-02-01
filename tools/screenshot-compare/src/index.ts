#!/usr/bin/env node

import { GoogleGenAI } from "@google/genai/node";
import { execFileSync, execSync } from "child_process";
import { access } from "fs/promises";
import { constants } from "fs";

// Version check - Node.js 24+ required
const REQUIRED_NODE_MAJOR = 24;
{
  const major = Number(process.versions.node.split(".")[0]);
  if (major < REQUIRED_NODE_MAJOR) {
    console.error(
      `screenshot-compare: requires Node.js ${REQUIRED_NODE_MAJOR}+ (found ${process.version})`
    );
    process.exit(1);
  }
}

const SCRIPT_NAME = "screenshot-compare";
const MODEL = "gemini-3-flash-preview";

const DEFAULT_PROMPT = `You are a meticulous UI QA engineer. Compare these two screenshots with extreme precision. They are expected to show the same UI, but one contains subtle layout, size, or styling variations that may be bugs.

Perform a pixel-by-pixel mental comparison. Carefully examine:
1. The exact width and height of all containers and shapes.
2. The internal padding between text/icons and their containers.
3. The external margins between elements and the screen edges.
4. The precise alignment and centering of all components.
5. Font properties including size, weight, style (italic/bold), and color.

Specifically, look for any stretching, shrinking, or shifting of UI elements, or changes in text rendering. Even a few pixels of difference or a slight font weight change is critical to report.

If the images are completely different (e.g., they show different apps or entirely different screens), provide a single, concise explanation of why they are not comparable as your entire response.

Otherwise, provide a detailed description of the visual differences in paragraph form. Do not use bullet points or lists. Be specific about changes to container dimensions, colors, font sizes, margins, padding, and layout shifts, noting direction and approximate pixel values where possible.

Conclude with a brief summary paragraph of the overall changes (e.g., 'the height of the primary container has been reduced' or 'vertical padding has been increased throughout').

Your entire response must be in paragraph form and must not utilize bullet points.`;

function usage(): void {
  console.log(`Usage: ${SCRIPT_NAME} IMAGE1 IMAGE2 [PROMPT]

Compare two screenshots using the Gemini API. Identifies visual differences like
layout shifts, color changes, padding, or text updates.

Arguments:
  IMAGE1      Path to the first screenshot (baseline/before)
  IMAGE2      Path to the second screenshot (comparison/after)
  PROMPT      Custom prompt for the AI model (optional)

Options:
  -h, --help  Display this help message and exit

Environment:
  GEMINI_API_KEY  Required. Your Gemini API key.

Examples:
  ${SCRIPT_NAME} before.png after.png
  ${SCRIPT_NAME} v1.png v2.png "Check for font size changes in the header"

Exit Codes:
  0    Success (differences found and described)
  1    General error (API error, usage, missing file, etc.)
  2    Images are identical (no differences to describe)`);
  process.exit(0);
}

function error(message: string, code: number = 1): never {
  console.error(`${SCRIPT_NAME}: ${message}`);
  process.exit(code);
}

async function fileExists(path: string): Promise<boolean> {
  try {
    await access(path, constants.R_OK);
    return true;
  } catch {
    return false;
  }
}

/**
 * Check if a command exists in PATH.
 */
function commandExists(cmd: string): boolean {
  try {
    execSync(`command -v ${cmd}`, { stdio: "ignore" });
    return true;
  } catch {
    return false;
  }
}

/**
 * Process an image using ImageMagick: flatten against magenta background and
 * convert to lossless webp. Returns base64-encoded data.
 *
 * The magenta background ensures the AI perceives circular UI shapes correctly
 * (transparent corners on circular Wear OS screenshots would otherwise blend
 * with whatever background the AI assumes).
 */
function processImage(path: string): string {
  // ImageMagick outputs binary webp to stdout, which we capture as a Buffer
  // Using execFileSync avoids shell parsing and handles special characters in paths
  const webpBuffer = execFileSync(
    "magick",
    [path, "-background", "magenta", "-flatten", "-define", "webp:lossless=true", "webp:-"],
    { maxBuffer: 50 * 1024 * 1024 }, // 50MB buffer for large images
  );
  return webpBuffer.toString("base64");
}

async function main(): Promise<void> {
  const args = process.argv.slice(2);

  // Handle help
  if (args.includes("-h") || args.includes("--help")) {
    usage();
  }

  // Validate arguments
  if (args.length < 2) {
    usage();
  }

  // Check for required commands
  if (!commandExists("magick")) {
    error("magick not found (install ImageMagick)");
  }

  const image1Path = args[0];
  const image2Path = args[1];
  const prompt = args[2] || DEFAULT_PROMPT;

  // Check files exist
  if (!(await fileExists(image1Path))) {
    error(`${image1Path}: No such file or directory`);
  }
  if (!(await fileExists(image2Path))) {
    error(`${image2Path}: No such file or directory`);
  }

  // Check for API key
  if (!process.env.GEMINI_API_KEY) {
    error("GEMINI_API_KEY environment variable not set");
  }

  // Process images (synchronous since we're using execSync)
  const img1Base64 = processImage(image1Path);
  const img2Base64 = processImage(image2Path);

  // Check if images are identical
  if (img1Base64 === img2Base64) {
    console.log("The images are identical.");
    console.error(`${SCRIPT_NAME}: error: input images are identical`);
    process.exit(2);
  }

  // Initialize AI client (auto-picks up GEMINI_API_KEY)
  const ai = new GoogleGenAI({});

  // Call the API with text before images (recommended for comparison tasks)
  const response = await ai.models.generateContent({
    model: MODEL,
    contents: [
      {
        role: "user",
        parts: [
          { text: prompt },
          { inlineData: { mimeType: "image/webp", data: img1Base64 } },
          { inlineData: { mimeType: "image/webp", data: img2Base64 } },
        ],
      },
    ],
  });

  // Extract text response
  const text = response.text;
  if (!text) {
    error("no response text received from API");
  }

  console.log(text);
}

main().catch((err) => {
  // Handle API errors specifically
  if (err && typeof err === "object" && "status" in err) {
    error(`API error: ${err.message || "Unknown error"}`);
  }
  error(err instanceof Error ? err.message : String(err));
});

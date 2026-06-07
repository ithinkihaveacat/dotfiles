#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "llm",
#     "llm-gemini",
#     "pillow",
# ]
# ///
"""Ask an LLM a yes/no visual question over every JPG in a directory."""

import argparse
import glob
import hashlib
import json
import os
import sys
import tempfile
from io import BytesIO

import llm
from PIL import Image


def resize_image(filename, max_size=512):
    """Resize a JPG to fit inside max_size x max_size, memoised on disk."""
    cache_key = hashlib.md5(f"{filename}:{max_size}".encode()).hexdigest()
    cache_dir = os.path.join(tempfile.gettempdir(), "resize_cache")
    cache_path = os.path.join(cache_dir, f"{cache_key}.jpg")

    os.makedirs(cache_dir, exist_ok=True)

    if os.path.exists(cache_path):
        with open(cache_path, "rb") as f:
            return f.read()

    with Image.open(filename) as img:
        img.thumbnail((max_size, max_size))
        img.save(cache_path, format="JPEG")
        buffer = BytesIO()
        img.save(buffer, format="JPEG")
        return buffer.getvalue()


def main():
    parser = argparse.ArgumentParser(description=__doc__, add_help=False)
    parser.add_argument("--help", action="help", help="Show this help message and exit")
    parser.add_argument("directory", help="Directory to walk recursively for *.jpg")
    parser.add_argument(
        "--prompt", required=True, help="Prompt text sent with each image"
    )
    parser.add_argument(
        "--schema",
        required=True,
        help="llm.schema_dsl spec, e.g. 'has_bedside_table bool'",
    )
    parser.add_argument(
        "--filter",
        dest="filter_field",
        help="Print only filenames where this boolean field is true",
    )
    parser.add_argument("--model", default="gemini/gemini-2.5-flash-lite")
    parser.add_argument("--max-size", type=int, default=512)
    args = parser.parse_args()

    model = llm.get_model(args.model)
    schema = llm.schema_dsl(args.schema)

    pattern = os.path.join(args.directory, "**/*.jpg")
    for input_filename in glob.glob(pattern, recursive=True):
        response = model.prompt(
            args.prompt,
            schema=schema,
            attachments=[
                llm.Attachment(content=resize_image(input_filename, args.max_size))
            ],
        )

        try:
            parsed = json.loads(response.text())
        except json.JSONDecodeError:
            print(f"Could not parse JSON for {input_filename}", file=sys.stderr)
            continue

        parsed["filename"] = input_filename

        if args.filter_field:
            if parsed.get(args.filter_field):
                print(input_filename)
        else:
            print(parsed)


if __name__ == "__main__":
    main()

#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "google-genai",
#     "pyyaml",
# ]
# [tool.uv.sources]
# google-genai = { index = "pypi" }
# [[tool.uv.index]]
# name = "pypi"
# url = "https://pypi.org/simple"
# ///
"""Skill Search: Discover relevant agent skills using Gemini."""

import argparse
import os
import subprocess
import sys
from pathlib import Path
from google import genai
from google.genai import types
import yaml


def load_skill_md(path: Path) -> dict | None:
    """Reads SKILL.md and extracts frontmatter and content."""
    skill_md = path / "SKILL.md"
    if not skill_md.is_file():
        return None
    try:
        content = skill_md.read_text(encoding="utf-8", errors="replace")
        # Parse YAML frontmatter
        if content.startswith("---"):
            parts = content.split("---", 2)
            if len(parts) >= 3:
                frontmatter = yaml.safe_load(parts[1])
                body = parts[2].strip()
                return {
                    "name": frontmatter.get("name", path.name),
                    "description": frontmatter.get("description", ""),
                    "path": str(path),
                    "content": body,
                }
        return {
            "name": path.name,
            "description": "",
            "path": str(path),
            "content": content,
        }
    except Exception as e:
        print(f"Warning: failed to read skill at {path}: {e}", file=sys.stderr)
        return None


def gather_skills(search_dirs: list[Path]) -> list[dict]:
    """Finds all skills in the given directories. Does NOT deduplicate to allow comparing duplicates."""
    skills = []
    for d in search_dirs:
        expanded_d = Path(os.path.expanduser(str(d))).resolve()
        if not expanded_d.is_dir():
            continue
        # Search for SKILL.md in subdirectories
        for item in expanded_d.iterdir():
            if item.is_dir() and not item.name.startswith("."):
                skill_data = load_skill_md(item)
                if skill_data:
                    skills.append(skill_data)
    return skills


def gather_repo_context() -> str:
    """Gathers files and .gitignore contents for fallback query context."""
    context = ""
    # 1. Try to get git files
    try:
        res = subprocess.run(
            ["git", "ls-files"], capture_output=True, text=True, check=True
        )
        files = res.stdout.splitlines()
        context += "Tracked Files (first 50):\n" + "\n".join(files[:50]) + "\n"
    except Exception:
        # Fallback to local files
        try:
            items = [
                str(p.relative_to(Path.cwd()))
                for p in Path.cwd().iterdir()
                if not p.name.startswith(".")
            ]
            context += "Files in current directory:\n" + "\n".join(items[:30]) + "\n"
        except Exception as e:
            context += f"Could not list directory: {e}\n"

    # 2. Try to get .gitignore
    gitignore = Path(".gitignore")
    if gitignore.is_file():
        try:
            content = gitignore.read_text(encoding="utf-8", errors="replace")
            # Clip to 1KB
            if len(content) > 1024:
                content = content[:1024] + "\n... [TRUNCATED]"
            context += f"\n.gitignore content:\n{content}\n"
        except Exception:
            pass

    return context


def main():
    parser = argparse.ArgumentParser(description="Search agent skills.")
    parser.add_argument("query", nargs="?", help="Problem description or goal.")
    parser.add_argument(
        "--search-dirs",
        help="Colon-separated search directories (overrides environment).",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show gathered skills and prompt without calling API.",
    )
    args = parser.parse_args()

    # Resolve search directories
    search_paths = []
    if args.search_dirs:
        search_paths.extend([Path(p) for p in args.search_dirs.split(":")])
    else:
        env_dirs = os.environ.get("SKILL_SOURCE_DIRS")
        if env_dirs:
            search_paths.extend([Path(p) for p in env_dirs.split(":")])

    # Also check local _agents/skills
    search_paths.append(Path("_agents/skills"))
    search_paths.append(Path(".agents/skills"))

    if not search_paths:
        print(
            "Error: No search paths configured. Please set SKILL_SOURCE_DIRS environment variable or use --search-dirs.",
            file=sys.stderr,
        )
        sys.exit(1)

    skills = gather_skills(search_paths)

    if not skills:
        print("No skills found in search paths.", file=sys.stderr)
        sys.exit(0)

    # If no query, we suggest defaults based on repo context
    query = args.query
    if not query:
        repo_ctx = gather_repo_context()
        query = (
            "Bootstrap this repository with sensible default skills. Here is the repository context:\n"
            + repo_ctx
        )

    # System instruction for selection
    system_instruction = """You are an expert developer assistant. Your task is to select the most relevant AI agent skills from a list of available skills to help solve a user's problem or goal.

You must return a JSON list of objects, where each object represents a selected skill and contains:
- "name": The name of the skill.
- "path": The path to the skill.
- "reason": A brief explanation of why this skill is relevant.

### Selection Rules:
1. **Hierarchy of Preferences**: 
   - Personal skills (custom workflows, personal style guides, etc.) are highly preferred and should almost always be suggested if they are even marginally relevant.
   - General tools (e.g., 'agent-tools') are next.
   - Specific workspace tools (e.g., 'adb', 'emumanager') should only be suggested if the context implies their use (e.g., Android, emulator).
2. **Relevance**: Only suggest skills that actually help with the described problem. Do not suggest unrelated skills.
3. **Duplicates**: If multiple skills with the same name exist at different paths, you may suggest multiple of them if their content differs and both are relevant.
4. **Defaults**: If the user is asking to bootstrap or has no specific query, suggest a set of sensible defaults based on the project structure (like general coding tools for coding repos).
5. **Format**: Your output must conform strictly to the specified JSON schema.

Example Output:
[
  {"name": "coding-standards", "path": "/path/to/personal/coding-standards", "reason": "User needs to format code and check style."},
  {"name": "agent-tools", "path": "/path/to/agent-tools", "reason": "Provides general utility scripts."}
]
"""

    # Format skills for context
    skills_context = ""
    for s in skills:
        skills_context += f"=== Skill: {s['name']} ===\n"
        skills_context += f"Path: {s['path']}\n"
        skills_context += f"Description: {s['description']}\n"
        skills_context += f"Content:\n{s['content']}\n\n"

    user_prompt = f"User Problem/Goal: {query}\n\nAvailable Skills:\n{skills_context}"

    if args.dry_run:
        print("=== DRY RUN ===", file=sys.stderr)
        print(f"Query: {query}", file=sys.stderr)
        print(f"Found {len(skills)} skills.", file=sys.stderr)
        for s in skills:
            print(f"  - {s['name']} ({s['path']})", file=sys.stderr)
        print("\nPrompt that would be sent to Gemini:", file=sys.stderr)
        print(user_prompt[:500] + "...\n[TRUNCATED]", file=sys.stderr)
        sys.exit(0)

    # Call Gemini API
    api_key = os.environ.get("GEMINI_CLI_GEMINI_API_KEY") or os.environ.get(
        "GEMINI_API_KEY"
    )
    if not api_key:
        print("Error: GEMINI_API_KEY environment variable not set.", file=sys.stderr)
        sys.exit(1)

    client = genai.Client(api_key=api_key)
    model_id = "gemini-3.5-flash"

    # Define strict schema for output to guarantee structure
    skill_schema = types.Schema(
        type=types.Type.ARRAY,
        items=types.Schema(
            type=types.Type.OBJECT,
            properties={
                "name": types.Schema(type=types.Type.STRING),
                "path": types.Schema(type=types.Type.STRING),
                "reason": types.Schema(type=types.Type.STRING),
            },
            required=["name", "path", "reason"],
        ),
    )

    try:
        response = client.models.generate_content(
            model=model_id,
            contents=user_prompt,
            config=types.GenerateContentConfig(
                system_instruction=system_instruction,
                temperature=0.0,
                response_mime_type="application/json",
                response_schema=skill_schema,
            ),
        )

        result_json = response.text.strip()
        # Print JSON output to stdout
        print(result_json)

    except Exception as e:
        print(f"Error calling Gemini API: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()

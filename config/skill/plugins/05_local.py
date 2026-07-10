import os
import sys
from pathlib import Path


def register(api):
    # Allow environment variable override for automated tests and custom workspaces,
    # but fall back to the canonical local skill directories by default.
    if "SKILL_SOURCE_DIRS" in os.environ:
        source_dirs = [
            Path(p).expanduser()
            for p in os.environ["SKILL_SOURCE_DIRS"].split(":")
            if p
        ]
    else:
        source_dirs = [
            Path("~/.dotfiles/skills").expanduser(),
            Path("~/.private/skills").expanduser(),
            Path("~/.corp/skills").expanduser(),
            Path("~/.agents/skills").expanduser(),
            Path("~/.gemini/config/skills").expanduser(),
            Path("~/.gemini/jetski/skills").expanduser(),
        ]

    seen_realpaths = set()
    for d in source_dirs:
        if not d.is_dir():
            continue
        try:
            for item in d.iterdir():
                if item.name.startswith(".") or not item.is_dir():
                    continue
                if (item / "SKILL.md").is_file():
                    realpath = str(os.path.realpath(item))
                    if realpath in seen_realpaths:
                        continue
                    seen_realpaths.add(realpath)
                    # Register under the 'local' namespace
                    api.register_skill(
                        f"local:{item.name}",
                        {"path": realpath, "resolve": True},
                    )
        except Exception as e:
            print(
                f"local skills plugin: warning: failed to scan {d}: {e}",
                file=sys.stderr,
            )

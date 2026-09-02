import os
import sys
from pathlib import Path


def register(api):
    # Allow environment variable override for automated tests and custom workspaces,
    # but fall back to ~/.android/cli/skills by default.
    if "ANDROID_CLI_SKILLS_DIR" in os.environ:
        skills_dir = Path(os.environ["ANDROID_CLI_SKILLS_DIR"]).expanduser()
    else:
        skills_dir = Path("~/.android/cli/skills").expanduser()

    if not skills_dir.is_dir():
        return

    seen_names = set()
    seen_realpaths = set()
    try:
        for root, dirs, files in os.walk(skills_dir, followlinks=True):
            dirs[:] = sorted([d for d in dirs if not d.startswith(".")])
            if "SKILL.md" in files:
                skill_dir = Path(root)
                realpath = str(skill_dir.resolve())
                if realpath in seen_realpaths:
                    dirs.clear()
                    continue
                seen_realpaths.add(realpath)

                rel_parts = skill_dir.relative_to(skills_dir).parts
                if not rel_parts:
                    dirs.clear()
                    continue
                skill_name = "-".join(rel_parts)
                if skill_name in seen_names:
                    dirs.clear()
                    continue
                seen_names.add(skill_name)
                api.register_skill(
                    f"android:{skill_name}",
                    {"path": realpath, "resolve": True},
                )
                dirs.clear()
    except Exception as e:
        print(
            f"android skills plugin: warning: failed to scan {skills_dir}: {e}",
            file=sys.stderr,
        )

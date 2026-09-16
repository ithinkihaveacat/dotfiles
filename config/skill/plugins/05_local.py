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
        ]

    seen = set()
    for d in source_dirs:
        if not d.is_dir():
            continue
        try:
            # Scan real directories first so canonical skills take precedence over alias symlinks
            for item in sorted(d.iterdir(), key=lambda p: (p.is_symlink(), p.name)):
                if item.name.startswith(".") or not item.is_dir():
                    continue
                if (item / "SKILL.md").is_file():
                    # COMPAT: When can this code be removed?
                    # Keying on (item.name, realpath) allows the 'skills/workspace-config'
                    # compatibility symlink to register alongside 'workspace-tools' without
                    # colliding, while still deduplicating identical skills across overlay
                    # directories (e.g. ~/.agents/skills -> ~/.dotfiles/skills).
                    # This can be reverted to seen_realpaths once all workspaces migrate
                    # and the 'skills/workspace-config' compatibility symlink is deleted.
                    realpath = str(os.path.realpath(item))
                    key = (item.name, realpath)
                    if key in seen:
                        continue
                    seen.add(key)
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

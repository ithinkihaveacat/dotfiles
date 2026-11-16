#!/bin/sh
# Default skills, linked into the user scope (~/.claude/skills, ~/.agents/skills,
# ~/.gemini/config/skills) so every agent sees them without per-workspace seeding.
# install.sh runs this file, then the overlays' own etc/skill/defaults.sh.
#
# To stop shipping a default, change its 'add' to 'skill --scope user remove
# --quiet <name>' (rather than deleting the name), so machines that already
# have it drop it on their next install.sh run.
set -e

skill --scope user add --quiet \
  agent-tools \
  coding-standards \
  workspace-tools \
  agent-config \
  technical-writing \
  taskgo

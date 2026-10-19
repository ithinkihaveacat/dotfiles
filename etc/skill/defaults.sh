#!/bin/sh
# Default skills, linked into each repo by its clone hook and into each wrapped
# agent session at launch ('skill add --defaults'). install.sh runs this file,
# then the overlays' own etc/skill/defaults.sh.
#
# To stop shipping a default, change its 'add' to a 'remove' (rather than
# deleting the name), so machines that already have it drop it; its links then
# break everywhere and the next 'skill add --defaults' clears them.
set -e

skill --scope defaults add --quiet \
  agent-tools \
  coding-standards \
  workspace-tools \
  agent-config \
  technical-writing \
  taskgo

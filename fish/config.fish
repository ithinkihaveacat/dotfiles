# -*- sh -*-

set -x GITROOT "git@github.com:ithinkihaveacat"
set -x GIT_COMPOSER_STALE "warn"
set -x GREP_OPTIONS "--exclude-dir=.svn --exclude-dir=.git --binary-files=without-match"
set -x LESS "-XMcifR"
set -x TZ "Europe/London"

set -g CDPATH . ~ ~/workspace

# Remove greeting
set fish_greeting

# Configure git prompt
# https://github.com/fish-shell/fish-shell/blob/master/share/functions/__fish_git_prompt.fish
set -g __fish_git_prompt_showupstream "auto"
set -g __fish_git_prompt_showstashstate "1"
set -g __fish_git_prompt_showdirtystate "1"

. $HOME/.config/fish/solarized.fish
. $HOME/.config/fish/rubies.fish

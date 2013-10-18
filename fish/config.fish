# -*- sh -*-

# tool config

set -x GREP_OPTIONS "--exclude-dir=.svn --exclude-dir=.git --binary-files=without-match"
set -x LESS "-XMcifR"
set -x TZ "Europe/London"

# personal config

set -x GITROOT "git@github.com:ithinkihaveacat"
set -x GIT_COMPOSER_STALE "warn"

# fish config

mkdir -p ~/workspace
set -g CDPATH . ~ ~/workspace

# http://fishshell.com/docs/2.0/#variables-special
set fish_user_paths $HOME/.config/fish/../bin

# http://fishshell.com/docs/2.0/#variables-special
set fish_greeting

# https://github.com/fish-shell/fish-shell/blob/master/share/functions/__fish_git_prompt.fish
set -g __fish_git_prompt_showupstream "auto"
set -g __fish_git_prompt_showstashstate "1"
set -g __fish_git_prompt_showdirtystate "1"

. $HOME/.config/fish/solarized.fish
. $HOME/.config/fish/rubies.fish

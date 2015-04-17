# -*- sh -*-

# tool config

set -x GREP_OPTIONS "--exclude-dir=.svn --exclude-dir=.git --binary-files=without-match"
set -x LESS "-XMcifR"
set -x TZ "Europe/London"

# personal config

set -x GITROOT "git@github.com:ithinkihaveacat"
set -x GITONBORGROOT "sso://user/stillers"

set -x ANDROID_HOME "$HOME/workspace/sdk"
if begin ; test -x /usr/libexec/java_home ; and /usr/libexec/java_home -v 1.7 >/dev/null ; end
  set -x JAVA_HOME (/usr/libexec/java_home -v 1.7)
end

if type atom >/dev/null
  set -x EDITOR "atom --new-window --wait"
  set -x VISUAL "atom --new-window --wait"
end

set -x GIT_EDITOR "vim"

# fish config

set -g CDPATH . ~
if test -d ~/workspace
  set -g CDPATH $CDPATH ~/workspace
end
if test -d ~/citc
  set -g CDPATH $CDPATH ~/citc
end

# http://fishshell.com/docs/2.1/#variables-special
set fish_user_paths /usr/local/sbin /usr/local/bin ~/.dotfiles/fish/../bin

if test -d ~/local/homebrew/bin
  set fish_user_paths ~/local/homebrew/bin $fish_user_paths
end

if test -d ~/local/homebrew/sbin
  set fish_user_paths ~/local/homebrew/sbin $fish_user_paths
end

if test -d ~/local/google-cloud-sdk/bin
  set fish_user_paths $fish_user_paths ~/local/google-cloud-sdk/bin
end

if test -d ~/local/bin
  set fish_user_paths $fish_user_paths ~/local/bin
end

# gem install $name --user-install
if test -d ~/.gem/ruby/*/bin
  set fish_user_paths $fish_user_paths ~/.gem/ruby/*/bin
end

# http://fishshell.com/docs/2.1/#variables-special
set --erase fish_greeting

# https://github.com/fish-shell/fish-shell/blob/master/share/functions/__fish_git_prompt.fish
set -g __fish_git_prompt_showupstream "auto"
set -g __fish_git_prompt_showstashstate "1"
set -g __fish_git_prompt_showdirtystate "1"

. $HOME/.config/fish/solarized.fish

# mkdir -p ~/.rubies
# . $HOME/.config/fish/rubies.fish

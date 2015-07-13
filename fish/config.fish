# -*- sh -*-

# tool config

set -x GREP_OPTIONS "--exclude-dir=.svn --exclude-dir=.git --binary-files=without-match"
set -x LESS "-XMcifR"
set -x TZ "Europe/London"

# personal config

set -x GITROOT "git@github.com:ithinkihaveacat"

set -x ANDROID_HOME "$HOME/workspace/sdk"

# fish config

set -g CDPATH . ~
if test -d ~/workspace
  set -g CDPATH $CDPATH ~/workspace
end
if test -d ~/citc
  set -g CDPATH $CDPATH ~/citc
end

# http://fishshell.com/docs/2.1/#variables-special

if test -d /usr/local/sbin
  set fish_user_paths /usr/local/sbin $fish_user_paths
end

if test -d /usr/local/bin
  set fish_user_paths /usr/local/bin $fish_user_paths
end

if test -d ~/.dotfiles/fish/../bin
  set fish_user_paths ~/.dotfiles/fish/../bin $fish_user_paths
end

if test -d ~/local/homebrew/bin
  set fish_user_paths ~/local/homebrew/bin $fish_user_paths
end

if test -d ~/local/homebrew/sbin
  set fish_user_paths ~/local/homebrew/sbin $fish_user_paths
end

if test -d ~/local/google-cloud-sdk/bin
  set fish_user_paths $fish_user_paths ~/local/google-cloud-sdk/bin
end

if test -d $ANDROID_HOME/platform-tools
  set fish_user_paths $fish_user_paths $ANDROID_HOME/platform-tools
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

# mkdir -p ~/.rubies
# . $HOME/.config/fish/rubies.fish

# https://github.com/zimbatm/direnv
if type direnv >/dev/null
  eval (direnv hook fish)
end

if type jed >/dev/null
  set -x EDITOR "jed"
end

if type go >/dev/null
  set -x GOPATH ~/local/go
  mkdir -p $GOPATH
  if test -d $GOPATH/bin
    set fish_user_paths $fish_user_paths $GOPATH/bin
  end
end

source $HOME/.config/fish/solarized.fish

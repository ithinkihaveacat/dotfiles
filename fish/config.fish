# -*- sh -*-

# tool config

set -x LESS "-XMcifR"
set -x TZ "Europe/London"

# personal config

set -x GITROOT "https://github.com//ithinkihaveacat"

# fish config

set -g CDPATH . ~
if test -d ~/workspace
  set -g CDPATH $CDPATH ~/workspace
end
if test -d ~/citc
  set -g CDPATH $CDPATH ~/citc
end

function append_if_exists
  if count $argv > /dev/null ; and count $argv[1] > /dev/null ; and test -d $argv[1]
    # http://fishshell.com/docs/2.1/#variables-special
    set -g fish_user_paths $fish_user_paths $argv[1]
  end
end

append_if_exists (realpath "$HOME/.dotfiles/fish/../bin")
append_if_exists "$HOME/.yarn-cache/.global/node_modules/.bin"
append_if_exists "$HOME/local/homebrew/bin"
append_if_exists "$HOME/local/homebrew/sbin"
append_if_exists "$HOME/local/bin"
append_if_exists "$HOME/local/google-cloud-sdk/bin"
append_if_exists "$HOME/local/google-cloud-sdk/platform/google_appengine"

# java
#
# 1. Choose JRE from
#    http://www.oracle.com/technetwork/java/javase/downloads/index.html
# 2. Download the *.tar.gz.
# 3. Extract to ~/local.
set d ~/local/jre*/Contents/Home/bin
append_if_exists $d

# ghc
#
# Install via:
#
#   $ brew cask install ghc
#
# Then:
#
#   $ cabal update
#   $ cabal install pandoc
set d /Applications/ghc-*.app/Contents/bin
append_if_exists $d
append_if_exists ~/.cabal/bin

# Android
if test -d ~/Library/Android/sdk
  set -x ANDROID_HOME ~/Library/Android/sdk
  set fish_user_paths $fish_user_paths $ANDROID_HOME/platform-tools
end

# Ruby
#
# Install gems via:
#
#   $ gem install $name --user-install
set d ~/.gem/ruby/*/bin
append_if_exists $d

# golang
#
# Ubuntu (package is golang-*-go)
set d /usr/lib/go-*/bin
append_if_exists $d

# OS X
if type -q go
  set -x GOPATH ~/local/go
  mkdir -p $GOPATH
  append_if_exists $GOPATH/bin
end

append_if_exists /usr/local/sbin
append_if_exists /usr/local/bin

# http://fishshell.com/docs/2.1/#variables-special
set --erase fish_greeting

# https://github.com/fish-shell/fish-shell/blob/master/share/functions/__fish_git_prompt.fish
set -g __fish_git_prompt_showupstream "auto"
set -g __fish_git_prompt_showstashstate "1"
set -g __fish_git_prompt_showdirtystate "1"

# mkdir -p ~/.rubies
# . $HOME/.config/fish/rubies.fish

# https://github.com/zimbatm/direnv
if type -q direnv
  eval (direnv hook fish)
end

if type -q jed
  set -x EDITOR "jed"
end

if type -q atom
  set -x VISUAL "jed" # or "atom -w"
end

alias yarn="yarn --no-emoji"

source ~/.config/fish/solarized.fish

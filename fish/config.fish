# -*- sh -*-

# tool config

set -x LESS "-XMcifR"
set -x TZ "Europe/London"

# personal config

set -x GITROOT "https://github.com/ithinkihaveacat"

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

function sourceif
  if test -r $argv[1]
    source $argv[1]
  end
end

append_if_exists (realpath "$HOME/.dotfiles/fish/../bin")
append_if_exists "$HOME/.yarn-cache/.global/node_modules/.bin"
append_if_exists "$HOME/local/homebrew/bin"
append_if_exists "$HOME/local/homebrew/sbin"
append_if_exists "$HOME/local/bin"
append_if_exists "$HOME/local/google-cloud-sdk/bin"
append_if_exists "$HOME/local/google-cloud-sdk/platform/google_appengine"
append_if_exists "$HOME/local/google-cloud-sdk/platform/google_appengine/goroot/bin"
# https://cloud.google.com/appengine/docs/go/download
append_if_exists "$HOME/local/go_appengine"

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

# Android Tools
if test -d ~/Library/Android/sdk
  set -x ANDROID_HOME ~/Library/Android/sdk
end
if test -d ~/Android/Sdk
  set -x ANDROID_HOME ~/Android/Sdk
  append_if_exists $ANDROID_HOME/platform-tools
  append_if_exists $ANDROID_HOME/tools
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

# Node
#
# NODE_VERSIONS is used by direnv and nodejs-install to make different
# versions of node available; see ~/.direnvrc

set -x NODE_VERSIONS $HOME/.local/share/node/versions
mkdir -p $NODE_VERSIONS

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
  # If MANPATH is set, man very helpfully ignores the default search path as defined in
  # /etc/manpath.config (at least on Linux). Therefore, to ensure man searches through
  # the default after direnv fiddles with MANPATH, we explicitly set it to its default value.
  # See http://unix.stackexchange.com/q/344603/49703
  set -x MANPATH (man -w)
end

if type -q jed
  set -x EDITOR "jed"
end

if type -q atom
  set -x VISUAL "jed" # or "atom -w"
end

type -q pbcopy  ; or alias pbcopy  "xsel -bi"
type -q pbpaste ; or alias pbpaste "xsel -bo"

source ~/.config/fish/solarized.fish
source ~/.config/fish/ua.fish

sourceif ~/.ssh/etc/fish/envrc

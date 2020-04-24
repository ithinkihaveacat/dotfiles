# -*- sh -*-

# tool config

set -x LESS "-XMcifR"
set -x TZ "Europe/London"

# personal config

set -x GITROOT "git@github.com:ithinkihaveacat"

# fish config

set -g CDPATH . ~
if test -d ~/workspace
  set -g CDPATH $CDPATH ~/workspace
end
if test -d ~/citc
  set -g CDPATH $CDPATH ~/citc
end

# Avoid fish_user_path and instead set PATH directly. fish_user_path can be used
# to share a PATH across shells and invocations if set as a universal variable;
# it isn't very useful otherwise. See
# https://github.com/fish-shell/fish-shell/issues/527#issuecomment-253775156
function append_path
  if begin ; count $argv > /dev/null ; and count $argv[1] > /dev/null ; and test -d $argv[1] ; end
    if not contains $argv[1] $PATH
      set PATH $PATH $argv[1]
    end
  end
end

function prepend_path
  if begin ; count $argv > /dev/null ; and count $argv[1] > /dev/null ; and test -d $argv[1] ; end
    if not contains $argv[1] $PATH
      set PATH $argv[1] $PATH
    end
  end
end

function sourceif
  if test -r $argv[1]
    source $argv[1]
  end
end

# binaries

prepend_path /usr/local/sbin
prepend_path /usr/local/bin

prepend_path "$HOME/local/homebrew/bin"
prepend_path "$HOME/local/homebrew/sbin"

prepend_path "$HOME/local-linux/bin" # $PLATFORM is not readily available, so hardcode
prepend_path "$HOME/local/bin"

# Google Cloud SDK
#
# https://cloud.google.com/sdk/

prepend_path "$HOME/local/google-cloud-sdk/platform/google_appengine/goroot/bin"
prepend_path "$HOME/local/google-cloud-sdk/platform/google_appengine"
prepend_path "$HOME/local/google-cloud-sdk/bin"

# java
#
# 1. Choose a "JRE Download" from
#    https://www.oracle.com/java/technologies/javase-downloads.html
# 2. Download an appropriate *.tar.gz.
# 3. Extract to ~/local.

set d ~/local/jre*/Contents/Home/bin
prepend_path $d

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
prepend_path $d
prepend_path ~/.cabal/bin

# Android Tools

test -d ~/Library/Android/sdk ; and set -x ANDROID_HOME ~/Library/Android/sdk
test -d ~/Android/Sdk         ; and set -x ANDROID_HOME ~/Android/Sdk

prepend_path $ANDROID_HOME/platform-tools
prepend_path $ANDROID_HOME/tools
prepend_path $ANDROID_HOME/tools/bin

# Ruby
#
# Install gems via:
#
#   $ gem install $name --user-install

set -x GEM_HOME ~/.gem

set d ~/.gem/ruby/*/bin
prepend_path $d

# Node
#
# NODE_VERSIONS is used by direnv and nodejs-install to make different
# versions of node available; see ~/.direnvrc

set -x NODE_VERSIONS $HOME/.local/share/node/versions
mkdir -p $NODE_VERSIONS

if count $NODE_VERSIONS/node-v10*/bin >/dev/null
  prepend_path (ls -d $NODE_VERSIONS/node-v12*/bin | sort -V | tail -1)
end

# golang

# Special-case PATH for Ubuntu (package is golang-*-go)
set d /usr/lib/go-*/bin
prepend_path $d

if type -q go
  set -x GOPATH ~/local/go
  mkdir -p $GOPATH
  prepend_path $GOPATH/bin
end

# flutter

prepend_path ~/local/flutter/bin

# other scripts

prepend_path (realpath "$HOME/.dotfiles/fish/../bin")
prepend_path "$HOME/.dotfiles/npm/node_modules/.bin"

# http://fishshell.com/docs/current/faq.html#faq-greeting
set fish_greeting

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

set -x VISUAL $EDITOR

#if type -q code
#  set -x VISUAL "code -w"
#end

type -q pbcopy  ; or alias pbcopy  "xsel -bi"
type -q pbpaste ; or alias pbpaste "xsel -bo"

. ~/.config/fish/solarized.fish
. ~/.config/fish/ua.fish

sourceif ~/.ssh/etc/fish/envrc
sourceif ~/.ssh/etc/fish/functions.fish

if type -q starship
  starship init fish | source

  function fish_prompt_notify --on-event fish_prompt
    # If commands takes longer than 10 seconds, notify user on completion if Terminal
    # in background. (Otherwise e.g. reading man pages for longer than 10 seconds will
    # trigger the notification.) Inspired by https://github.com/jml/undistract-me/issues/32.
    if test $CMD_DURATION
      if test $CMD_DURATION -gt 10000
        if not terminal-frontmost
          set secs (math "$CMD_DURATION / 1000")
          # It's not possible to raise the window via the notification; see
          # https://stackoverflow.com/a/33808356
          notify "$history[1]" "(status $status; $secs secs)"
        end
      end
    end
  end
end

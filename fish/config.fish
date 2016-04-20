# -*- sh -*-

# tool config

set -x GREP_OPTIONS "--exclude-dir=.svn --exclude-dir=.git --binary-files=without-match"
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

# http://fishshell.com/docs/2.1/#variables-special

if test -d ~/.dotfiles/fish/../bin
  set fish_user_paths $fish_user_paths ~/.dotfiles/fish/../bin
end

if test -d ~/local/homebrew/bin
  set fish_user_paths $fish_user_paths ~/local/homebrew/bin
end

if test -d ~/local/homebrew/sbin
  set fish_user_paths $fish_user_paths ~/local/homebrew/sbin
end

if test -d ~/local/bin
  set fish_user_paths $fish_user_paths ~/local/bin
end

if test -d ~/local/google-cloud-sdk/bin
  set fish_user_paths $fish_user_paths ~/local/google-cloud-sdk/bin
end

if test -d ~/local/google-cloud-sdk/platform/google_appengine
  set fish_user_paths $fish_user_paths ~/local/google-cloud-sdk/platform/google_appengine
end

# 1. Download *.tar.gz JRE from
# java
#
# 1. Choose JRE from
#    http://www.oracle.com/technetwork/java/javase/downloads/index.html
# 2. Download the *.tar.gz
# 3. Extract to ~/local.
if test -d ~/local/jre*/Contents/Home/bin
  set fish_user_paths $fish_user_paths ~/local/jre*/Contents/Home/bin
end

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
if test -d /opt/homebrew-cask/Caskroom/ghc/*/ghc-*.app/Contents/bin
  set fish_user_paths $fish_user_paths /opt/homebrew-cask/Caskroom/ghc/*/ghc-*.app/Contents/bin
end
if test -d ~/.cabal/bin
  set fish_user_paths $fish_user_paths ~/.cabal/bin
end

# Android
if test -d ~/workspace/sdk
  set -x ANDROID_HOME ~/workspace/sdk
  set fish_user_paths $fish_user_paths $ANDROID_HOME/platform-tools
end

# Ruby
#
# Install gems via:
#
#   $ gem install $name --user-install
if test -d ~/.gem/ruby/*/bin
  set fish_user_paths $fish_user_paths ~/.gem/ruby/*/bin
end

# golang
#
# Ubuntu (package is golang-*-go)
if test -d /usr/lib/go-*/bin
  set fish_user_paths $fish_user_paths /usr/lib/go-*/bin
end
# OS X
if type go >/dev/null
  set -x GOPATH ~/local/go
  mkdir -p $GOPATH
  if test -d $GOPATH/bin
    set fish_user_paths $fish_user_paths $GOPATH/bin
  end
end

if test -d /usr/local/sbin
  set fish_user_paths $fish_user_paths /usr/local/sbin
end

if test -d /usr/local/bin
  set fish_user_paths $fish_user_paths /usr/local/bin
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

if type atom >/dev/null
  set -x VISUAL "jed" # or "atom -w"
end

source $HOME/.config/fish/solarized.fish

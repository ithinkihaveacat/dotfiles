# -*- sh -*-

# tool config

set -x LESS -XMcifR
set -x TZ Europe/London

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

# Modify PATH directly via fish_add_path -gP rather than using fish_user_paths.
# fish_user_paths is useful for sharing paths across shells when set as a
# universal variable, but can accumulate stale entries over time. Using -gP
# keeps PATH management explicit and predictable. The -m flag moves existing
# entries to avoid duplicates. See
# https://github.com/fish-shell/fish-shell/issues/527#issuecomment-253775156

function add_path
    for p in $argv
        test -d $p; and fish_add_path -gPm $p
    end
end

function sourceif
    if test -r $argv[1]
        source $argv[1]
    end
end

# Google Cloud SDK (gcloud)
#
# https://cloud.google.com/sdk/

add_path $HOME/local/google-cloud-sdk/platform/google_appengine/goroot/bin
add_path $HOME/local/google-cloud-sdk/platform/google_appengine
add_path $HOME/local/google-cloud-sdk/bin

# java

# Via mule:
#
#   $ mule list | grep -o -E "jdk[0-9]+" | sort | tail -1 | xargs mule install

# Via manual install:
#
# Oracle keep messing around with their distributions and licenses... For the
# scripts below to work, you need to end up with the JRE distribution in the
# directory ~/local/jre1.8.0_341.jre/Contents/Home, and the java binary
# available at ~/local/jre1.8.0_341.jre/Contents/Home/bin/java.
#
# To do this:
#
# 1. Go to https://www.oracle.com/uk/java/technologies/javase/javase8u211-later-archive-downloads.html and accept cookies, etc.
# 2. Download the Java SE Runtime Environment.
#      Might be: https://www.oracle.com/webapps/redirect/signon?nexturl=https://download.oracle.com/otn/java/jdk/8u341-b10/424b9da4b48848379167015dcc250d8d/jre-8u341-macosx-x64.tar.gz
# 3. Extract to ~/local.
#
#for d in ~/local/jre*/Contents/Home/bin
#    add_path $d
#end

# Via Android Studio:
#
# https://developer.android.com/studio

# JAVA_HOME is needed for apkanalyzer, and for some reason it's pretty picky about the version. It's compatible with the Android Studio version at least
test -d "/Applications/Android Studio.app/Contents/jbr/Contents/Home"; and set -x JAVA_HOME "/Applications/Android Studio.app/Contents/jbr/Contents/Home"
test -d "/Applications/Android Studio Preview.app/Contents/jbr/Contents/Home"; and set -x JAVA_HOME "/Applications/Android Studio Preview.app/Contents/jbr/Contents/Home"
#test -d /Library/Java/JavaVirtualMachines/default/Contents/Home/jre ; and set -x JAVA_HOME /Library/Java/JavaVirtualMachines/default/Contents/Home/jre
#test -d "/Applications/Android Studio.app/Contents/jre/Contents/Home" ; and set -x JAVA_HOME "/Applications/Android Studio.app/Contents/jre/Contents/Home"

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
#
#for d in /Applications/ghc-*.app/Contents/bin
#    add_path $d
#end
#add_path ~/.cabal/bin

# Android Tools

test -d ~/.local/share/android-sdk; and set -x ANDROID_HOME ~/.local/share/android-sdk
#test -d ~/Library/Android/sdk ; and set -x ANDROID_HOME ~/Library/Android/sdk
#test -d ~/Android/Sdk         ; and set -x ANDROID_HOME ~/Android/Sdk

add_path $ANDROID_HOME/platform-tools
add_path $ANDROID_HOME/cmdline-tools/latest/bin
# the emulator in tools/emulator does not work: https://www.stkent.com/2017/08/10/update-your-path-for-the-new-android-emulator-location.html
add_path $ANDROID_HOME/emulator

if count $ANDROID_HOME/build-tools/* >/dev/null
    add_path (printf '%s\n' $ANDROID_HOME/build-tools/* | sort -rV | head -1)
end

test -d $ANDROID_HOME; and set -x ANDROID_JAR (printf '%s\n' $ANDROID_HOME/platforms/android-*/android.jar | sort -rV | head -1)

# binaries

add_path /opt/homebrew/bin
add_path /opt/homebrew/sbin

add_path /usr/local/sbin
add_path /usr/local/bin

add_path $HOME/local/homebrew/bin
add_path $HOME/local/homebrew/sbin

add_path $HOME/.local/bin

# Ruby
#
# Install gems via:
#
#   $ gem install $name --user-install

#set -x GEM_HOME ~/.gem

#for d in ~/.gem/ruby/*/bin; add_path $d; end

# Node
#
# direnv looks in NODE_VERSIONS for different versions of node; node-install has been configured
# install them there. See ~/.direnv for usage instructions.

set -x NODE_VERSIONS $HOME/.local/share/node/versions
mkdir -p $NODE_VERSIONS

# golang

# Special-case PATH for Ubuntu (package is golang-*-go)
if count /usr/lib/go-*/bin >/dev/null
    add_path (printf '%s\n' /usr/lib/go-*/bin | sort -rV | head -1)
end

if type -q go
    set -x GOPATH ~/local/go
    mkdir -p $GOPATH
    add_path $GOPATH/bin
end

# adb

set -l LOGCAT_IGNORED_TAGS eglCodecCommon EGL_emulation OpenGLRenderer GnssHAL_GnssInterface Wear_NetworkService
set -x ANDROID_LOG_TAGS (string join " " (string replace -r '$' ':s' $LOGCAT_IGNORED_TAGS))
set -x PIDCAT_IGNORED_TAGS (string join ";" $LOGCAT_IGNORED_TAGS)
set -x ADB_VENDOR_KEYS $HOME/.local/share/adb-security/adb # go/wear-productivity-adb#adb-vendor-keys

# acid

if test -r ~/.ssh/etc/acid
    set -x ACID_STARTUP_SCRIPT_PATH ~/.ssh/etc/acid
end

# mosh

set -x MOSH_TITLE_NOPREFIX 1

# other scripts

add_path (realpath $HOME/.dotfiles/fish/../bin)

# http://fishshell.com/docs/current/faq.html#faq-greeting
set fish_greeting

# mkdir -p ~/.rubies
# . $HOME/.config/fish/rubies.fish

# https://github.com/zimbatm/direnv
if type -q direnv
    direnv hook fish | source
    # If MANPATH is set, man very helpfully ignores the default search path as defined in
    # /etc/manpath.config (at least on Linux). Therefore, to ensure man searches through
    # the default after direnv fiddles with MANPATH, we explicitly set it to its default value.
    # See http://unix.stackexchange.com/q/344603/49703
    # Broke around macOS Ventury 13.0
    #set -x MANPATH (man -w)
end

if type -q jed
    set -x EDITOR jed
end

set -x VISUAL $EDITOR

#if type -q code
#  set -x VISUAL "code -w"
#end

# completions

type -q pbcopy; or alias pbcopy fish_clipboard_copy
type -q pbpaste; or alias pbpaste fish_clipboard_paste

sourceif $HOME/.config/fish/solarized.fish

sourceif $HOME/.ssh/etc/fish/envrc
sourceif $HOME/.ssh/etc/fish/functions.fish
sourceif $HOME/.ssh/etc/fish/config.fish

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

# if type -q starship
#     starship init fish | source
# end

if set -q GHOSTTY_RESOURCES_DIR
    source $GHOSTTY_RESOURCES_DIR/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish
end

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

# Google Cloud SDK (gcloud)
#
# https://cloud.google.com/sdk/

add_path $HOME/.local/share/google-cloud-sdk/bin

if type -q gcloud
    if type -q python3
        set -l python_path (which python3)
        if $python_path -c 'import sys; exit(0 if sys.version_info >= (3, 10) else 1)'
            set -gx CLOUDSDK_PYTHON $python_path
        end
    end
end

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

#set -l LOGCAT_IGNORED_TAGS eglCodecCommon EGL_emulation OpenGLRenderer GnssHAL_GnssInterface Wear_NetworkService
#set -x ANDROID_LOG_TAGS (string join " " (string replace -r '$' ':s' $LOGCAT_IGNORED_TAGS))
#set -x PIDCAT_IGNORED_TAGS (string join ";" $LOGCAT_IGNORED_TAGS)
set -x ADB_VENDOR_KEYS $HOME/.local/share/adb-security/adb # go/wear-productivity-adb#adb-vendor-keys

# mosh

set -x MOSH_TITLE_NOPREFIX 1

# other scripts

add_path (realpath $HOME/.dotfiles/fish/../bin)

# Ensure GEMINI_CLI_GEMINI_API_KEY is in sync with GEMINI_API_KEY
# to work around CLI environment variable redaction.
if set -q GEMINI_API_KEY; and not set -q GEMINI_CLI_GEMINI_API_KEY
    set -gx GEMINI_CLI_GEMINI_API_KEY $GEMINI_API_KEY
end

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

# Private overlay: lazy-load functions/completions and run conf.d snippets.
# Functions in ~/.private/fish/functions/ autoload on first invocation
# (e.g. gemini-gfg, cloudtop). conf.d/*.fish runs at every shell startup
# and is the right place for boot-time setsecret calls.
if test -d $HOME/.private/fish/functions
    set -p fish_function_path $HOME/.private/fish/functions
end
if test -d $HOME/.private/fish/completions
    set -p fish_complete_path $HOME/.private/fish/completions
end
if test -d $HOME/.private/fish/conf.d
    for f in $HOME/.private/fish/conf.d/*.fish
        sourceif $f
    end
end

# Corp overlay: lazy-load functions/completions and run conf.d snippets.
if test -d $HOME/.corp/fish/functions
    set -p fish_function_path $HOME/.corp/fish/functions
end
if test -d $HOME/.corp/fish/completions
    set -p fish_complete_path $HOME/.corp/fish/completions
end
if test -d $HOME/.corp/fish/conf.d
    for f in $HOME/.corp/fish/conf.d/*.fish
        sourceif $f
    end
end

# if type -q starship
#     starship init fish | source
# end

# ghostty

if set -q GHOSTTY_RESOURCES_DIR
    source $GHOSTTY_RESOURCES_DIR/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish
end

# uv

set -x UV_EXCLUDE_NEWER "7 days"

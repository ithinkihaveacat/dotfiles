# -*- sh -*-

# tool config

set -x LESS -XMcifR
set -x TZ Europe/London

# Enables compose-preview plugin application via init script.
# See ~/.gradle/init.d/compose-ai-tools.gradle for details.
set -gx COMPOSE_AI_TOOLS true

# personal config

set -x GITROOT "git@github.com:ithinkihaveacat"

# fish config

set -g CDPATH . ~
if test -d ~/workspace
    set -g CDPATH $CDPATH ~/workspace
end

# java
#
# Temurin JDK casks are installed by update and land in:
#   /Library/Java/JavaVirtualMachines/temurin-*.jdk/Contents/Home
#
# Not all tools rely on JAVA_HOME to find a JDK. Gradle toolchains, for
# example, scan /Library/Java/JavaVirtualMachines/ directly and pick the
# right version based on the project's declared requirement. JAVA_HOME is
# mainly needed for tools like apkanalyzer that don't do their own discovery.
#
# JAVA_HOME is set to Android Studio's bundled JBR for compatibility with
# apkanalyzer. Preview is preferred over stable when both are installed.
#
# To use a specific JDK version for a single command (macOS):
#   JAVA_HOME=(/usr/libexec/java_home -v 17) ./gradlew ...
#
# On Linux, set JAVA_HOME manually (no java_home tool is available):
#   JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 ./gradlew ...

if test -d "/Applications/Android Studio Preview.app/Contents/jbr/Contents/Home"
    set -x JAVA_HOME "/Applications/Android Studio Preview.app/Contents/jbr/Contents/Home"
else if test -d "/Applications/Android Studio.app/Contents/jbr/Contents/Home"
    set -x JAVA_HOME "/Applications/Android Studio.app/Contents/jbr/Contents/Home"
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
add_path $HOME/.local/share/npm/bin

# Google Cloud SDK (gcloud)
#
# https://cloud.google.com/sdk/

add_path $HOME/.local/share/google-cloud-sdk/bin

# Ruby
#
# direnv looks in RUBY_VERSIONS for different versions of ruby; ruby-install has
# been configured to install them there. See ~/.direnvrc for usage instructions.

set -x RUBY_VERSIONS $HOME/.local/share/ruby/versions
mkdir -p $RUBY_VERSIONS

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
add_path $HOME/.corp/bin

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

# uv
set -x UV_EXCLUDE_NEWER "7 days"

# Force uv to use its own managed/hermetic Python installations instead of system ones.
# On macOS, official Python.org installers (which land in /Library/Frameworks/Python.framework)
# do not install root certificates by default, leaving Python's SSL context without any trusted
# CA bundle. This causes all HTTPS requests made via Python's built-in urllib or standard ssl
# library to fail with: [SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed.
# By default, uv will search for and use system-installed Pythons if they satisfy version
# requirements (e.g., >=3.11). Forcing 'managed' ensures uv uses hermetic Python builds that
# have working root certificates out of the box, avoiding SSL validation failures in user scripts.
set -x UV_PYTHON_PREFERENCE managed

# Default required skills for agent CLI preflight checks
if not set -q AGENT_REQUIRED_SKILLS
    set -gx AGENT_REQUIRED_SKILLS agent-tools coding-standards workspace-config technical-writing
end

_load_overlay $HOME/.private
_load_overlay $HOME/.corp

# if type -q starship
#     starship init fish | source
# end

# ghostty

if set -q GHOSTTY_RESOURCES_DIR
    source $GHOSTTY_RESOURCES_DIR/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish
end

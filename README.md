# About

Config files for various tools I use, or have used in the past, such as
[fish](http://fishshell.com/), [git](http://git-scm.com/),
[jed](http://www.jedsoft.org/jed/) and [Sublime
Text](http://www.sublimetext.com/).

It's very unlikely that anyone will want to use this directly; the more
interesting directories are:

* [fish](fish) - configuration and startup files for fish shell.
* [bin](bin) - mostly git commands that are a bit too long or complicated to be
  embedded into [.gitconfig](home/.gitconfig).
* [templates/hooks](templates/hooks) - git hooks

Note that there's a lot of bash config files scattered about the place--I used
to use bash but have now switched to fish, but am keeping it around for the
memories, such as the [list of operating systems](unix) that have been
"supported" at some point in the past...

# Prerequisites

## [fish](http://fishshell.com/)

### OS X

````sh
$ brew install fish
````

### Don't have [homebrew](http://brew.sh/)?

#### If you want to install into `/usr/local` ...

See <http://brew.sh>.

#### If you want to install somewhere else ...

See <https://github.com/Homebrew/homebrew/wiki/Installation#untar-anywhere-and-then-symlink-the-brew-command-elsewhere>

Note that the binaries are symlinked into whatever directory `brew` is
installed into. (So if `brew` is symlinked into `/usr/local/bin`, then
all executables `brew` installs will be symlinked into there as well.)
This can be useful if you want to install `brew` in your home
directory, but symlink binaries into `/usr/local/bin`.

### Other Platforms

See <http://fishshell.com/>.

## [PHP](http://php.net) (Optional)

Probably best to [install from source](http://php.net/downloads.php).

You'll probably want to enable a few extensions when you `./configure`:

````sh
$ ./configure --with-curl --with-zlib --with-openssl --enable-zip
````

# Installation

````sh
$ cd $HOME
$ git clone git@github.com:ithinkihaveacat/dotfiles.git .dotfiles
$ cd $HOME/.dotfiles
$ ./update
# On OS X, logout and login again
````

Note that `update` may be destructive&#8212;if you have "unmanaged" files in
locations such as `~/Library/KeyBindings` or `~/Library/Fonts`, they will be
wiped out!

It's safe to run `update` multiple times.  (It's idempotent.)

# Manual Changes

## All Platforms

### Sublime Text

[Install Package Control](https://sublime.wbond.net/installation). The actual
packages to install are stored in [`etc/subl/Package Control.sublime-settings`](Package Control.sublime-settings); Package Control
will pick this up and install the appropriate packages as soon as it itself is
installed.

## OS X

### Configure Terminal

Import [`etc/Solarized Dark.terminal`](etc/Solarized Dark.terminal).

### "New Terminal at Folder"

System Preferences > Keyboard > Keyboard Shortcuts > Services > File and Folders

* Enable "New Terminal at Folder"

## Ubuntu

### Emacs Keybindings

Get emacs keybindings across all gtk apps
([source](http://superuser.com/a/348609)):

````sh
$ gsettings set org.gnome.desktop.interface gtk-key-theme "Emacs"
````

### Ubuntu Terminal

#### Change Colour Scheme

Run the following `gconftool` commands to set
[Solarized](http://ethanschoonover.com/solarized) colours correctly:

<http://stackoverflow.com/a/7734960>

#### Change Font

Use "Profile Preferences" to change the default font.

#### Make Alt Available

Open "Keyboard Shortcuts" and unselect "Enable menu access keys".
(Otherwise Alt is used for accessing the menu.)

# Author

<mjs@beebo.org>

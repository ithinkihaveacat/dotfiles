## About

Config files for various tools I use, or have used in the past, such as
[fish](http://fishshell.com/), [git](http://git-scm.com/),
[jed](http://www.jedsoft.org/jed/), [Sublime
Text](http://www.sublimetext.com/) and [Atom](https://atom.io/).

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

## Prerequisites

> **Getting locale-related errors when going through these steps?**
>
> 1. Generate missing locales: `locale-gen fi_FI.UTF-8`

### [git](http://git-scm.com/)

Ubuntu | OS X
-------|-----
`sudo apt-get install git-core`|Install [Xcode](https://developer.apple.com/xcode/downloads/)

> No `sudo`? (If, for example, you're on a Gandi VPS.)
>
> 1. Login as root: `ssh root@server`
> 1. Install `sudo`: `apt-get install sudo`
> 1. Edit `/etc/sudoers`: `visudo`
> 1. Add the line: `mjs ALL=(ALL) NOPASSWD:ALL`

### [fish](http://fishshell.com/)

Ubuntu | OS X
-------|-----
`sudo apt-get install fish ; sudo chsh mjs -s /usr/bin/fish`|`brew install fish`

> **Need latest version?**
>
> 1. Check version: `apt-cache show fish`
> 1. Install `apt-add-repository`: `sudo apt-get install software-properties-common python-software-properties`
> 1. Add fish PPA: <https://launchpad.net/~fish-shell/+archive/ubuntu/release-2>
>
> **No [`brew`](http://brew.sh/)?**
>
> *If you want to install into `/usr/local` ...*
>
> See <http://brew.sh>.
>
> *If you want to install somewhere else ...*
>
> See [alternative installs](https://github.com/Homebrew/homebrew/blob/master/share/doc/homebrew/Installation.md#alternative-installs).
>
> Note that the binaries are symlinked into whatever directory `brew` is
installed into. (So if `brew` is symlinked into `/usr/local/bin`, then
all executables installed by `brew` will be symlinked into there as well.)
This can be useful if you want to install `brew` in your home
directory, but symlink binaries into `/usr/local/bin`.
>
> *Other Platforms*
>
> See <http://fishshell.com/>.

## Installation

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

(Though it is safe to run `update` multiple times.)

## Manual Changes

### All Platforms

#### [PHP](http://php.net)

Probably best to [install from source](http://php.net/downloads.php).

You'll probably want to enable a few extensions when you `./configure`:

````sh
$ ./configure --with-curl --with-zlib --with-openssl --enable-zip
````

#### Sublime Text

[Install Package Control](https://sublime.wbond.net/installation). The actual
packages to install are stored in [`etc/subl/Package Control.sublime-settings`](Package Control.sublime-settings); Package Control
will pick this up and install the appropriate packages as soon as it itself is
installed.

#### [jed](http://www.jedsoft.org/jed/)

`jed` has stopped building via `brew`, though maybe it's because I'm installing
to somewhere other than `/usr/local`.

If you have problems with the packages, you can do this manually via something
like:

````sh
# slang
wget http://www.jedsoft.org/releases/slang/slang-2.3.0.tar.gz
# extract
./configure --prefix=$HOME/local --libdir=$HOME/local/homebrew/lib --includedir=$HOME/local/homebrew/include --without-x --without-png
make
make install

# jed
wget http://www.jedsoft.org/releases/jed/jed-0.99-19.tar.gz
# extract
./configure --prefix=$HOME/local --libdir=$HOME/local/homebrew/lib --includedir=$HOME/local/homebrew/include --without-x
make
make install
````

### OS X

#### Configure Terminal

Import [`etc/Solarized Dark.terminal`](etc/Solarized Dark.terminal).

#### "New Terminal at Folder"

System Preferences > Keyboard > Keyboard Shortcuts > Services > File and Folders

* Enable "New Terminal at Folder"

#### Add Lock Screen to Menu Bar

For some reason this is configured via "Keychain Access" preferences.

### Ubuntu

#### Emacs Keybindings

Get emacs keybindings across all gtk apps
([source](http://superuser.com/a/348609)):

````sh
$ gsettings set org.gnome.desktop.interface gtk-key-theme "Emacs"
````

#### Ubuntu Terminal

##### Change Colour Scheme

Run the following `gconftool` commands to set
[Solarized](http://ethanschoonover.com/solarized) colours correctly:

<http://stackoverflow.com/a/7734960>

##### Change Font

Use "Profile Preferences" to change the default font.

##### Make Alt Available

Open "Keyboard Shortcuts" and unselect "Enable menu access keys".
(Otherwise Alt is used for accessing the menu.)

## Author

<mjs@beebo.org>

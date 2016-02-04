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
>
> Don't want to install Xcode?
>
> Run `git` and install the command-line tools. (Also saves a lot of diskspace.)

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
> See [alternative installs](https://github.com/Homebrew/homebrew/blob/master/share/doc/homebrew/Installation.md#alternative-installs). (Installing into `~/local/homebrew`, and symlinking `brew` into `~/local/homebrew/bin` might be a good option.)
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
$ git clone https://github.com/ithinkihaveacat/dotfiles.git .dotfiles
# Pull from ro repo, push to rw
$ git remote set-url origin --push git@github.com:ithinkihaveacat/dotfiles.git
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

#### [jed](http://www.jedsoft.org/jed/)

`jed` has stopped building via `brew`, though maybe it's because I'm installing
to somewhere other than `/usr/local`.

If you have problems with the packages, you can do this manually via something
like:

````sh
# slang
wget http://www.jedsoft.org/snapshots/slang-pre2.3.1-40.tar.gz
# extract
./configure --prefix=$HOME/local --libdir=$HOME/local/homebrew/lib --includedir=$HOME/local/homebrew/include --without-x --without-png
make
make install

# jed
wget http://www.jedsoft.org/snapshots/jed-pre0.99.20-111.tar.gz
# extract
./configure --prefix=$HOME/local --libdir=$HOME/local/homebrew/lib --includedir=$HOME/local/homebrew/include --without-x
make
make install
````

### OS X

(See [this
script](https://github.com/mathiasbynens/dotfiles/blob/master/.osx)
for some tips on how to change some of these settings automatically.)

#### Configure Terminal

Import the [`etc/Solarized Dark.terminal`](etc/Solarized Dark.terminal) profile. (See [this script](https://github.com/mathiasbynens/dotfiles/blob/master/.osx) for some information on how to do this automatically.)

#### Configure keyboard

* Open System Preferences > Keyboard
  * Open Shortcuts > Services > File and Folders, enable "New Terminal at Folder".
  * Open Text, disable "Correct spelling automatically".

#### Add Lock Screen option to Menu Bar

Configure via "Keychain Access" preferences.

#### Add Volume Controls to Menu Bar

Configure via the "Sound" system preference panel.

#### Disable local Time Machine backups

    $ sudo tmutil disablelocal

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

## Manually Installing Binaries?

Put them in `~/local/bin`, and man pages (if you have them) in
`~/local/share/man/man?`. (`man --path` lists the man page search
path.)

## Author

<mjs@beebo.org>

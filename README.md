# dotfiles

## About

Config files for various tools I use, or have used in the past, such as
[fish](http://fishshell.com/), [git](http://git-scm.com/),
[jed](http://www.jedsoft.org/jed/), and
[Visual Studio Code](https://code.visualstudio.com/).

It's very unlikely that anyone will want to use this directly; the more
interesting directories are:

- [fish](fish) - configuration and startup files for fish shell.
- [bin](bin) - bash scripts for various things.
- [fish functions](fish/functions) - more scripts, generally those that are
  awkward/impossible to write in bash.
- [etc/git/templates](etc/git/templates) - git hooks
- [docker](docker) - Dockerfile

The idempotent [install script](./update) handles a few different operating
systems and package managers (past and present) has a some interesting
constructions that may be useful.

## Prerequisites

> **Getting locale-related errors when going through these steps?**
>
> 1. Generate missing locales: `locale-gen en_GB.UTF-8`

### [git](http://git-scm.com/)

- **Ubuntu**: `sudo apt-get install git-core`
- **OS X**: `xcode-select --install` (or install
  [Xcode](https://developer.apple.com/xcode/downloads/))

> No `sudo`? (If, for example, you're on a Gandi VPS.)
>
> 1. Login as root: `ssh root@server`
> 1. Install `sudo`: `apt-get install sudo`
> 1. Edit `/etc/sudoers`: `visudo`
> 1. Add the line: `mjs ALL=(ALL) NOPASSWD:ALL`

### [fish](http://fishshell.com/)

#### Ubuntu

```sh
sudo apt-get install fish
```

#### OS X

Via [`brew`](http://brew.sh/):

```sh
brew install fish
chsh -s /bin/bash # .bash_profile runs fish if available (zsh is default)
```

> **Don't already have [`brew`](http://brew.sh/)?**
>
> _If you want to install into `/opt/homebrew` ..._
>
> See <http://brew.sh>.
>
> _If you want to install somewhere else ..._
>
> See
> [alternative installs](https://github.com/Homebrew/brew/blob/master/docs/Installation.md#alternative-installs).
> (Installing into `~/local/homebrew`, and symlinking `brew` into
> `~/local/homebrew/bin` might be a good option.)
>
> Note that the binaries are symlinked into whatever directory `brew` is
> installed into. (So if `brew` is symlinked into `/usr/local/bin`, then all
> executables installed by `brew` will be symlinked into there as well.) This
> can be useful if you want to install `brew` in your home directory, but
> symlink binaries into `/usr/local/bin`.

#### Other Platforms

See <http://fishshell.com/>.

## Installation

```sh
$ cd $HOME
$ git clone https://github.com/ithinkihaveacat/dotfiles.git .dotfiles
$ cd $HOME/.dotfiles
# Pull from ro repo, push to rw
$ git remote set-url origin --push git@github.com:ithinkihaveacat/dotfiles.git
$ ./update  # if macOS and brew in PATH
$ PATH=~/local/homebrew/bin:/opt/homebrew/bin:$PATH ./update  # if not
# On OS X, logout and login again
```

Note that `update` may be destructive&#8212;if you have "unmanaged" files in
locations such as `~/Library/KeyBindings` or `~/Library/Fonts`, they will be
wiped out!

(Though it is safe to run `update` multiple times.)

## Environment Management

This repository uses [direnv](https://direnv.net/) to automatically switch
development environments when entering directories. This is configured via
`~/.direnvrc` (linked from `home/.direnvrc`) and hooks in `fish/config.fish`.

To configure a project, create an `.envrc` file in the project root.

### Node.js

Node.js versions are managed by the custom `node-install` script (found in
`bin/`) and `direnv`.

1. **Install a Node.js version:**

   ```sh
   node-install 22  # Installs the latest 22.x release
   ```

   This installs the version into `$HOME/.local/share/node/versions`.

2. **Use it in a project:**

   Add the following to your `.envrc`:

   ```sh
   use node 22
   layout node
   ```

   `use node 22` selects the version, and `layout node` adds `node_modules/.bin`
   to the PATH.

### Python (via uv)

Python environments are managed using [uv](https://github.com/astral-sh/uv).

1. **Use it in a project:**

   Add the following to your `.envrc`:

   ```sh
   layout uv
   ```

   This will automatically create a virtual environment (`.venv`) if one doesn't
   exist (using `uv venv`) and activate it.

### Environment Variables

You can also use `.envrc` to set environment variables on a per-project basis.
This is useful for API keys, configuration flags, or other project-specific
settings.

**Example:**

```sh
export GEMINI_API_KEY="your-api-key"
export PORT=8080
```

When you enter the directory, these variables will be exported. When you leave,
they will be unset.

## Manual Changes

### All Platforms

#### [jed](http://www.jedsoft.org/jed/)

If you have problems installing `jed` from packages, it can be installed
manually via something like:

```sh
# slang
wget http://www.jedsoft.org/snapshots/slang-pre2.3.1-40.tar.gz
# extract
./configure --prefix=$HOME/local \
  --libdir=$HOME/local/homebrew/lib \
  --includedir=$HOME/local/homebrew/include \
  --without-x --without-png
make
make install

# jed
wget http://www.jedsoft.org/snapshots/jed-pre0.99.20-111.tar.gz
# extract
./configure --prefix=$HOME/local \
  --libdir=$HOME/local/homebrew/lib \
  --includedir=$HOME/local/homebrew/include \
  --without-x
make
make install
```

### macOS

(See [this script](https://github.com/mathiasbynens/dotfiles/blob/master/.osx)
for some tips on how to change some of these settings automatically.)

#### Configure Terminal

Import the [`etc/Solarized Dark.terminal`](etc/Solarized Dark.terminal) profile,
and set it to the "default". (See
[this script](https://github.com/mathiasbynens/dotfiles/blob/master/.osx) for
some information on how to do this automatically.)

#### Configure keyboard

- Open System Preferences > Keyboard
  - Open Shortcuts > Services > File and Folders, enable "New Terminal at
    Folder".
  - Open Text, disable "Correct spelling automatically".

#### Configure Text Replacements

If signed into the same iCloud account, these should be shared automatically.

Otherwise, see
[Back up and share text replacements on Mac](https://support.apple.com/en-gb/guide/mac-help/mchl2a7bd795/mac).
Text replacements themselves are stored in [`etc/Text
Replacements.plist`](etc/Text Replacements.plist)

#### Add Lock Screen option to Menu Bar

Configure via "Keychain Access" preferences.

#### Add Volume Controls to Menu Bar

Control Center | Sound | Always Show in Menu Bar.

#### Disable local Time Machine backups

```sh
sudo tmutil disablelocal
```

#### Install "Network Link Conditioner"

<https://developer.apple.com/download/more/?q=Additional%20Tools>

This provides a way to simulate degraded network conditions
([more info](http://nshipster.com/network-link-conditioner/)).

#### Install GitHub theme for iA Writer

See <https://ia.net/writer/templates/>.

#### Disable Hot Corners

Via System Preferences.

#### Install optional fonts

See <https://typography.guru/journal/awesome-catalina-fonts/>.

### Ubuntu (Additional)

#### Emacs Keybindings

Get emacs keybindings across all gtk apps
([source](http://superuser.com/a/348609)):

```sh
gsettings set org.gnome.desktop.interface gtk-key-theme "Emacs"
```

#### Compose Key

Set the [compose key](https://help.ubuntu.com/community/ComposeKey) to Caps Lock
so that you can e.g. hold down Caps Lock and type `---` to get an mdash.

#### Fonts

Open "System Settings", change the fonts as below:

![Fonts](https://i.imgur.com/oBF07hH.png)

#### Terminal

##### Change Colour Scheme

Run the following `gconftool` commands to set
[Solarized](http://ethanschoonover.com/solarized) colours correctly:

<http://stackoverflow.com/a/7734960>

##### Change Font

Use "Profile Preferences" to change the default font.

##### Make Alt Available

Open "Keyboard Shortcuts" and unselect "Enable menu access keys". (Otherwise Alt
is used for accessing the menu.)

##### Change Size

Edit "Default" profile, change custom default terminal size to 100 columns, 60
rows.

### Raspberry Pi OS

1. Use the Raspberry Pi Imager <https://www.raspberrypi.com/software/> to
   install the OS on an SD card or external SSD.
   1. For a "headless" version (i.e. without desktop apps), go to "Raspberry Pi
      OS (other)" and select "Raspberry Pi OS Lite".
   1. In the OS customization settings, enable SSH access in the "Remote access"
      section.
   1. (Optional) Configure Wi-Fi in the "Wi-Fi" section.
1. SSH into the machine: `ssh mjs@lil.local` (where `mjs` is the username and
   `lil` is the hostname provided in the "User" section of the imager).
   1. (Optional) If using Ghostty, copy the terminfo (run from your local
      machine): `infocmp -x xterm-ghostty | ssh mjs@lil.local -- tic -x -`
1. Update the OS: `sudo apt-get update && sudo apt-get upgrade -y`
   1. If `/var/run/reboot-required` exists (created if a package update requires
      a reboot), reboot: `sudo reboot`.
1. Install `fish`: `sudo apt-get install fish`.
1. Install `git`: `sudo apt-get install git`.
1. Install `tailscale`: `curl -fsSL https://tailscale.com/install.sh | sh`
   <https://tailscale.com/download/linux>
   1. Log in to Tailscale: `sudo tailscale up`
1. (Optional) Install `nodejs` and `npm`: `sudo apt-get install nodejs npm`.
   Note that these may be older versions; for newer versions, see the
   [Node.js](#nodejs) section.
1. (Optional) Disable WiFi and Bluetooth: add `dtoverlay=disable-wifi` and
   `dtoverlay=disable-bt` on separate lines under the `[all]` section in
   `/boot/firmware/config.txt`. (See the
   [overlays README](https://raw.githubusercontent.com/raspberrypi/firmware/master/boot/overlays/README)
   for more info.)
1. (Optional) Change the hostname: edit `/etc/hostname` and `/etc/hosts`,
   replacing the old hostname with the new one in both files.

A reboot is recommended after performing any of the optional configuration steps
above (such as disabling WiFi/Bluetooth or changing the hostname) to ensure that
the changes are consistently applied across the system: `sudo reboot`.

Once complete, the Raspberry Pi is ready for user configuration. Proceed to the
[Installation](#installation) section to clone these dotfiles and set up your
environment.

Recommendation: use VS Code's
[Remote - SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh)
extension to edit files.

## Manually Installing Binaries?

Put them in `~/local/bin`, and man pages (if you have them) in
`~/local/share/man/man?`. (`man --path` lists the man page search path.)

## Author

<mjs@beebo.org>

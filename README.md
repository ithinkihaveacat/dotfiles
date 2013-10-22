### About

Config files for various tools I use, or have used in the past, such as [fish](http://fishshell.com/), [git](http://git-scm.com/), [jed](http://www.jedsoft.org/jed/) and [Sublime Text](http://www.sublimetext.com/).

It's very unlikely that anyone will want to use this directly; the more interesting directories are:

* [fish](fish) - configuration and startup files for fish shell.
* [bin](bin) - mostly git commands that are a bit too long or complicated to be embedded into [.gitconfig](home/.gitconfig).
* [templates/hooks](templates/hooks) - git hooks; these are installed via [`git updatehooks`](bin/git-updatehooks).

Note that there's a lot of bash config files scattered about the place--I used to use bash but have now switched to fish, but am keeping it around for the memories, such as the [list of operating systems](unix) that have been "supported" at some point in the past...

### Prerequisites

#### OS X

##### [homebrew](http://brew.sh/)

homebrew needs write permission to `/usr/local`, although this can be limited to just install symlinks. If you only want symlinks in `/usr/local`, do something like:

````sh
$ mkdir -p $HOME/local
$ cd $HOME/local
$ mkdir homebrew && curl -L https://github.com/mxcl/homebrew/tarball/master | tar xz --strip 1 -C homebrew
$ sudo ln -s $HOME/local/homebrew/bin/brew /usr/local/bin/brew
````

Then, make certain directores in `/usr/local` writable:

````sh
$ sudo chown $USER /usr/local /usr/local/bin /usr/local/share /usr/local/etc /usr/local/share/man
````

(You may need to do this every time you `brew install`, if something is changing the permissions in `/usr/local`.)

##### [fish](http://fishshell.com/)

````sh
$ brew install fish
````

### Installation

````sh
$ cd $HOME
$ git clone git@github.com:ithinkihaveacat/dotfiles.git .dotfiles
$ cd $HOME/.dotfiles
$ ./update
# On OS X, logout and login again
````

Note that `update` may be destructive--if you have "unmanaged" files in
locations such as `~/Library/KeyBindings` or `~/Library/Fonts`, they
will be wiped out!

It's safe to run `update` multiple times.  (It's idempotent.)

### Manual Changes

#### Sublime Text

[Install Package Control](https://sublime.wbond.net/installation).

#### OS X

##### "New Terminal at Folder"

System Preferences > Keyboard > Keyboard Shortcuts > Services > File and Folders

* Enable "New Terminal at Folder"

##### Sublime Text

Symlink `subl`:

````sh
$ ln -s "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl" /usr/local/bin/subl
````

#### Terminal Configuration

Import `etc/Solarized Dark.terminal`.

#### Ubuntu

##### Solarized Terminal

Run the following `gconftool` commands to set the terminal colours correctly:

<http://stackoverflow.com/a/7734960>

### To Do

Go through
<http://blog.flowblok.id.au/2013-02/shell-startup-scripts.html> and
copy anything useful.

### Author

Michael Stillwell<br/>
mjs@beebo.org

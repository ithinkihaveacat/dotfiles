### About

Config files for various tools I use, or have used in the past, such as [fish](http://fishshell.com/), [git](http://git-scm.com/), [jed](http://www.jedsoft.org/jed/) and [Sublime Text](http://www.sublimetext.com/).

It's very unlikely that anyone will want to use this directly; the more interesting directories are:

* [fish](fish) - configuration and startup files for fish shell.
* [bin](bin) - mostly git commands that are a bit too long or complicated to be embedded into [.gitconfig](home/.gitconfig).
* [templates/hooks](templates/hooks) - git hooks; these are installed via [`git updatehooks`](bin/git-updatehooks).

Note that there's a lot of bash config files scattered about the place--I used to use bash but have no switched to fish, but am keeping it around for the memories, such as the [list of operatings systems](unix) that have been "supported" at some point in the past...

### Installation

````sh
$ cd $HOME
$ git clone git@github.com:ithinkihaveacat/dotfiles.git .dotfiles
$ cd $HOME/.dotfiles
$ ./update
````

Note that `update` may be destructive--if you have "unmanaged" files in
locations such as `~/Library/KeyBindings` or `~/Library/Fonts`, they
will be wiped out!

It's safe to run `update` multiple times.  (It's idempotent.)

### Manual Changes

System Preferences > Keyboard > Keyboard Shortcuts > Services

* Enable "New Terminal at Folder"

### To Do

Go through
<http://blog.flowblok.id.au/2013-02/shell-startup-scripts.html> and
copy anything useful.

### Author

Michael Stillwell<br/>
mjs@beebo.org

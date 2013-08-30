## Installation Instructions

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

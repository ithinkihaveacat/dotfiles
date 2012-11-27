## Installation Instructions

    cd $HOME
    git clone git@github.com:ithinkihaveacat/dotfiles.git .config   # If you're ithinkihaveacat
    git clone git://github.com/ithinkihaveacat/dotfiles.git .config # If you're not ithinkihaveacat
    cd $HOME/.config
    ./install

Note that `install` may be destructive--if you have "unmanaged" files in
locations such as `~/Library/KeyBindings` or `~/Library/Fonts`, they
will be wiped out!

It's safe to run `install` multiple times.  (It's idempotent.)

# Manual Changes

System Preferences > Keyboard > Keyboard Shortcuts > Services

* Enable "New Terminal at Folder"

System Preferences > Keyboard > Keyboard Shortcuts > Keyboard & Text
Input

* Change keybinding for "Move focus to the next window" to ⌘ §.
(Cmd-§.)

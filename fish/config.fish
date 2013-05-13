# -*- sh -*-

set -g GITROOT "git@github.com:ithinkihaveacat"
set -g GREP_OPTIONS "--exclude=.svn --exclude=.git --binary-files=without-match"
set -g TZ "Europe/London"

# Create ls and dir aliases
type -t gls > /dev/null
switch $status

  case 0
    function ls
      command gls -FBh --color=auto $argv
    end

    function dir
      command gls -lFBh --color=auto $argv
    end  
    
  case '*'
    function ls
      command ls -FBh --color=auto $argv
    end

    function dir
      command ls -lFBh --color=auto $argv
    end  

end

# Remove greeting
set fish_greeting

# Configure git prompt
# https://github.com/fish-shell/fish-shell/blob/master/share/functions/__fish_git_prompt.fish
set -g __fish_git_prompt_showupstream "auto"
set -g __fish_git_prompt_showstashstate "1"
set -g __fish_git_prompt_showdirtystate "1"

. $HOME/.config/fish/rubies.fish

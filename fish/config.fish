type -t gls > /dev/null
switch $status

  case 0
    function ls
      command gls -FBh $argv
    end

    function dir
      command gls -lFBh $argv
    end  
    
  case '*'
    function ls
      command ls -FBh $argv
    end

    function dir
      command ls -lFBh $argv
    end  

end

# Remove greeting
set fish_greeting

# https://github.com/fish-shell/fish-shell/blob/master/share/functions/__fish_git_prompt.fish
set -g __fish_git_prompt_showupstream "auto"
set -g __fish_git_prompt_showstashstate "1"
set -g __fish_git_prompt_showdirtystate "1"

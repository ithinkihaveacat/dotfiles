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

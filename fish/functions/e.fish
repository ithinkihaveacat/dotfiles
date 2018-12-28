function e -d 'Edit file, searching in a few different places' -w type

  if test ( count $argv ) -ne 1
    printf "usage: %s filename" (status current-command)
    return
  end

  if test -f $argv[1]
    eval $EDITOR $argv[1]
    return
  end

  if not type -qt $argv[1]
    printf "%s: '%s' not found, or not a file\n" (status current-command) $argv[1]
    return
  end

  switch ( type -t $argv[1] )

    case file

      if file ( type -p $argv[1] ) | grep text >/dev/null
        eval $EDITOR ( type -p $argv[1] )
      else
        echo "error: '$argv[1]' is not a text file"
      end

    case function

      if test -f $HOME/.config/fish/functions/$argv[1].fish
        eval $EDITOR $HOME/.config/fish/functions/$argv[1].fish
      else
        echo "error: '$argv[1]' not defined in $HOME/.config/fish/functions"
      end

    case '*'

      echo "error: '$argv[1]' not found"

  end

end

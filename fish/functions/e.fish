function e -d 'Edit file, searching in a few different places'

  if test ( count $argv ) -ne 1
    echo "usage: $_ filename"
    return
  end

  if not type -qt $argv[1]
    echo "$_: '$argv[1]' not found"
    return
  end

  switch (type -t $argv[1])

    case file

      if file (type -p $argv[1]) | grep text >/dev/null
        eval $EDITOR (type -p $argv[1])
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

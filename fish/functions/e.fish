function e -d 'Search for filename in $PATH, edit with $EDITOR'
  if test ( count $argv ) -ne 1
    echo "usage: $_ filename"
    return
  end
  if test -f $argv[1]
    eval $EDITOR $argv[1]
  end
  # Might be able to switch to "command" in fish 2.2+ (or type -q)
  if type -P $argv[1] >/dev/null
    if file (type -P $argv[1]) | grep text >/dev/null
      eval $EDITOR (type -P $argv[1])
    else
      echo "$_: '$argv[1]' is not a text file"
    end
  else
    echo "$_: Could not find '$argv[1]'"
  end
end

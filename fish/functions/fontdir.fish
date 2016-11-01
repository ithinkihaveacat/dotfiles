function fontdir

  if test -x /bin/uname
    set UNAME "/bin/uname"
  else if test -x /usr/bin/uname
    set UNAME "/usr/bin/uname"
  end

  switch (eval $UNAME)

    case Linux
      echo "$HOME/.fonts"

    case Darwin
      echo "$HOME/Library/Fonts"

    case '*'
      exit 1

  end

end

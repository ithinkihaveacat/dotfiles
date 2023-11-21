function downloads-latest -d 'echos filename of newest file in ~/Downloads'

  ls -tr (find $HOME/Downloads -type f -depth 1) | tail -1

end

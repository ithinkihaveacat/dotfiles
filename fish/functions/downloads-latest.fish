function downloads-latest -d 'echos filename of newest file in ~/Downloads'

  ls -trd $HOME/Downloads/* | tail -1

end

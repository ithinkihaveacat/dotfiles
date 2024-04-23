function desktop-latest -d 'echos filename of newest file in ~/Desktop'

  ls -trd $HOME/Desktop/* | tail -1

end

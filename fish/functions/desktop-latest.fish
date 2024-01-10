function desktop-latest -d 'echos filename of newest file in ~/Desktop'

  ls -tr (find $HOME/Desktop -type f -depth 1) | tail -1

end

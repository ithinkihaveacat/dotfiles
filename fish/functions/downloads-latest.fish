function downloads-latest -d 'echos filename of newest file in ~/Downloads'

  find "$HOME/Downloads" -type f -exec stat -f "%m %N" {} + | sort -n -r | head -n 1 | cut -d" " -f2-

end

function desktop-latest -d 'echos filename of newest file in ~/Desktop'

    find "$HOME/Desktop" -type f -exec stat -f "%m %N" {} + | sort -n -r | head -n 1 | cut -d" " -f2-

end

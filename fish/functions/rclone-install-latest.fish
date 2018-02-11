function rclone-install-latest -d "Install latest version of rclone"

  unzip -oj (curl -s https://downloads.rclone.org/rclone-current-osx-amd64.zip | psub) -d $HOME/local/bin '*/rclone'
  unzip -oj (curl -s https://downloads.rclone.org/rclone-current-osx-amd64.zip | psub) -d $HOME/local/share/man/man1 '*/rclone.1'

end

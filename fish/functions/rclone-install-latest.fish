function rclone-install-latest -d "Install latest version of rclone"

    mkdir -p $HOME/local/bin
    unzip -oj (curl -s https://downloads.rclone.org/rclone-current-osx-amd64.zip | psub) -d $HOME/local/bin '*/rclone'
    mkdir -p $HOME/local/share/man/man1
    unzip -oj (curl -s https://downloads.rclone.org/rclone-current-osx-amd64.zip | psub) -d $HOME/local/share/man/man1 '*/rclone.1'

end

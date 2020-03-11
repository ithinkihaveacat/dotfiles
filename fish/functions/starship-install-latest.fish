function starship-install-latest -d "Install latest version of starship"
  curl -fsSL https://starship.rs/install.sh | bash /dev/stdin -y -b $HOME/local/bin
end

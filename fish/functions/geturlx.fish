function geturlx -w wget -d "Retrieve single URL, mapping host and path to directories"
  wget --quiet --force-directories $argv
end

function getcat -d "Retrieve single URL, output to stdout"
  wget --quiet -O - $argv
end

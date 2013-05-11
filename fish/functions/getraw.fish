function getraw -d "Retrieve single URL (including headers), output to stdout"
  curl -s -i --max-redirs 0 $argv
end

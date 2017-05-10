function gethead -d "Retrieve single URL, displaying headers only"
  curl -sS -D - -o /dev/null $argv
  # curl -s -i --max-redirs 0 $argv | perl -ne 'print if 1 .. /^\s*$/'
end

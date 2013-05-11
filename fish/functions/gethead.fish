function gethead -d "Retrieve single URL, display headers only"
  curl -s -i --max-redirs 0 $argv | perl -ne 'print if 1 .. /^\s*$/'
end

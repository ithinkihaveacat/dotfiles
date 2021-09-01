function randombase64 -d "Generate random base64 string"
  set -l n $argv[1]; test -z $n; and set n 16
  # https://en.wikipedia.org/wiki/Birthday_problem#Probability_table
  dd if=/dev/urandom bs=1 count=$n 2>/dev/null | base64 | tr -d "[/+]" | cut -b -$n
end

function randombase64 -d "Generate random base64 string"
  set -l n $argv[1]; test -z $n; and set n 12
  # https://en.wikipedia.org/wiki/Birthday_problem#Probability_table
  dd if=/dev/urandom bs=1 count=$n ^/dev/null | base64 | cut -b -$n
end

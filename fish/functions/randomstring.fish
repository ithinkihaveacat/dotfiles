function randomstring -d "Generate random base64 string"
  # https://en.wikipedia.org/wiki/Birthday_problem#Probability_table
  dd if=/dev/urandom bs=1 count=128 ^/dev/null | base64 | cut -b -12
end

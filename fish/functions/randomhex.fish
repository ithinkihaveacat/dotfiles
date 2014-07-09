function randomhex -d "Generate random hexadecimal string"
  # https://en.wikipedia.org/wiki/Birthday_problem#Probability_table
  dd if=/dev/urandom bs=1 count=128 ^/dev/null | gmd5sum - | cut -b -12
end

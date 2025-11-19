function randomhex -d "Generate random hexadecimal string"
    set -l n $argv[1]
    test -z $n; and set n 12
    # https://en.wikipedia.org/wiki/Birthday_problem#Probability_table
    dd if=/dev/urandom bs=1 count=1024 2>/dev/null | md5sum - | cut -b -$n
end

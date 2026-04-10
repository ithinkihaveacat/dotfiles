function randomhex -d "Generate random hexadecimal string"
    set -l n $argv[1]
    test -z $n; and set n 12
    # https://en.wikipedia.org/wiki/Birthday_problem#Probability_table
    openssl rand -hex $n | cut -c -$n
end

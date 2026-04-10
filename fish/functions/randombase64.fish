function randombase64 -d "Generate random base64 string"
    set -l n $argv[1]
    test -z $n; and set n 16
    # https://en.wikipedia.org/wiki/Birthday_problem#Probability_table
    openssl rand -base64 $n | tr -d "[/+=\n]" | cut -c -$n
end

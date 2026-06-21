function randompw -d "Generate random password using pwgen"
    set -l n $argv[1]
    test -z $n; and set n 12
    pwgen -s -y -c -n -B -1 $n 1
end

function sourceif
    if test -r $argv[1]
        source $argv[1]
    end
end

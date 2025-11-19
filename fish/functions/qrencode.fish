function qrencode
    printf $argv | curl '-F-=<-' http://qrenco.de
end

function notify -a title -a body -d "Posts a notification using the native notification system"
    # If two arguments are provided, use OSC 777 (Title + Body)
    if count $argv >1
        printf "\033]777;notify;%s;%s\033\\" $argv[1] $argv[2]

        # If only one argument is provided, use OSC 9 (Message only)
    else if count $argv >0
        printf "\033]9;%s\033\\" $argv[1]

    else
        printf "Usage: %s [title] <message>" (status current-command)
    end
end

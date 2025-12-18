function pbpaste
    if not __fish_is_remote
        if type -q pbpaste
            command pbpaste
            return
        end
    end

    return 1
end

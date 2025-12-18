function __fish_is_remote
    if set -q SSH_TTY; or set -q SSH_CLIENT; or set -q SHPOOL_SESSION_NAME
        return 0 # True
    end

    # Specific check for your setup: Linux usually means remote for you
    if test (uname) = Linux
        return 0
    end

    return 1 # False
end

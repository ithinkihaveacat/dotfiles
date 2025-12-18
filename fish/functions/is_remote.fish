function is_remote --description 'Test if running in a remote session'
    set -q SSH_CONNECTION; or set -q SSH_TTY; or set -q SSH_CLIENT
    and return 0

    set -q SHPOOL_SESSION_NAME
    and return 0

    return 1
end

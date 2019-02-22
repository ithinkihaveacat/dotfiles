# See https://github.com/fish-shell/fish-shell/issues/825#issuecomment-440286038;
# get the current version via "type up-or-search".
function up-or-search --description 'Depending on cursor position and current mode, either search backward or move up one line'

    if commandline --search-mode
        commandline -f history-search-backward
        return
    end

    # If we are navigating the pager, then up always navigates
    if commandline --paging-mode
        commandline -f up-line
        return
    end

    # We are not already in search mode.
    # If we are on the top line, start search mode,
    # otherwise move up
    set lineno (commandline -L)

    switch $lineno
        case 1
            commandline -f history-search-backward
            history merge

        case '*'
            commandline -f up-line
    end
end

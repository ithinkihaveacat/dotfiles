# https://github.com/fish-shell/fish-shell/blob/master/share/functions/fish_git_prompt.fish

# PWD Settings
set -g fish_prompt_pwd_dir_length 1
set -g fish_prompt_pwd_full_dirs 3

# Transient prompts (hide right prompt on non-active lines) requires fish 4.1+
# fish 4.0.x does not support --final-rendering flag
set -l version_parts (string split . $FISH_VERSION) 0 0
set -l major $version_parts[1]
set -l minor $version_parts[2]

if test $major -gt 4; or test $major -eq 4 -a $minor -ge 1
    set -g fish_transient_prompt 1
end

# Git Logic
set -g __fish_git_prompt_showupstream auto
set -g __fish_git_prompt_showstashstate yes
set -g __fish_git_prompt_show_informative_status yes

# Git Characters (Customizing the look)
set -g __fish_git_prompt_char_stateseparator ' '
set -g __fish_git_prompt_char_cleanstate "✔"
set -g __fish_git_prompt_color_cleanstate --bold white

function fish_prompt --description 'Write out the prompt'
    set -l last_status $status

    set_color blue
    printf "%s\n" (prompt_pwd)

    if test $last_status -eq 0
        set_color white
    else
        set_color red
    end
    echo -n "\$ "

    set_color normal
end

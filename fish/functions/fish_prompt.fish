# https://github.com/fish-shell/fish-shell/blob/master/share/functions/fish_git_prompt.fish

# PWD Settings
set fish_prompt_pwd_dir_length 1
set fish_prompt_pwd_full_dirs 3

# Transient prompts (hide right prompt on non-active lines) requires fish 4.1+
# fish 4.0.x does not support --final-rendering flag
set -l version_parts (string split . $FISH_VERSION) 0 0
set -l major $version_parts[1]
set -l minor $version_parts[2]

if test $major -gt 4; or test $major -eq 4 -a $minor -ge 1
    set fish_transient_prompt 1
end

# Git Logic
set __fish_git_prompt_showupstream auto
set __fish_git_prompt_showstashstate yes
set __fish_git_prompt_show_informative_status yes

# Git Characters (Customizing the look)
set __fish_git_prompt_char_stateseparator ' '
set __fish_git_prompt_char_cleanstate "✔"
set __fish_git_prompt_color_cleanstate --bold white
#set __fish_git_prompt_char_dirtystate '*'     # Overrides default ✚
#set __fish_git_prompt_char_stagedstate '⇢'    # Overrides default ●

# Git Characters
#set __fish_git_prompt_char_dirtystate '*'
#set __fish_git_prompt_char_stagedstate '⇢'
#set __fish_git_prompt_char_upstream_prefix ' '
#set __fish_git_prompt_char_upstream_equal ''
#set __fish_git_prompt_char_upstream_ahead '⇡'
#set __fish_git_prompt_char_upstream_behind '⇣'
#set __fish_git_prompt_char_upstream_diverged '⇡⇣'

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

function fish_right_prompt --description 'Write out the right prompt'

    if not contains -- --final-rendering $argv

        if is_remote
            set_color $fish_color_ssh
            printf "@%s " (prompt_hostname)
            set_color normal
        end

        if __fish_is_git_repository
            set_color yellow
            basename (git rev-parse --show-toplevel)
            set_color normal
            echo -n " "
            __fish_git_prompt "%s"
        end

    end

end

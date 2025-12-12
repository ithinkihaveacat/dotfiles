set fish_prompt_pwd_dir_length 1
set fish_prompt_pwd_full_dirs 3
set fish_transient_prompt 1

# https://github.com/fish-shell/fish-shell/blob/master/share/functions/fish_git_prompt.fish
set __fish_git_prompt_showupstream auto
set __fish_git_prompt_showstashstate yes
set __fish_git_prompt_showdirtystate yes
set __fish_git_prompt_use_informative_chars yes

# Git Characters
set __fish_git_prompt_char_dirtystate '*'
set __fish_git_prompt_char_stagedstate '⇢'
set __fish_git_prompt_char_upstream_prefix ' '
set __fish_git_prompt_char_upstream_equal ''
set __fish_git_prompt_char_upstream_ahead '⇡'
set __fish_git_prompt_char_upstream_behind '⇣'
set __fish_git_prompt_char_upstream_diverged '⇡⇣'

function fish_prompt --description 'Write out the prompt'

    set_color blue
    echo -n (prompt_pwd)
    echo -n " "

    if test $status -eq 0
        set_color white
    else
        set_color red
    end
    echo -n "\$ "

    set_color normal

end

function fish_right_prompt --description 'Write out the right prompt'

    if not contains -- --final-rendering $argv

        if test -n "$SSH_CONNECTION"
            set_color $fish_color_ssh
            printf "@%s " (string replace -r '[\.|\-].*' '' (string lower $hostname))
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

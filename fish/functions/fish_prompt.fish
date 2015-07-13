function fish_prompt --description 'Write out the prompt'

    # Use after set_color to reset bold
    if not set -q __fish_prompt_color_normal
        set -g __fish_prompt_color_normal (set_color normal)
    end

    if not set -q __fish_prompt_color_hostname
        set -g __fish_prompt_color_hostname (set_color -o $fish_color_hostname)
    end

    if not set -q __fish_prompt_color_cwd
        set -g __fish_prompt_color_cwd (set_color $fish_color_cwd)
    end

    if not set -q __fish_prompt_color_git
        set -g __fish_prompt_color_git (set_color $fish_color_git)
    end

    if not set -q __fish_prompt_hostname
        if test -d /etc/goobuntu
          set -g __fish_prompt_hostname (hostname -s|cut -d \- -f 1)@goobuntu
        else if begin ; hostname | grep -q syd ; end
          set -g __fish_prompt_hostname syd@gandi
        else
          set -g __fish_prompt_hostname (hostname -s|cut -d \- -f 1|tr A-Z a-z)
        end
    end

    echo -n -s "$__fish_prompt_color_hostname" "$__fish_prompt_hostname" "$__fish_prompt_color_normal" ':' "$__fish_prompt_color_cwd" (prompt_pwd) "$__fish_prompt_color_git" (__fish_git_prompt "#%s") "$__fish_prompt_color_normal" '$ '

end

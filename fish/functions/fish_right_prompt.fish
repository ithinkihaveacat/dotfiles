function fish_right_prompt --description 'Write out the right prompt'
    if not contains -- --final-rendering $argv
        if is_remote
            set_color $fish_color_ssh
            printf "@%s " (prompt_hostname)
            set_color normal
        end

        if __fish_is_git_repository
            set -l toplevel (git rev-parse --show-toplevel 2>/dev/null)
            if test -n "$toplevel"
                set -l prefix ""
                # Fast path: Check env variables first
                set -l resolved_email $GIT_AUTHOR_EMAIL
                if test -z "$resolved_email"
                    # Fallback to git config
                    set resolved_email (command git config user.email 2>/dev/null)
                end
                if test -n "$resolved_email"; and test "$resolved_email" != "mjs@beebo.org"
                    set prefix "💼 "
                end

                set_color yellow
                printf "%s%s" "$prefix" (string replace -r '^.*/' '' $toplevel)
                set_color normal
                echo -n " "
            end
            __fish_git_prompt "%s"
        end
    end
end

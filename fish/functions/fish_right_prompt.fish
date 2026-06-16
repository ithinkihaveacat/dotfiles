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
                # Sparkle only when skills are managed AND skill doctor last
                # verified them healthy (cache written by _agent_preflight at
                # agent launch). Absence of the sparkle is the neutral default.
                if _skill_is_managed "$toplevel"; and _skill_doctor_fresh_ok "$toplevel"
                    set prefix "✨ "
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

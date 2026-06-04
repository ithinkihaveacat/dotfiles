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
                set -l exclude_file "$toplevel/.git/info/exclude"
                if not test -f "$exclude_file"
                    set exclude_file (git rev-parse --git-path info/exclude 2>/dev/null)
                end
                if test -f "$exclude_file"
                    if string match -q -r "skills \\(managed by 'git-skill'\\)" <"$exclude_file"
                        set -l managed_skills (string replace -r '^/\.(claude|agents)/skills/([^/]+)$' '$2' <"$exclude_file" | string match -r '^[^/#]+$')
                        set -l unique_skills (printf '%s\n' $managed_skills | sort -u | string match -r '\S+')
                        set -l skill_count (count $unique_skills)
                        if test $skill_count -gt 0
                            set prefix "✨ "
                        end
                    end
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

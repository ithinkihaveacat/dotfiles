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
    # once fish 2.5 is everywhere, use prompt_hostname here
    if test -d /etc/goobuntu
      set -g __fish_prompt_hostname goobuntu
    else if begin ; hostname | grep -q syd ; end
      set -g __fish_prompt_hostname syd@gandi
    else
      set -g __fish_prompt_hostname (hostname -s|cut -d \- -f 1|tr A-Z a-z)
    end
  end

  # If commands takes longer than 10 seconds, notify user on completion
  # https://github.com/jml/undistract-me/issues/32
  if test $CMD_DURATION
    if test $CMD_DURATION -gt (math "1000 * 10")
      # tmp so that an empty frontmost-tty results in an empty string; see
      # https://github.com/fish-shell/fish-shell/issues/159
      set tmp (frontmost-tty)
      if test "$tmp" != (tty)
        set secs (math "$CMD_DURATION / 1000")
        # It's not possible to raise the window via the notifcation; see
        # https://stackoverflow.com/a/33808356
        notify "$history[1]" "(status $status; $secs secs)"
      end
    end
  end

  echo -n -s "$__fish_prompt_color_hostname" "$__fish_prompt_hostname" "$__fish_prompt_color_normal" ':' "$__fish_prompt_color_cwd" (prompt_pwd) "$__fish_prompt_color_git" (__fish_git_prompt "#%s") "$__fish_prompt_color_normal" '$ '

end

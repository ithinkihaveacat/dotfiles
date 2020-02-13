set fish_prompt_pwd_dir_length 0

# https://github.com/fish-shell/fish-shell/blob/master/share/functions/fish_git_prompt.fish
set __fish_git_prompt_showupstream "auto"
set __fish_git_prompt_showstashstate "yes"
set __fish_git_prompt_showdirtystate "yes"
set __fish_git_prompt_use_informative_chars "yes"

# Git Characters
set __fish_git_prompt_char_dirtystate '*'
set __fish_git_prompt_char_stagedstate '⇢'
set __fish_git_prompt_char_upstream_prefix ' '
set __fish_git_prompt_char_upstream_equal ''
set __fish_git_prompt_char_upstream_ahead '⇡'
set __fish_git_prompt_char_upstream_behind '⇣'
set __fish_git_prompt_char_upstream_diverged '⇡⇣'

set __fish_prompt_hostname (string replace -r '[\.|\-].*' '' (string lower $hostname))
set __fish_prompt_username $USER

function _print
  set -l string $argv[1]
  set -l color  $argv[2]

  set_color $color
  printf $string
  set_color normal
end

function _prompt_color
  if test $argv[1] -eq 0
    echo white
  else
    echo red
  end
end

function fish_prompt --description 'Write out the prompt'

  set -l last_status $status

  # If commands takes longer than 10 seconds, notify user on completion if Terminal
  # in background. (Otherwise e.g. reading man pages for longer than 10 seconds will
  # trigger the notification.) Inspired by https://github.com/jml/undistract-me/issues/32.
  if test $CMD_DURATION
    if test $CMD_DURATION -gt 10000
      if not terminal-frontmost
        set secs (math "$CMD_DURATION / 1000")
        # It's not possible to raise the window via the notification; see
        # https://stackoverflow.com/a/33808356
        notify "$history[1]" "(status $status; $secs secs)"
      end
    end
  end

  _print "\n" # TODO: not the first time

  if test -n "$SSH_CONNECTION"
    _print "$__fish_prompt_username"@"$__fish_prompt_hostname" $fish_color_ssh
    _print : white
  end

  _print (prompt_pwd) blue
  __fish_git_prompt " %s"
  _print "\n❯ " (_prompt_color $last_status)

end

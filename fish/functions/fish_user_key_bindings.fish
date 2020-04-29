function fish_user_key_bindings
  bind \033f nextd-or-forward-word
  bind \033b prevd-or-backward-word
  if type -q brew
    and type -q fzf
	source (brew --prefix)/opt/fzf/shell/key-bindings.fish
	fzf_key_bindings
  end
end

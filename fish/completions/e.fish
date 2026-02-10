# Complete with fish function names
complete -c e -a "(functions -n)"

# Complete with scripts from dotfiles bin directory
# (Filtering text files across all of PATH would be too slow)
complete -c e -a "(printf '%s\n' $HOME/.dotfiles/bin/* 2>/dev/null | xargs -n1 basename 2>/dev/null)"

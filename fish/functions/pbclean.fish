function pbclean
    pbpaste | sed -E 's/"data:[^"]*"/""/g' | string replace --all (printf '\u00a0') ' ' | string replace --all -r '\[cite[^]]*]' '' | string replace --all -- --- '' | pbcopy
end

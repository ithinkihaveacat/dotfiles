function pbclean
    pbpaste | grep -v "data:image/png;base64," | string replace --all (printf '\u00a0') ' ' | string replace --all -r '\[cite[^]]*]' '' | string replace --all -- '---' '' | pbcopy
end

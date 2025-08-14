function pbclean
    pbpaste | grep -v "data:image/png;base64," | string replace --all (printf '\u00a0') ' ' | string replace -a -r '\[cite[^]]*]' '' | pbcopy
end

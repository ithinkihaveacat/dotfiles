function pbclean
    pbpaste | sed -E -e '/^\[image[0-9]+\]: <data:image\//d' -e 's/"data:[^"]*"/""/g' | string replace --all (printf '\u00a0') ' ' | string replace --all -r '\[cite[^]]*]' '' | string replace --all -- --- '' | pbcopy
end

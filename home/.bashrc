# Start fish if shell is bash, but is interactive, and fish is
# available. (This is useful if it's not possible/advisable to change
# the shell at system level to fish.)

FISH=$(which fish)

if echo $- | grep -q 'i' && [[ -x $FISH ]] && [[ $SHELL != $FISH ]]; then
  exec env SHELL=$FISH $FISH -i
fi

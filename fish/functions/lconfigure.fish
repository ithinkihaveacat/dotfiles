function lconfigure -d "./configure and install into $HOME/local and $LOCAL"
    ./configure --prefix=$HOME/local $argv
end

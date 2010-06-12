# -*- sh -*-

OS='unix'
PLATFORM=`"$HOME/.platform"`
HOSTNAME=`hostname | tr '.' ' ' | awk '{ print $1 }'`

# Source the parameter, if it exists

function sourceif {
    if [ -f "$1" ]; then
        source "$1"
    fi
}  

sourceif "$HOME/.bashrc"

sourceif "$CONFIG/$OS/login"
sourceif "$CONFIG/$OS/$PLATFORM/login"
sourceif "$CONFIG/$OS/$PLATFORM/$HOSTNAME/login"

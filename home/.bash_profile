# -*- sh -*-

export CONFIGROOT=${CONFIGROOT:-$(dirname $(dirname $(readlink $BASH_SOURCE)))}

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

sourceif "$CONFIGROOT/$OS/login"
sourceif "$CONFIGROOT/$OS/$PLATFORM/login"
sourceif "$CONFIGROOT/$OS/$PLATFORM/$HOSTNAME/login"

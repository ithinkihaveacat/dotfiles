# -*- sh -*-

export OS='unix'
export PLATFORM=$($HOME/.platform)
export HOSTNAME=$(hostname | tr '.' ' ' | awk '{ print $1 }')

# Ensure $READLINK returns absolute path

case $PLATFORM in

  darwin)
    READLINK="readlink"
    ;;
    
  *)
    READLINK="readlink -f"
    ;;
    
esac

export CONFIGROOT=${CONFIGROOT:-$(dirname $(dirname $($READLINK $BASH_SOURCE)))}

# @TODO Figure out why $READLINK gets exported, and stop that from happening

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

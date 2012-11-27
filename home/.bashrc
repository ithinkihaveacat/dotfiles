# -*- sh -*-

export OS=${OS:-'unix'}
export PLATFORM=${PLATFORM:-$($HOME/.platform)}
export HOSTNAME=${HOSTNAME:-$(hostname | tr '.' ' ' | awk '{ print $1 }')}

# Ensure $READLINK returns absolute path

case $PLATFORM in

  darwin)
    READLINK="greadlink -f"
    ;;
    
  *)
    READLINK="readlink -f"
    ;;
    
esac

export CONFIGROOT="${CONFIGROOT:-$(dirname $(dirname $($READLINK $BASH_SOURCE)))}"

# @TODO Figure out why $READLINK gets exported, and stop that from happening

# set this early, because often used in setting the path
export LOCAL="$HOME/local-$PLATFORM"

export PATH0
export PATH1=$PATH

# Source the parameter, if it exists
function sourceif {
    if [ -f "$1" ]; then
        source "$1"
    fi
}

# Returns colon-separated string; $(makepath foo bar) -> foo:bar 
function makepath {
    local IFS=:
    echo "$*"
}    

# Set path

sourceif "$CONFIGROOT/$OS/path"
sourceif "$CONFIGROOT/$OS/$PLATFORM/path"
sourceif "$CONFIGROOT/$OS/$PLATFORM/$HOSTNAME/path"

export PATH=$(makepath $PATH0 $PATH1)

# Set general options

sourceif "$CONFIGROOT/$OS/$PLATFORM/$HOSTNAME/begin"

sourceif "$CONFIGROOT/$OS/config"
sourceif "$CONFIGROOT/$OS/$PLATFORM/config"
sourceif "$CONFIGROOT/$OS/$PLATFORM/$HOSTNAME/config"

# Set application-specific/conditional options

for p in $CONFIGROOT/programs/* ; do

  if type -t $(basename $p) >/dev/null ; then
    source $p
  fi

done  

# Set path again (potentially modified by programs/*)

export PATH=$(makepath $PATH0 $PATH1)

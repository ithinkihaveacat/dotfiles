# -*- sh -*-

export CONFIGROOT=${CONFIGROOT:-$(dirname $(dirname $(readlink $BASH_SOURCE)))}

export OS='unix'
export PLATFORM=`"$HOME/.platform"`
export HOSTNAME=`hostname | tr '.' ' ' | awk '{ print $1 }'`
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

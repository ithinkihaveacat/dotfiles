# -*- sh -*-

export CONFIGROOT=${CONFIGROOT:-$(dirname $(dirname $(readlink $BASH_SOURCE)))}

export OS='unix'
export PLATFORM=`"$HOME/.platform"`
export HOSTNAME=`hostname | tr '.' ' ' | awk '{ print $1 }'`
# set this early, because often used in setting the path
export LOCAL="$HOME/local-$PLATFORM"

# Source the parameter, if it exists

function sourceif {
    if [ -f "$1" ]; then
        source "$1"
    fi
}  

# Set path

if [ -z "$PATH_SET" ]; then

    sourceif "$CONFIGROOT/$OS/path"
    sourceif "$CONFIGROOT/$OS/$PLATFORM/path"
    sourceif "$CONFIGROOT/$OS/$PLATFORM/$HOSTNAME/path"

    export PATH="$LPATH:$PATH"

    export PATH_SET="y"  

fi

# Set other options

sourceif "$CONFIGROOT/$OS/$PLATFORM/$HOSTNAME/begin"

sourceif "$CONFIGROOT/$OS/config"
sourceif "$CONFIGROOT/$OS/$PLATFORM/config"
sourceif "$CONFIGROOT/$OS/$PLATFORM/$HOSTNAME/config"

# For each program that exists, create special configuration

for p in $CONFIGROOT/programs/* ; do

  if [ -d $p ]; then
    continue
  fi
  
  if ( which $(basename $p) >/dev/null ); then
    source $p
  fi

done  

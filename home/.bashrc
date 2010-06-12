# -*- sh -*-

export CONFIG="$HOME/.config"

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

    sourceif "$CONFIG/$OS/path"
    sourceif "$CONFIG/$OS/$PLATFORM/path"
    sourceif "$CONFIG/$OS/$PLATFORM/$HOSTNAME/path"

    export PATH="$LPATH:$PATH"

    export PATH_SET="y"  

fi

# Set other options

sourceif "$CONFIG/$OS/$PLATFORM/$HOSTNAME/begin"

sourceif "$CONFIG/$OS/config"
sourceif "$CONFIG/$OS/$PLATFORM/config"
sourceif "$CONFIG/$OS/$PLATFORM/$HOSTNAME/config"

# For each program that exists, create special configuration

for p in $CONFIG/programs/* ; do

  if [ -d $p ]; then
    continue
  fi
  
  if ( which $(basename $p) >/dev/null ); then
    source $p
  fi

done  

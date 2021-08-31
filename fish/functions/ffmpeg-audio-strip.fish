# -*- sh -*-

# doesn't work as expected because can't figure out a way to force
# ffmpeg to use particular format for output (instead of inferring from
# filename)

function ffmpeg-audio-strip -d "Removes audio from video"

  if test ( count $argv ) -eq 0
    printf "usage: %s file\n" (status current-command)
    return
  end
  
  # The temporary filename handling part of this comes from psub.fish

  set -l tmpdir /tmp
  set -q TMPDIR && set tmpdir $TMPDIR
  
  set filename (mktemp (printf "%s/.%s.XXXXXXXXXX" $tmpdir (status current-command)))
  
  echo $filename

  ffmpeg -y -i $argv[1] -c copy -an -codec copy $filename && mv $filename $argv[1]

  # Find unique function name
  while true
      set funcname __fish_psub_(random)
      if not functions $funcname >/dev/null 2>/dev/null
          break
      end
  end

  # Make sure we erase file when caller exits
  function $funcname --on-job-exit caller --inherit-variable filename --inherit-variable funcname
      command rm $filename
      functions -e $funcname
  end
  
end

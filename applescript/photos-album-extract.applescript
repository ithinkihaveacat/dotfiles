#!/usr/bin/env osascript

-- Usage:
--
--   $ photos-album-extract Christmas
--
-- Returns the filenames of the photos in album "Christmas".

on run argv
	tell application "Photos"
	  if length of argv is 0
		  log "usage: photos-album-extract album"
			return
		end if
		set src to item 1 of argv
		try
			count of every media item of album src
		on error
			log "error: Photos.app not ready, or album " & src & " does not exist"
		end try
		repeat with f in every media item of album src
			log ((filename of f) as string)
		end repeat
	end tell
end run

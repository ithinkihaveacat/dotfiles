#!/usr/bin/env osascript

-- For every photo in album "Src" with keyword "Stack Pick", add every photo
-- with exactly the same date to the album "Dst". This script does not delete anything:
-- the idea is that you "Dst" to see if the results are as expected, and
-- delete the photos via the GUI if necessary.

-- I'm using this to remove non "Stack Picks" from my albums. (Aperture supported
-- stacks, but Photos doesn't--when imported, all the stacks were mashed together.)

-- NOTE: Photos' AppleScript support is very temperamental: make sure Photos is
-- running before starting this script, and if you get errors, try resolving them
-- by restarting Photos. Also, run this on "small" albums first (less than 100
-- photos). Basically, I'm not at all comfortable that this script will
-- always behave properly: be careful & take backups!

-- Open with Script Editor for syntax highlighting, better debugging, etc.

-- Extracting metadata from photos takes a really long time, so we do this
-- once and then use the cached results, instead of in the nested loops below.
using terms from application "Photos"
	on AlbumMetadata(c)
		set l to {}
		repeat with f in every media item of c
			set end of l to {item:f, keywords:keywords of f, filename:filename of f, date:date of f, id:id of f}
		end repeat
		return l
	end AlbumMetadata
end using terms from

tell application "Photos"
	
	set src to "Src"
	set dst to "Dst"
	
	try
		count of every media item of container src
		count of every media item of container dst
	on error
		log "error: Photos.app not ready, or album " & src & " or " & dst & " does not exist"
		return
	end try
	
	log "Processing " & (count of every media item of container src) & " photos in album " & src
	
	log "Collecting metadata ..."
	set metadata to my AlbumMetadata(container src) -- not sure why we need to do "container" in the caller but whatevs...
	log "... done!"
	
	set picks to {}
	repeat with f in metadata
		if keywords of f contains "Stack Pick" then
			set end of picks to f
		end if
	end repeat
	
	set other to {}
	repeat with f in picks
		repeat with g in metadata
			if (date of g is date of f) and (id of g is not id of f) then
				log (filename of g) & " is a duplicate of stack pick " & (filename of f)
				set end of other to (item of g)
				exit repeat
			end if
		end repeat
	end repeat
	
	log "Adding " & (count of other) & " photos to album " & dst & " ..."
	add other to container dst
	log "... done!"
	
end tell

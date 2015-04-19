#!/usr/bin/env osascript

on ReverseString(s)
	return (reverse of (characters of s) as string)
end ReverseString

-- not quite the standard basename(): strips off the extension no matter what
on Basename(s)
	if not (offset of "." in s) = 0 then
		set s to ReverseString(s)
		set s to text ((offset of "." in s) + 1) thru -1 of s
		set s to ReverseString(s)
	end if
	return s
end Basename

on Realpath(s)
	try
		set a to alias (POSIX file s) -- throw error if doesn't exist
	on error
		return ""
	end try
	return POSIX path of a
end Realpath

on run argv
	tell application "Image Events"
		launch
		repeat with f in argv
			set src to my Realpath(f)
			if src is "" then
				exit repeat
			end if
			set dst to ((my Basename(src)) & ".jpg")
			set img to open ((POSIX file src) as string)
			save img as JPEG in dst with compression level high
			log "Converted " & src & " to " & dst
		end repeat
	end tell
end run

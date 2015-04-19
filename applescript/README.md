## About

Some random AppleScript scripts.

## Tips

Check for existence of a file:

```
-- not quite right (doesn't work with relative paths)
-- e.g. log FileExists("foo.txt")
on FileExists(f)
 tell application "System Events"
   return exists file f
 end tell
end FileExists
```

Need the current working directory?

```
set pwd to do shell script "pwd"
```

Files, aliases, and converting between Unix-style and Apple-style paths is ... weird. See <https://developer.apple.com/library/mac/documentation/AppleScript/Conceptual/AppleScriptLangGuide/conceptual/ASLR_fundamentals.html#//apple_ref/doc/uid/TP40000983-CH218-SW28>

(Note that this is a (POSIX path ...) command as well as (POSIX file ...).)

Use "log" to dump output for debugging

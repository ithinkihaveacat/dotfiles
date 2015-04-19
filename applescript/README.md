## About

Some random AppleScript scripts.

## Tips

Need the current working directory?

```
set pwd to do shell script "pwd"
```

Create file object from Unix-style path (with "/"):

```
(POSIX file unixpath)
```

Get Unix-style path from a file object:

```
(POSIX path file)
```

See:

* <https://developer.apple.com/library/mac/documentation/AppleScript/Conceptual/AppleScriptLangGuide/conceptual/ASLR_fundamentals.html#//apple_ref/doc/uid/TP40000983-CH218-SW28>
* <http://www.satimage.fr/software/en/smile/external_codes/file_paths.html>

How to debug?

* Use "log" to dump output for debugging.
* Though note that sometimes different types are coerced into string
for output; compare `log obj` and `log class of obj` if not sure.

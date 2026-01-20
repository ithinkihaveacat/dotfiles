function pbclean
    # Ensure clipboard contains text
    if not osascript -e 'clipboard info' | string match -q -r '«class utf8»|string|Unicode text'
        echo "pbclean: No text in clipboard" >&2
        return 1
    end

    # Capture clipboard content into a variable (binary safe-ish)
    set -l content_in (pbpaste | string collect --no-trim-newline)
    set -l size_in (printf '%s' "$content_in" | wc -c | string trim)

    if test $size_in -eq 0
        echo "pbclean: Clipboard empty" >&2
        return
    end

    # Process content using perl for robust UTF-8 and cross-platform handling
    set -l content_out (printf '%s' "$content_in" | perl -CSD -pe '
        if (/^\[image\d+\]: <data:image\//) { $_ = ""; next; }
        s/"data:[^"]*"/""/g;
        s/\x{00A0}/ /g;
        s/\[cite[^\]]*\]//g;
        s/ ?\(\[source\]\(http[^)]+\)\)//g;
        s/---//g;
    ' | string collect --no-trim-newline)

    set -l size_out (printf '%s' "$content_out" | wc -c | string trim)

    # Copy the cleaned content back to clipboard (use 'command' to call the
    # system pbcopy directly, avoiding the fish function wrapper)
    printf '%s' "$content_out" | command pbcopy

    # Calculate and report statistics
    set -l diff (math $size_in - $size_out)

    if test $size_in -gt 0
        set -l percent (math "$diff / $size_in * 100")
        printf "pbclean: Reduced by %d bytes (%.1f%%)\n" $diff $percent >&2
    end
end

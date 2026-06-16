# True when the cached skill-doctor result for a repo is healthy and fresh.
#
# Usage: _skill_doctor_fresh_ok TOPLEVEL
#
# Reads the cache file written by _agent_preflight: content must be "ok" and the
# file's mtime must be within the TTL (default 24h, override with the
# `skill_doctor_ttl` variable, in seconds). Returns 0 if fresh-and-ok, else 1.
# This is the only thing fish_right_prompt consults; it never runs the check.
function _skill_doctor_fresh_ok --description 'True if skill-doctor cache for a repo is ok and fresh' --argument-names toplevel
    test -n "$toplevel"; or return 1

    set -l cache_file (_skill_cache_file "$toplevel")
    test -f "$cache_file"; or return 1
    test (cat "$cache_file" 2>/dev/null) = ok; or return 1

    set -l ttl 86400
    set -q skill_doctor_ttl; and set ttl $skill_doctor_ttl

    # mtime: BSD/macOS stat first, GNU/Linux stat as fallback.
    set -l mtime (stat -f %m "$cache_file" 2>/dev/null; or stat -c %Y "$cache_file" 2>/dev/null)
    test -n "$mtime"; or return 1

    test (math (date +%s) - $mtime) -lt $ttl
end

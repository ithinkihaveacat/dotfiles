function getmarkdown -w curl -d "Retrieve URL as Markdown, output to stdout"
    if test "$argv[1]" = --help
        echo "Usage: getmarkdown URL

Retrieve a URL as Markdown, output to stdout.

Tries the Accept: text/markdown HTTP header first (supported by Cloudflare-
hosted sites, among others). Falls back to the Jina Reader API (r.jina.ai)
if the server does not return Markdown.

Arguments:
  URL         The URL to fetch as Markdown

Options:
  --help      Display this help message and exit

Examples:
  getmarkdown https://www.home-assistant.io/blog/2026/04/01/release-20264/
  getmarkdown https://example.com/article | head -20
  getmarkdown https://docs.cloudflare.com/workers/ > workers.md"
        return 0
    end

    if test (count $argv) -eq 0
        echo "getmarkdown: URL required" >&2
        echo "Try 'getmarkdown --help' for more information." >&2
        return 1
    end

    set -l url $argv[1]

    # Strategy 1: Request text/markdown via Accept header (Cloudflare et al.)
    set -l tmpfile (mktemp)
    set -l headers (curl -sSL -D - -o "$tmpfile" -H "Accept: text/markdown" "$url" 2>/dev/null | string collect)
    set -l curl_status $status

    if test $curl_status -eq 0
        # Check if server actually returned markdown
        set -l content_type (echo "$headers" | string match -ri '^content-type:.*text/markdown')
        if test -n "$content_type"
            cat "$tmpfile"
            rm -f "$tmpfile"
            return 0
        end
    end
    rm -f "$tmpfile"

    # Strategy 2: Jina Reader API (JSON mode, extract content field)
    set -l jina_output (curl -sSL -H "Accept: application/json" "https://r.jina.ai/$url" 2>/dev/null)
    if test $status -eq 0 -a -n "$jina_output"
        set -l markdown (echo "$jina_output" | jq -r '.data.content // empty')
        if test -n "$markdown"
            echo "$markdown"
            return 0
        end
    end

    # Both strategies failed
    echo "getmarkdown: failed to retrieve markdown for $url" >&2
    return 1
end

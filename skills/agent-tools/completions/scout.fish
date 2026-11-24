# Fish completion for scout
complete -c scout -l model -x -d "Gemini model to use (default: gemini-3.5-flash-lite)"
complete -c scout -l urls-only -d "Print only unwrapped source URLs (one per line)"
complete -c scout -l json -d "Output JSON with answer, sources, queries, and usage"
complete -c scout -l no-resolve -d "Keep raw grounding redirect URIs instead of unwrapping 302s"
complete -c scout -l timeout -x -d "API request timeout in seconds (default: 60)"
complete -c scout -s q -l quiet -d "Suppress the stderr summary footer"
complete -c scout -s h -l help -d "Show this help message and exit"

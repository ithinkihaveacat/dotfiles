#!/usr/bin/env bash
#
# agy-statusline.sh - Custom status line script for Antigravity CLI.
#
# Displays real-time session metrics: agent state, host, conversation summary,
# context window remaining, active model, and background tasks.
#
# Installation:
#   1. Using CLI slash command (interactive):
#        /statusline ~/.dotfiles/etc/agents/agy-statusline.sh
#      or symlinked to standard location:
#        ln -sf ~/.dotfiles/etc/agents/agy-statusline.sh ~/.gemini/antigravity-cli/statusline.sh
#        /statusline ~/.gemini/antigravity-cli/statusline.sh
#
#   2. Or add to settings.json (~/.gemini/antigravity-cli/settings.json):
#      "statusLine": {
#        "type": "command",
#        "command": "~/.dotfiles/etc/agents/agy-statusline.sh",
#        "padding": 0,
#        "enabled": true
#      }
#
# Documentation:
#   - Public: https://antigravity.google/docs/cli/statusline
#

set -euo pipefail

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Custom status line script for Antigravity CLI.

Reads session JSON from standard input, formats real-time metrics (agent state,
hostname, conversation summary, context window remaining, and active model),
and outputs styled text for the TUI status bar.

Options:
  -h, --help  Display this help message and exit

Installation:
  1. Using CLI slash command:
       /statusline ~/.dotfiles/etc/agents/agy-statusline.sh

  2. Or configure in settings.json:
       "statusLine": {
         "type": "command",
         "command": "~/.dotfiles/etc/agents/agy-statusline.sh",
         "padding": 0,
         "enabled": true
       }

Documentation:
  Public: https://antigravity.google/docs/cli/statusline

Examples:
  # Test with mock session JSON
  echo '{"agent_state": "idle", "context_window": {"remaining_percentage": 94.2}}' | $(basename "$0")

  # Test with mock session JSON and conversation title
  echo '{"agent_state": "idle", "conversation_title": "Fix statusline", "context_window": {"remaining_percentage": 94.2}}' | $(basename "$0")
EOF
  exit 0
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
fi

require() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "$(basename "$0"): $1 not found" >&2
    exit 127
  }
}

require jq

# Color definitions (respects NO_COLOR standard: https://no-color.org)
if [[ -n "${NO_COLOR:-}" ]]; then
  C_RESET=""
  C_GREEN=""
  C_YELLOW=""
  C_CYAN=""
  C_MAGENTA=""
  C_RED=""
  C_BLUE=""
  C_DIM=""
  C_WHITE=""
else
  C_RESET="\033[0m"
  C_GREEN="\033[1;32m"
  C_YELLOW="\033[1;33m"
  C_CYAN="\033[1;36m"
  C_MAGENTA="\033[1;35m"
  C_RED="\033[1;31m"
  C_BLUE="\033[34m"
  C_DIM="\033[90m"
  C_WHITE="\033[37m"
fi

# Fallback values
STATE="idle"
TITLE=""
TRANSCRIPT_PATH=""
CONVERSATION_ID=""
CTX_REMAINING="100"
CTX_SIZE=""
TOTAL_IN=""
TOTAL_OUT=""
TOTAL_USD="0"
MODEL=""
TASKS="0"
SUBAGENTS="0"
CLIENT=""
COLS="80"

# Parse stdin JSON payload
if [[ ! -t 0 ]]; then
  PARSED_VARS=$(jq -r '
    def fmt_k:
      if . == null then ""
      elif . >= 1000000 then
        ((. / 1000000) * 10 | round / 10 | tostring | sub("\\.0$"; "")) + "M"
      elif . >= 10000 then
        ((. / 1000) | round | tostring) + "k"
      elif . >= 1000 then
        ((. / 1000) * 10 | round / 10 | tostring | sub("\\.0$"; "")) + "k"
      else tostring
      end;

    .context_window as $cw |
    [
      "STATE=" + ((.agent_state // "idle") | @sh),
      "TITLE=" + (((.conversation_title // .title // "") | gsub("[\\r\\n]+"; " ")) | @sh),
      "TRANSCRIPT_PATH=" + ((.transcript_path // "") | @sh),
      "CONVERSATION_ID=" + ((.conversation_id // .session_id // "") | @sh),
      "CTX_REMAINING=" + (((.context_window?.remaining_percentage // 100) | tostring) | @sh),
      "CTX_SIZE=" + (($cw.context_window_size | fmt_k) | @sh),
      "TOTAL_IN=" + (($cw.total_input_tokens | fmt_k) | @sh),
      "TOTAL_OUT=" + (($cw.total_output_tokens | fmt_k) | @sh),
      "TOTAL_USD=" + (((.cost?.total_usd // 0) | tostring) | @sh),
      "MODEL=" + ((.model?.display_name // .model?.id // "") | @sh),
      "TASKS=" + (((.task_count // 0) | tostring) | @sh),
      "SUBAGENTS=" + (((.subagents // [] | map(select(.status == "running")) | length) | tostring) | @sh),
      "CLIENT=" + ((.vcs?.client // .vcs?.branch // "") | @sh),
      "COLS=" + (((.terminal_width // 80) | tostring) | @sh)
    ] | join("\n")
  ' 2>/dev/null || true)

  if [[ -n "$PARSED_VARS" ]]; then
    eval "$PARSED_VARS"
  fi
fi

# 1. State badge
case "$STATE" in
  idle) STATE_BADGE="${C_GREEN}● READY${C_RESET}" ;;
  thinking) STATE_BADGE="${C_YELLOW}◆ THINKING${C_RESET}" ;;
  working) STATE_BADGE="${C_CYAN}WORKING${C_RESET}" ;;
  tool_use) STATE_BADGE="${C_MAGENTA}TOOL USE${C_RESET}" ;;
  reviewing) STATE_BADGE="${C_MAGENTA}REVIEWING${C_RESET}" ;;
  authenticating) STATE_BADGE="${C_YELLOW}AUTH${C_RESET}" ;;
  initializing) STATE_BADGE="${C_BLUE}INIT${C_RESET}" ;;
  error) STATE_BADGE="${C_RED}ERROR${C_RESET}" ;;
  *) STATE_BADGE="${C_WHITE}● ${STATE}${C_RESET}" ;;
esac

# 2. Host segment
HOST=$(hostname -s 2>/dev/null || hostname 2>/dev/null || echo "localhost")
HOST_SEGMENT="${C_BLUE}${HOST}${C_RESET}"

# 3. Conversation summary / title segment
# Fall back to resolving the session prompt from the transcript if title is not directly provided in the payload
if [[ -z "$TITLE" ]]; then
  if [[ -z "$TRANSCRIPT_PATH" && -n "$CONVERSATION_ID" ]]; then
    for candidate in \
      "$HOME/.gemini/jetski/brain/${CONVERSATION_ID}/.system_generated/logs/transcript.jsonl" \
      "$HOME/.gemini/antigravity/brain/${CONVERSATION_ID}/.system_generated/logs/transcript.jsonl"; do
      if [[ -r "$candidate" ]]; then
        TRANSCRIPT_PATH="$candidate"
        break
      fi
    done
  fi

  if [[ -n "$TRANSCRIPT_PATH" && -r "$TRANSCRIPT_PATH" ]]; then
    TITLE=$(head -n 5 "$TRANSCRIPT_PATH" 2>/dev/null | jq -s -r '
      map(select(.type == "USER_INPUT") | .content // "") | first // "" |
      gsub("<[^>]*>"; "") |
      split("\n") |
      map(gsub("^[[:space:]]+|[[:space:]]+$"; "") | gsub("[[:space:]]+"; " ")) |
      map(select(length > 0)) |
      first // ""
    ' 2>/dev/null || true)
  fi
fi

TITLE_SEGMENT=""
if [[ -n "$TITLE" ]]; then
  MAX_TITLE_LEN=32
  if [[ ${#TITLE} -gt $MAX_TITLE_LEN ]]; then
    TITLE="${TITLE:0:$((MAX_TITLE_LEN - 1))}…"
  fi
  TITLE_SEGMENT="${C_WHITE}${TITLE}${C_RESET}"
fi

# 4. Context window remaining segment: [REMAINING% SIZE · TOTAL_IN↑ TOTAL_OUT↓ · $X.XX]
CTX_REMAINING_FMT=$(printf "%.1f" "$CTX_REMAINING" 2>/dev/null || echo "$CTX_REMAINING")
CTX_REMAINING_INT="${CTX_REMAINING_FMT%.*}"
if [[ "${CTX_REMAINING_INT:-100}" -lt 20 ]]; then
  CTX_COLOR="$C_RED"
elif [[ "${CTX_REMAINING_INT:-100}" -lt 50 ]]; then
  CTX_COLOR="$C_YELLOW"
else
  CTX_COLOR="$C_GREEN"
fi

CTX_TEXT="${CTX_REMAINING_FMT}%"
if [[ -n "$CTX_SIZE" ]]; then
  CTX_TEXT="${CTX_TEXT} ${CTX_SIZE}"
else
  CTX_TEXT="${CTX_TEXT} left"
fi

TOTAL_TOKENS=""
if [[ -n "$TOTAL_IN" && -n "$TOTAL_OUT" ]]; then
  TOTAL_TOKENS=" · ${TOTAL_IN}↑ ${TOTAL_OUT}↓"
elif [[ -n "$TOTAL_IN" ]]; then
  TOTAL_TOKENS=" · ${TOTAL_IN}↑"
fi

COST_PART=""
TOTAL_USD_INT="${TOTAL_USD%.*}"
if [[ "${TOTAL_USD_INT:-0}" -ge 2 ]]; then
  COST_FMT=$(printf "%.2f" "$TOTAL_USD" 2>/dev/null || echo "$TOTAL_USD")
  COST_PART=" · ${C_YELLOW}\$${COST_FMT}${C_RESET}"
fi

CTX_SEGMENT="${CTX_COLOR}${CTX_TEXT}${C_DIM}${TOTAL_TOKENS}${C_RESET}${COST_PART}"

# 5. Model segment
MODEL_SEGMENT=""
if [[ -n "$MODEL" ]]; then
  MODEL_SEGMENT="${C_MAGENTA}${MODEL}${C_RESET}"
fi

# 6. Background tasks / subagents badge
BG_SEGMENT=""
TOTAL_BG=$((TASKS + SUBAGENTS))
if [[ $TOTAL_BG -gt 0 ]]; then
  BG_PARTS=()
  if [[ $TASKS -eq 1 ]]; then
    BG_PARTS+=("1 task")
  elif [[ $TASKS -gt 1 ]]; then
    BG_PARTS+=("${TASKS} tasks")
  fi
  if [[ $SUBAGENTS -eq 1 ]]; then
    BG_PARTS+=("1 agent")
  elif [[ $SUBAGENTS -gt 1 ]]; then
    BG_PARTS+=("${SUBAGENTS} agents")
  fi
  BG_TEXT=$(printf ", %s" "${BG_PARTS[@]}")
  BG_SEGMENT="${C_CYAN}${BG_TEXT:2}${C_RESET}"
fi

# 7. Repository / CitC workspace segment (mirrors fish_right_prompt)
REPO_SEGMENT=""
# If in a non-default CitC client, display it
if [[ -n "$CLIENT" && ! "$CLIENT" =~ ^.+-[a-z0-9]+-defaultclient$ ]]; then
  REPO_SEGMENT="${C_CYAN}${CLIENT}${C_RESET}"
elif GIT_TOPLEVEL=$(git rev-parse --show-toplevel 2>/dev/null); then
  REPO_NAME="${GIT_TOPLEVEL##*/}"
  REPO_SEGMENT="${C_YELLOW}${REPO_NAME}${C_RESET}"
fi

# Delimiter
SEP="${C_DIM}│${C_RESET}"

# Assemble segments based on available terminal width
PARTS=("$STATE_BADGE" "$HOST_SEGMENT")

if [[ -n "$TITLE_SEGMENT" ]]; then
  PARTS+=("$TITLE_SEGMENT")
fi

PARTS+=("$CTX_SEGMENT")

# On wider terminals (>= 110 columns), show all details
if [[ "${COLS:-80}" -ge 110 ]]; then
  if [[ -n "$MODEL_SEGMENT" ]]; then
    PARTS+=("$MODEL_SEGMENT")
  fi
  if [[ -n "$BG_SEGMENT" ]]; then
    PARTS+=("$BG_SEGMENT")
  fi
  if [[ -n "$REPO_SEGMENT" ]]; then
    PARTS+=("$REPO_SEGMENT")
  fi
elif [[ "${COLS:-80}" -ge 90 ]]; then
  if [[ -n "$MODEL_SEGMENT" ]]; then
    PARTS+=("$MODEL_SEGMENT")
  fi
  if [[ -n "$REPO_SEGMENT" ]]; then
    PARTS+=("$REPO_SEGMENT")
  fi
elif [[ "${COLS:-80}" -ge 80 ]]; then
  if [[ -n "$MODEL_SEGMENT" ]]; then
    PARTS+=("$MODEL_SEGMENT")
  fi
fi

# Print single-line status output
OUTPUT=""
for part in "${PARTS[@]}"; do
  if [[ -z "$OUTPUT" ]]; then
    OUTPUT=" $part"
  else
    OUTPUT="$OUTPUT $SEP $part"
  fi
done

printf "%b\n" "$OUTPUT"

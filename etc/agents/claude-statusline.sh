#!/usr/bin/env bash
#
# claude-statusline.sh - Custom status line script for Claude Code.
#
# Companion to agy-statusline.sh: displays the same segments (host, context
# window remaining, active model, repo) from Claude Code's statusline JSON
# schema. Claude Code exposes no agent state or background task fields, so
# those segments are omitted; the session title is omitted because Claude
# Code already shows it beside the input box.
#
# Installation:
#   1. Using CLI slash command (interactive):
#        /statusline ~/.dotfiles/etc/agents/claude-statusline.sh
#
#   2. Or add to settings.json (~/.claude/settings.json):
#      "statusLine": {
#        "type": "command",
#        "command": "~/.dotfiles/etc/agents/claude-statusline.sh",
#        "padding": 0
#      }
#
# Documentation:
#   - Public: https://code.claude.com/docs/en/statusline.md
#

set -euo pipefail

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Custom status line script for Claude Code.

Reads session JSON from standard input, formats real-time metrics (vim mode,
hostname, context window remaining, active model, repository, and 5-hour
rate limit), and outputs styled text for the statusline. The layout matches
agy-statusline.sh, minus the agent state and background task segments, which
Claude Code's payload does not provide.

Options:
  -h, --help  Display this help message and exit

Installation:
  1. Using CLI slash command:
       /statusline ~/.dotfiles/etc/agents/claude-statusline.sh

  2. Or configure in settings.json:
       "statusLine": {
         "type": "command",
         "command": "~/.dotfiles/etc/agents/claude-statusline.sh",
         "padding": 0
       }

Documentation:
  Public: https://code.claude.com/docs/en/statusline.md

Examples:
  # Test with mock session JSON
  echo '{"model":{"display_name":"Opus"},"context_window":{"remaining_percentage":94.2}}' | $(basename "$0")

  # Test with token counts and a wide terminal
  echo '{"model":{"display_name":"Opus"},"context_window":{"remaining_percentage":94.2,"context_window_size":200000,"total_input_tokens":11600,"total_output_tokens":800}}' | COLUMNS=120 $(basename "$0")
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
else
  C_RESET="\033[0m"
  C_GREEN="\033[1;32m"
  C_YELLOW="\033[1;33m"
  C_CYAN="\033[1;36m"
  C_MAGENTA="\033[1;35m"
  C_RED="\033[1;31m"
  C_BLUE="\033[34m"
  C_DIM="\033[90m"
fi

# Fallback values
CTX_REMAINING="100"
CTX_SIZE=""
TOTAL_IN=""
TOTAL_OUT=""
TOTAL_USD="0"
MODEL=""
EFFORT=""
AGENT_NAME=""
VIM_MODE=""
REPO_NAME=""
WORKTREE_NAME=""
RATE_5H_LEFT="-1"
PR_NUMBER=""
PR_STATE=""
COLS="${COLUMNS:-80}"

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

    (.context_window // {}) as $cw |
    [
      "CTX_REMAINING=" + ((($cw.remaining_percentage // 100) | tostring) | @sh),
      "CTX_SIZE=" + (($cw.context_window_size | fmt_k) | @sh),
      "TOTAL_IN=" + (($cw.total_input_tokens | fmt_k) | @sh),
      "TOTAL_OUT=" + (($cw.total_output_tokens | fmt_k) | @sh),
      "TOTAL_USD=" + (((.cost.total_cost_usd // 0) | tostring) | @sh),
      "MODEL=" + ((.model.display_name // .model.id // "") | @sh),
      "EFFORT=" + ((.effort.level // "") | @sh),
      "AGENT_NAME=" + ((.agent.name // "") | @sh),
      "VIM_MODE=" + ((.vim.mode // "") | @sh),
      "REPO_NAME=" + ((.workspace.repo.name // "") | @sh),
      "WORKTREE_NAME=" + ((.worktree.name // .workspace.git_worktree // "") | @sh),
      "RATE_5H_LEFT=" + (((.rate_limits.five_hour.used_percentage | if . == null then -1 else (100 - . | round) end) | tostring) | @sh),
      "PR_NUMBER=" + (((.pr.number // "") | tostring) | @sh),
      "PR_STATE=" + ((.pr.review_state // "") | @sh)
    ] | join("\n")
  ' 2>/dev/null || true)

  if [[ -n "$PARSED_VARS" ]]; then
    eval "$PARSED_VARS"
  fi
fi

# 1. Mode badge: vim mode and/or agent name (occupies the slot agy's agent
# state badge uses; empty when neither is set)
MODE_BADGE=""
if [[ -n "$VIM_MODE" ]]; then
  MODE_BADGE="${C_YELLOW}-- ${VIM_MODE} --${C_RESET}"
fi
if [[ -n "$AGENT_NAME" ]]; then
  MODE_BADGE="${MODE_BADGE:+$MODE_BADGE }${C_MAGENTA}@${AGENT_NAME}${C_RESET}"
fi

# 2. Host segment
HOST=$(hostname -s 2>/dev/null || hostname 2>/dev/null || echo "localhost")
HOST_SEGMENT="${C_BLUE}${HOST}${C_RESET}"

# 3. Context window remaining segment: [REMAINING% SIZE · TOTAL_IN↑ TOTAL_OUT↓ · $X.XX]
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

# 4. Model segment (with effort level, e.g. "Opus (high)")
MODEL_SEGMENT=""
if [[ -n "$MODEL" ]]; then
  MODEL_SEGMENT="${C_MAGENTA}${MODEL}${C_RESET}"
  if [[ -n "$EFFORT" ]]; then
    MODEL_SEGMENT="${MODEL_SEGMENT} ${C_DIM}(${EFFORT})${C_RESET}"
  fi
fi

# 5. Repository / worktree segment
REPO_SEGMENT=""
if [[ -n "$WORKTREE_NAME" ]]; then
  REPO_SEGMENT="${C_CYAN}${WORKTREE_NAME}${C_RESET}"
elif [[ -n "$REPO_NAME" ]]; then
  REPO_SEGMENT="${C_YELLOW}${REPO_NAME}${C_RESET}"
elif GIT_TOPLEVEL=$(git rev-parse --show-toplevel 2>/dev/null); then
  REPO_SEGMENT="${C_YELLOW}${GIT_TOPLEVEL##*/}${C_RESET}"
fi

# 6. Rate limit segment (Claude Code only, codex-style): [5h XX% left]
RATE_SEGMENT=""
if [[ "$RATE_5H_LEFT" != "-1" ]]; then
  if [[ "$RATE_5H_LEFT" -lt 10 ]]; then
    RATE_COLOR="$C_RED"
  elif [[ "$RATE_5H_LEFT" -lt 30 ]]; then
    RATE_COLOR="$C_YELLOW"
  else
    RATE_COLOR="$C_DIM"
  fi
  RATE_SEGMENT="${RATE_COLOR}5h ${RATE_5H_LEFT}% left${C_RESET}"
fi

# 7. Open PR segment (Claude Code only)
PR_SEGMENT=""
if [[ -n "$PR_NUMBER" ]]; then
  case "$PR_STATE" in
    approved) PR_COLOR="$C_GREEN" ;;
    changes_requested) PR_COLOR="$C_RED" ;;
    pending | draft) PR_COLOR="$C_YELLOW" ;;
    *) PR_COLOR="$C_DIM" ;;
  esac
  PR_SEGMENT="${PR_COLOR}PR #${PR_NUMBER}${C_RESET}"
fi

# Delimiter
SEP="${C_DIM}·${C_RESET}"

# Assemble segments based on available terminal width
PARTS=()
if [[ -n "$MODE_BADGE" ]]; then
  PARTS+=("$MODE_BADGE")
fi
PARTS+=("$HOST_SEGMENT")

PARTS+=("$CTX_SEGMENT")

# On wider terminals (>= 110 columns), show all details
if [[ "${COLS:-80}" -ge 110 ]]; then
  if [[ -n "$MODEL_SEGMENT" ]]; then
    PARTS+=("$MODEL_SEGMENT")
  fi
  if [[ -n "$REPO_SEGMENT" ]]; then
    PARTS+=("$REPO_SEGMENT")
  fi
  if [[ -n "$PR_SEGMENT" ]]; then
    PARTS+=("$PR_SEGMENT")
  fi
  if [[ -n "$RATE_SEGMENT" ]]; then
    PARTS+=("$RATE_SEGMENT")
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

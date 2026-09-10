#!/usr/bin/env bash
# The installer's whole drawing surface. Pure ANSI: a TUI library would be a
# dependency to install before anything can be installed.

RESET=$'\e[0m'; BOLD=$'\e[1m'
C_OK=$'\e[32m'; C_BAD=$'\e[31m'; C_DIM=$'\e[2m'

# The terminal is borrowed, not taken: every exit path gives it back. Without the
# trap, a Ctrl-C mid-install leaves the user typing blind into a shell with no
# echo. stty fails harmlessly when there is no tty, which is how the probes run.
_tui_open()  { printf '\e[?25l'; stty -echo 2>/dev/null; trap _tui_close EXIT INT TERM; }
_tui_close() { stty echo 2>/dev/null; printf '\e[?25h\n'; }

# Redraw in place: up N lines, and every line clears itself as it is rewritten --
# without the erase, a shorter line leaves the tail of the longer one it replaced.
_tui_up()   { printf '\e[%dA' "$1"; }
_tui_line() { printf '\r\e[K%s\n' "$*"; }

# A progress bar of exactly `width` cells, whatever the numbers say.
tui_bar() {
    local done=$1 total=$2 width=$3 filled i out=""
    [ "$total" -le 0 ] && total=1
    filled=$(( done * width / total ))
    [ "$filled" -gt "$width" ] && filled=$width
    [ "$filled" -lt 0 ] && filled=0
    for (( i = 0; i < width; i++ )); do
        if [ "$i" -lt "$filled" ]; then out+="█"; else out+="░"; fi
    done
    printf '%s' "$out"
}

# ── The surface ───────────────────────────────────────────────────────────
# The install used to print one line per package: 64 lines that scrolled past
# faster than they could be read, and no way to tell what was left. This draws
# the five steps ONCE and rewrites them in place, so the screen answers "where
# is it" without remembering what went by.
#
# Live only on a real terminal and only for a real install: a dry run is a
# report you read afterwards, and a pipe (the probes, a log) gets plain lines
# because \e[A into a file is just noise.
TUI_STEPS=(); TUI_STATE=(); TUI_NOTE=(); TUI_LIVE=0

tui_steps() {
    TUI_STEPS=("$@"); TUI_STATE=(); TUI_NOTE=()
    local _
    for _ in "$@"; do TUI_STATE+=(idle); TUI_NOTE+=(""); done
    if [ -t 1 ] && [ "${ASHEN_DRY:-0}" -eq 0 ]; then TUI_LIVE=1; else TUI_LIVE=0; fi
    [ "$TUI_LIVE" -eq 1 ] && _tui_render first
    return 0
}

# Cut to the terminal, never wrapped: a wrapped line breaks the redraw, because
# what went down two rows only comes back up one.
_tui_fit() {
    local text=$1 max=$(( ${COLUMNS:-$(tput cols 2>/dev/null || echo 80)} - 6 ))
    [ "${#text}" -le "$max" ] && { printf '%s' "$text"; return; }
    printf '%s…' "${text:0:max-1}"
}

_tui_render() {
    [ "$TUI_LIVE" -eq 1 ] || return 0
    [ -z "${1:-}" ] && _tui_up "${#TUI_STEPS[@]}"
    local i mark
    for i in "${!TUI_STEPS[@]}"; do
        case "${TUI_STATE[$i]}" in
            run) mark="${BOLD}▸${RESET}" ;;
            ok)  mark="${C_OK}✓${RESET}" ;;
            bad) mark="${C_BAD}✗${RESET}" ;;
            *)   mark="${C_DIM}·${RESET}" ;;
        esac
        _tui_line "$(_tui_fit "  $mark $(printf '%-14s' "${TUI_STEPS[$i]}")${C_DIM}${TUI_NOTE[$i]}${RESET}")"
    done
}

# A step changes state; a note is whatever it wants to say while it runs.
tui_step() {
    local i=$1 state=$2
    TUI_STATE[$i]=$state
    if [ "$TUI_LIVE" -eq 1 ]; then _tui_render
    elif [ "$state" = run ]; then printf '\n  %s%s%s\n' "$BOLD" "${TUI_STEPS[$i]}" "$RESET"
    fi
}
tui_note() {
    [ "$TUI_LIVE" -eq 1 ] || return 0
    TUI_NOTE[$1]=$2
    _tui_render
}

# Something that must survive the redraw -- a package that failed, a warning.
# Printed ABOVE the surface, which then draws itself one row lower.
tui_say() {
    if [ "$TUI_LIVE" -eq 1 ]; then
        _tui_up "${#TUI_STEPS[@]}"
        _tui_line "$*"
        _tui_render first
    else
        printf '  %s\n' "$*"
    fi
}

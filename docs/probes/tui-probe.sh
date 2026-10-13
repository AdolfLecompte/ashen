#!/usr/bin/env bash
# The terminal is borrowed. This checks it is always given back.
set -uo pipefail
cd "$(dirname "$0")/../.."
fail=0
say() { printf '%-4s %s\n' "$1" "$2"; }

bash -n install/lib/tui.sh 2>/dev/null && say ok "syntax" || { say FAIL "syntax"; exit 1; }

# Ctrl-C ENDS the install: a handler on INT that only restored the terminal let
# the run carry on installing.
out=$(bash -c 'source install/lib/tui.sh; _tui_open; kill -INT $$; echo AFTER' 2>&1)
printf '%s' "$out" | grep -q AFTER \
  && { say FAIL "install carries on after Ctrl-C"; fail=1; } || say ok "Ctrl-C stops the run"

# What a step prints lands above the surface, never through it.
out=$(bash -c 'source install/lib/tui.sh; TUI_LIVE=1; TUI_STEPS=(a b); TUI_STATE=(idle idle); TUI_NOTE=("" "");
               f() { echo "  hello"; return 3; }; tui_run f; echo "rc=$?"' 2>&1)
printf '%s' "$out" | grep -q 'rc=3' && printf '%s' "$out" | grep -q $'\e\[K'"hello" \
  && say ok "tui_run lifts output, keeps rc" || { say FAIL "tui_run"; fail=1; }

# A long note is cut on its visible text, never through an escape sequence.
n=$(bash -c 'source install/lib/tui.sh; COLUMNS=40; _tui_fit "$(printf "x%.0s" {1..80})" 18' | wc -m)
[ "$n" -le 16 ] && say ok "notes fit the terminal ($n)" || { say FAIL "note too long ($n)"; fail=1; }

# A run that dies mid-draw still emits the restoring sequences.
out=$(bash -c 'source install/lib/tui.sh; _tui_open; _tui_line hi; kill -INT $$' 2>&1)
printf '%s' "$out" | grep -q $'\e\[?25h' \
  && say ok "cursor restored after SIGINT" || { say FAIL "cursor left hidden"; fail=1; }

# A clean exit restores it too.
out=$(bash -c 'source install/lib/tui.sh; _tui_open; _tui_line hi' 2>&1)
printf '%s' "$out" | grep -q $'\e\[?25h' \
  && say ok "cursor restored on clean exit" || { say FAIL "cursor left hidden"; fail=1; }

# Every drawn line clears itself, or a shorter line leaves the tail of a longer one.
printf '%s' "$(bash -c 'source install/lib/tui.sh; _tui_line x')" | grep -q $'\e\[K' \
  && say ok "lines clear themselves" || { say FAIL "no erase-to-end"; fail=1; }

# The bar is exactly `width` cells whatever the numbers say.
for args in "0 47 20" "23 47 20" "47 47 20" "99 47 20" "-5 47 20"; do
    b=$(bash -c "source install/lib/tui.sh; tui_bar $args")
    n=$(printf '%s' "$b" | grep -o '[█░]' | wc -l)
    [ "$n" -eq 20 ] && say ok "bar($args) is 20 cells" \
                    || { say FAIL "bar($args) is $n cells"; fail=1; }
done

# Zero total must not divide by zero.
bash -c 'source install/lib/tui.sh; tui_bar 0 0 20' >/dev/null 2>&1 \
  && say ok "zero total survives" || { say FAIL "zero total divides by zero"; fail=1; }

# The bar actually tracks progress rather than being decorative.
e=$(bash -c 'source install/lib/tui.sh; tui_bar 0 10 20'  | grep -o '█' | wc -l)
h=$(bash -c 'source install/lib/tui.sh; tui_bar 5 10 20'  | grep -o '█' | wc -l)
f=$(bash -c 'source install/lib/tui.sh; tui_bar 10 10 20' | grep -o '█' | wc -l)
[ "$e" -eq 0 ] && [ "$h" -eq 10 ] && [ "$f" -eq 20 ] \
  && say ok "bar fills 0/10/20" || { say FAIL "bar fills $e/$h/$f"; fail=1; }

exit $fail

#!/usr/bin/env bash
# The terminal is borrowed. This checks it is always given back.
set -uo pipefail
cd "$(dirname "$0")/../.."
fail=0
say() { printf '%-4s %s\n' "$1" "$2"; }

bash -n install/lib/tui.sh 2>/dev/null && say ok "syntax" || { say FAIL "syntax"; exit 1; }

# The trap covers all three signals, not just EXIT: a Ctrl-C mid-install is the
# case that leaves a user typing blind.
grep -qE 'trap[[:space:]]+_tui_close[[:space:]]+EXIT[[:space:]]+INT[[:space:]]+TERM' install/lib/tui.sh \
  && say ok "trap on EXIT INT TERM" || { say FAIL "trap misses a signal"; fail=1; }

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

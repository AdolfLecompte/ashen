#!/usr/bin/env bash
# The mark is one artifact: the installer and fastfetch print the same rows.
set -uo pipefail
cd "$(dirname "$0")/../.."
fail=0
say() { printf '%-4s %s\n' "$1" "$2"; }

# shellcheck source=/dev/null
source install/lib/logo.sh 2>/dev/null || { say FAIL "install/lib/logo.sh missing"; exit 1; }

got=$(ashen_logo)
rows=$(printf '%s\n' "$got" | wc -l)
[ "$rows" -eq 6 ] && say ok "six rows" || { say FAIL "six rows, got $rows"; fail=1; }

wide=$(printf '%s\n' "$got" | awk '{ if (length($0) > m) m = length($0) } END { print m }')
[ "$wide" -le 72 ] && say ok "fits 80 cols ($wide)" || { say FAIL "too wide: $wide"; fail=1; }

# The A is well formed: ANSI Shadow's A opens with a space, not a block.
printf '%s\n' "$got" | head -1 | grep -q '^ *[░▒▓█]\{5\}╗' \
  && say ok "A well formed" || { say FAIL "A malformed (row 1)"; fail=1; }

# The smoke ramp runs top to bottom and never goes backwards.
order=" ░▒▓█"
prev=0
for i in 1 2 3 4 5; do
    ch=$(printf '%s\n' "$got" | sed -n "${i}p" | grep -o '[░▒▓█]' | head -1)
    idx=$(awk -v s="$order" -v c="$ch" 'BEGIN{ print index(s, c) }')
    [ "$idx" -ge "$prev" ] || { say FAIL "ramp goes backwards at row $i"; fail=1; }
    prev=$idx
done
say ok "ramp never goes backwards"

# fastfetch prints the same rows, modulo its $1 colour token and indentation.
strip() { sed 's/^\$1//' | grep '[░▒▓█]' | tr -d ' '; }
a=$(printf '%s\n' "$got" | strip)
b=$(strip < fastfetch/.config/fastfetch/ashen.txt)
[ "$a" = "$b" ] && say ok "fastfetch matches" || { say FAIL "fastfetch differs"; fail=1; }

exit $fail

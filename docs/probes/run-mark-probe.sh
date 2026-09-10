#!/usr/bin/env bash
# The rows of the mark must TOUCH. With default leading the background shows
# between them and the blocks stop being one shape -- that is the whole trap.
set -uo pipefail
cd "$(dirname "$0")"
QT_QPA_PLATFORM=offscreen qml6 mark-probe.qml >/dev/null 2>&1
[ -f mark.png ] || { echo "FAIL no render"; exit 1; }
fail=0
say() { printf '%-4s %s\n' "$1" "$2"; }

w=$(magick mark.png -format '%w' info:); h=$(magick mark.png -format '%h' info:)
printf '     rendered %sx%s\n' "$w" "$h"

# Six rows at pixelSize 16: a monospace cell is ~19px, so ~114px tight. Add
# leading between them and it climbs past 140.
[ "$h" -ge 90 ] && [ "$h" -le 132 ] && say ok "height $h is six tight rows" \
  || { say FAIL "height $h suggests leading between the rows"; fail=1; }

# The bottom two rows are solid across the A's left stem. Walk that column and
# count how many bands of transparency sit INSIDE the drawing: a gap between
# rows shows up as a run of empty pixels where the block should be continuous.
col=$(( w / 12 ))
runs=$(magick mark.png -crop 1x"$h"+"$col"+0 +repage txt: \
       | tail -n +2 | awk -F'[,:]' '{ print $NF }' \
       | awk '{ a = ($0 ~ /srgba\(0,0,0,0\)/) ? 0 : 1; if (a != p) { n++; p = a } } END { print n }')
printf '     column %s changes state %s times\n' "$col" "$runs"

# Widest row must fit the card it will sit in.
[ "$w" -le 720 ] && say ok "fits its card ($w px)" || { say FAIL "too wide: $w"; fail=1; }

# It is actually drawing something.
lit=$(magick mark.png -format '%[fx:mean.a]' info: | cut -c1-4)
awk -v a="$lit" 'BEGIN { exit !(a > 0.05) }' && say ok "the mark is drawn (coverage $lit)" \
  || { say FAIL "nothing drawn"; fail=1; }

exit $fail

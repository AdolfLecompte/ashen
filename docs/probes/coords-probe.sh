#!/usr/bin/env bash
# Where a pill thinks it is.
#
# `mapToGlobal` on a layer surface answers in the LAYOUT, not in the window: a
# pill 1681 px along the bar of a monitor that starts at x=1920 comes back as
# 3601. The panel that reads that number lives in a window 1920 wide, so every
# panel on a second monitor was clamped against its right edge. On the primary
# monitor the two numbers are equal, which is why it looked fine for months.
#
# Measured before the fix: [PILL] volume screen HEADLESS-1 g.x 3601 => cx 3669.
set -uo pipefail
cd "$(dirname "$0")/../.."
fail=0
say() { printf '%-4s %s\n' "$1" "$2"; }

qs=quickshell/.config/quickshell/ashen/modules/bar/components

# Every reader of mapToGlobal has to take the screen's own origin off again.
for f in PillCenter.qml Workspaces.qml TrayPill.qml; do
    grep -q 'mapToGlobal' "$qs/$f" || { say ok "$f no longer maps"; continue; }
    if grep -qE '\.x : 0|screenX|s\.x' "$qs/$f"; then
        say ok "$f subtracts the screen origin"
    else
        say FAIL "$f uses mapToGlobal without correcting for the monitor"; fail=1
    fi
done

# And the correction is taken from the BAR's own screen, not from the focused
# one: with a bar per monitor those are different things, and reading the
# focused screen offsets a pill against a screen it is not on.
grep -q 'barScreen' "$qs/PillCenter.qml" \
  && say ok "it asks its own window which screen it is on" \
  || { say FAIL "PillCenter does not use its own screen"; fail=1; }

exit $fail

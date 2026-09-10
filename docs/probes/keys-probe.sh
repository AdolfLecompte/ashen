#!/usr/bin/env bash
# Rebinding a shortcut. Hyprland runs its own binds BEFORE the client sees the
# key, so a chip waiting for SUPER+T used to open a terminal instead of hearing
# anything. The fix is an empty submap; these asserts guard both halves of it.
set -uo pipefail
cd "$(dirname "$0")/../.."
fail=0
say() { printf '%-4s %s\n' "$1" "$2"; }

keys=hypr/.config/hypr/conf/keybinds.lua
chip=quickshell/.config/quickshell/ashen/modules/settings/components/KeyChip.qml

grep -q 'define_submap("ashen-capture"' "$keys" \
  && say ok "the capture submap is defined" \
  || { say FAIL "no ashen-capture submap -- Hyprland eats the key"; fail=1; }

# Nothing may be bound in it except the way out, or that combination is the one
# thing you cannot assign.
body=$(sed -n '/define_submap("ashen-capture"/,/^end)/p' "$keys")
n=$(printf '%s\n' "$body" | grep -c 'hl.bind')
[ "$n" -eq 1 ] && say ok "only escape is bound inside it" \
  || { say FAIL "$n binds inside the capture submap, expected 1"; fail=1; }
printf '%s\n' "$body" | grep -q 'escape' \
  && say ok "escape leaves it" || { say FAIL "no way out of the submap"; fail=1; }

grep -q 'ashen-capture' "$chip" && say ok "the chip enters it" \
  || { say FAIL "KeyChip never enters the submap"; fail=1; }
grep -q 'submap(\\"reset\\")' "$chip" && say ok "the chip leaves it" \
  || { say FAIL "KeyChip never resets the submap"; fail=1; }
grep -q 'Component.onDestruction' "$chip" && say ok "closing Settings leaves it too" \
  || { say FAIL "a chip destroyed while listening strands the session"; fail=1; }

# This Hyprland's config is Lua and so is its dispatch argument: the classic
# `submap name` answers "')' expected near 'name'".
grep -q 'hl.dsp.submap' "$chip" && say ok "dispatch written in lua" \
  || { say FAIL "dispatch is not lua -- hyprctl will refuse it"; fail=1; }

# And it really is a verb this Hyprland knows, not one from the docs.
if command -v hyprctl >/dev/null 2>&1 && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    before=$(hyprctl submap)
    hyprctl dispatch 'hl.dsp.submap("ashen-capture")' >/dev/null 2>&1
    now=$(hyprctl submap)
    hyprctl dispatch 'hl.dsp.submap("reset")' >/dev/null 2>&1
    back=$(hyprctl submap)
    [ "$now" = "ashen-capture" ] && say ok "hyprland enters it live" \
      || { say FAIL "live submap did not switch (got '$now')"; fail=1; }
    [ "$back" = "$before" ] && say ok "and comes back" \
      || { say FAIL "session left in submap '$back'"; fail=1; }
else
    say ok "no hyprland here -- live check skipped"
fi

exit $fail

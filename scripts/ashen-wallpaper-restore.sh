#!/usr/bin/env bash
# ── Ashen — restores the last wallpaper on login ─────────────────────────
#    awww-daemon does not remember anything across reboots and mpvpaper is
#    not even running yet, so Hyprland's autostart calls this instead.
#
#    Each screen gets back what IT was wearing, read from ashen_wallpapers.txt.
#    The palette is applied once, from ashen_wallpaper.txt, which already holds
#    the primary screen's wallpaper -- so which screen is primary never has to
#    be worked out here.
# ─────────────────────────────────────────────────────────────────────────
set -uo pipefail

# Sibling scripts are resolved next to this one, so the set works from the
# checkout and from /usr/bin alike.
HERE="$(dirname "$(readlink -f "$0")")"
SET="$HERE/ashen-wallpaper.sh"

STATE="$HOME/.cache/ashen_wallpaper.txt"
STATES="$HOME/.cache/ashen_wallpapers.txt"

WALL="$(cat "$STATE" 2>/dev/null)"

# The per-screen record is keyed by DESCRIPTION, the way Displays keys its
# layout, because a port name moves between reboots. awww and mpvpaper only
# take names, so the key is resolved back to today's name here.
PAINTED=0
if [ -f "$STATES" ]; then
    while IFS=$'\t' read -r name desc; do
        [ -n "$name" ] || continue
        key="${desc:-$name}"
        wall="$(awk -F'\t' -v k="$key" '$1 == k { print $2; exit }' "$STATES")"
        [ -n "${wall:-}" ] && [ -f "$wall" ] || continue
        "$SET" "$wall" --output "$name"
        PAINTED=$((PAINTED + 1))
    done < <(hyprctl monitors 2>/dev/null | awk '
        /^Monitor /            { name = $2 }
        /^[ \t]+description: / { d = $0; sub(/^[ \t]*description: /, "", d)
                                 if (name != "") printf "%s\t%s\n", name, d }
    ')
fi

# Nothing remembered per screen (a first login, or an upgrade from before the
# per-screen record existed): fall back to painting everything with the one
# wallpaper we do know about.
if [ "$PAINTED" -eq 0 ]; then
    [ -n "${WALL:-}" ] && [ -f "$WALL" ] || exit 0
    exec "$SET" "$WALL"
fi

# The screens are painted; the colours still have to be laid down. Not by
# re-running the setter normally -- that would repaint a screen with someone
# else's wallpaper. --palette-only lays down the shared frame and the palette
# from the primary's wallpaper and touches no screen at all.
[ -n "${WALL:-}" ] && [ -f "$WALL" ] || exit 0
exec "$SET" "$WALL" --palette-only

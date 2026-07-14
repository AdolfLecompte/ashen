#!/usr/bin/env bash
# ── Ashen — restores the last wallpaper on login ─────────────────────────
#    awww-daemon does not remember anything across reboots and mpvpaper is
#    not even running yet, so Hyprland's autostart calls this instead.
# ─────────────────────────────────────────────────────────────────────────
set -uo pipefail

WALL="$(cat "$HOME/.cache/ashen_wallpaper.txt" 2>/dev/null)"
[ -n "${WALL:-}" ] && [ -f "$WALL" ] || exit 0

exec "$HOME/ashen/scripts/ashen-wallpaper.sh" "$WALL"

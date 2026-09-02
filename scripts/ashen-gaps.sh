#!/usr/bin/env bash
# ── Ashen — outer gap ────────────────────────────────────────────────────
# Set Hyprland's gaps_out, live. The framed bar style reserves its own border,
# so the compositor's outer gap has to step aside or the two stack up.
#
#   ashen-gaps.sh 0     -- the frame is the gap now
#   ashen-gaps.sh 8     -- back to the shipped one
#
# Never persisted: matugen rewrites general.lua, and the layout is per-machine.
# Same env dance as ashen-apply-border.sh: Quickshell spawns us without
# HYPRLAND_INSTANCE_SIGNATURE.
# ─────────────────────────────────────────────────────────────────────────
set -uo pipefail

n="${1:-8}"
case "$n" in
    ''|*[!0-9]*) exit 1 ;;
esac

[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] || \
    export HYPRLAND_INSTANCE_SIGNATURE="$(ls -t "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr" 2>/dev/null | head -1)"

# hl.config, not hl.general (no such field), and `hyprctl keyword` is dead here.
hyprctl eval "hl.config({ general = { gaps_out = ${n} } })" >/dev/null 2>&1 || true

#!/usr/bin/env bash
# ── Ashen — apply window border ──────────────────────────────────────────
# Push the accent to Hyprland's active window border, live (hyprctl) and
# persisted (~/.config/ashen/hypr/border.lua). Reads ~/.cache/ashen_accent.txt, which
# ashen-accent.sh writes -- the same tone the shell and the apps ended up with,
# rather than matugen's `primary`, which on a light palette may not be it.
#
# This lives here, NOT in matugen's post_hook, on purpose: matugen runs under
# Quickshell, and its post_hooks inherit an env WITHOUT
# HYPRLAND_INSTANCE_SIGNATURE, so hyprctl there fails and the whole hook aborts
# before it can even persist the border. Called from ashen-wallpaper.sh and
# ashen-recolor.sh right after matugen returns, where we control the env and
# derive the signature ourselves if it is missing.
# ─────────────────────────────────────────────────────────────────────────
set -uo pipefail

CACHE="$HOME/.cache"
hex="$(cat "$CACHE/ashen_accent.txt" 2>/dev/null)" || exit 0
[ -n "$hex" ] || exit 0

# Outside the checkout (hyprland.lua loads it last), so the repo stays clean.
mkdir -p "$HOME/.config/ashen/hypr"
printf 'hl.config({ general = { col = { active_border = { colors = {"rgba(%sff)"} } } } })\n' "$hex" \
    > "$HOME/.config/ashen/hypr/border.lua"

# hyprctl needs the instance signature; Quickshell-spawned callers do not carry
# it, so recover it from the runtime socket dir (newest instance).
[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] || \
    export HYPRLAND_INSTANCE_SIGNATURE="$(ls -t "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr" 2>/dev/null | head -1)"

hyprctl eval "hl.config({ general = { col = { active_border = { colors = {'rgba(${hex}ff)'} } } } })" >/dev/null 2>&1 || true
# Tab groups read the same accent file (conf/windows.lua).
hyprctl eval 'require("conf/windows").paintGroups()' >/dev/null 2>&1 || true

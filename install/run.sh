#!/usr/bin/env bash
# Ashen — the installer.
#
# Called by install/boot.sh after the clone, and usable on its own from a
# checkout. Running it again is how Ashen updates.
#
# NOT `set -e`: the whole point is that a package that fails does not end the
# run. Failures are collected and reported, never thrown.
set -uo pipefail

ASHEN_REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ASHEN_LOG="${ASHEN_LOG:-$HOME/.cache/ashen-install.log}"
ASHEN_DRY=0
for a in "$@"; do
    case "$a" in
        --dry-run) ASHEN_DRY=1 ;;
        -h|--help) echo "usage: run.sh [--dry-run]"; exit 0 ;;
    esac
done
export ASHEN_REPO ASHEN_LOG ASHEN_DRY

# shellcheck source=/dev/null
source "$ASHEN_REPO/install/lib/tui.sh"
# shellcheck source=/dev/null
source "$ASHEN_REPO/install/lib/logo.sh"
# shellcheck source=/dev/null
source "$ASHEN_REPO/install/lib/pkgs.sh"
# shellcheck source=/dev/null
source "$ASHEN_REPO/install/lib/dots.sh"
# shellcheck source=/dev/null
source "$ASHEN_REPO/install/lib/sddm.sh"

# A dry run touches nothing at all -- not even its own log, which is still a
# file appearing in a home that asked for a rehearsal.
if [ "$ASHEN_DRY" -eq 1 ]; then
    ASHEN_LOG=/dev/null
else
    mkdir -p "$(dirname "$ASHEN_LOG")"
    : >"$ASHEN_LOG"
fi

# The five things this does, named up front. Drawn once and rewritten in place
# (lib/tui.sh); on a pipe or a dry run the same calls print plain headings.
TUI_PKG_STEP=0

command -v pacman >/dev/null || {
    echo "ashen: not an Arch-based system (no pacman)." >&2
    exit 1
}

# Root once, refreshed in the background: a per-package prompt would ask 50 times.
if [ "$ASHEN_DRY" -eq 0 ]; then
    sudo -v || { echo "ashen: need sudo to install packages." >&2; exit 1; }
    while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null &
fi

[ "$ASHEN_DRY" -eq 0 ] && _tui_open

# The mark first, not only at the end: what you are installing should be on the
# screen while it installs, and a curl into bash has shown nothing until now.
printf '\n'; ashen_logo; printf '\n'

tui_steps "packages" "dotfiles" "login screen" "services" "folders"

tui_step 0 run
pkgs_drop_pulseaudio
pkgs_install "sudo pacman -S" "${PKGS_OFFICIAL[@]}"

helper=$(pkgs_aur_helper) && pkgs_install "$helper" "${PKGS_AUR[@]}" || {
    printf '  no AUR helper (paru/yay/pikaur/trizen); skipping:\n'
    printf '    %s\n' "${PKGS_AUR[@]}"
}

tui_step 0 ok
tui_step 1 run
dots_place

tui_step 1 ok
tui_step 2 run
sddm_install

tui_step 2 ok
tui_step 3 run
pkgs_services

pkgs_video_group

tui_step 3 ok
tui_step 4 run
# Named, not guessed: whatever the system locale calls the user's folders, the
# wallpaper picker and the screenshot keybind look here.
for d in "$HOME/Pictures/Wallpapers" "$HOME/Pictures/Screenshots" "$HOME/Videos"; do
    if [ "$ASHEN_DRY" -eq 1 ]; then printf '  would create   %s\n' "$d"
    else mkdir -p "$d"; fi
done

tui_step 4 ok

pkgs_report

# The mark is drawn ONCE, at the top, where it stays on screen for the whole
# install. Printing it again at the end was the same logo twice on one screen.
# Reboot, not "log out": this install changed the LOGIN SCREEN, enabled three
# system services and put the user in the video group. A logout shows none of
# that, and a first run that looks half-applied is how somebody concludes it
# failed. The welcome card comes up on its own the first time the shell starts.
printf '\n       %sreboot%s, and Ashen greets you at the login screen\n\n' "$BOLD" "$RESET"

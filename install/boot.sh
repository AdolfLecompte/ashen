#!/usr/bin/env bash
# Ashen — the only thing that travels over curl.
#
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/AdolfLecompte/ashen/main/install/boot.sh)"
#
# Three jobs and no more: is this Arch, is git here, get the repo. Everything
# else lives in the clone, because the dotfiles do too and it has to be fetched
# either way. Kept short on purpose -- anyone piping a script into a shell
# should be able to read it first.
set -uo pipefail

REPO_URL="${ASHEN_SOURCE:-https://github.com/AdolfLecompte/ashen.git}"
# The installer picks the directory, never the user's clone. The shell's lua and
# services/Paths.qml look in $HOME/ashen, and a checkout named Ashen used to
# disagree with them silently.
ASHEN_DIR="$HOME/ashen"

say() { printf '\033[1;35m::\033[0m %s\n' "$*"; }
die() { printf '\033[1;31m!!\033[0m %s\n' "$*" >&2; exit 1; }

command -v pacman >/dev/null || die "Ashen needs an Arch-based system (no pacman here)."

if ! command -v git >/dev/null; then
    say "Installing git..."
    sudo pacman -S --needed --noconfirm git || die "could not install git."
fi

if [ -d "$ASHEN_DIR/.git" ]; then
    say "Updating $ASHEN_DIR..."
    git -C "$ASHEN_DIR" pull --ff-only >/dev/null 2>&1 \
        || say "could not fast-forward (local changes?) — installing what is there."
elif [ -e "$ASHEN_DIR" ]; then
    die "$ASHEN_DIR exists and is not a git checkout. Move it aside and re-run."
else
    say "Cloning into $ASHEN_DIR..."
    git clone --depth=1 "$REPO_URL" "$ASHEN_DIR" >/dev/null 2>&1 \
        || die "could not clone $REPO_URL"
fi

exec bash "$ASHEN_DIR/install/run.sh" "$@"

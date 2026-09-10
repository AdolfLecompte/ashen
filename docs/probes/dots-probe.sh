#!/usr/bin/env bash
# Dotfiles land in a HOME, and nothing of the user's is lost doing it.
# Everything runs against a throwaway HOME: this never touches the real one.
set -uo pipefail
cd "$(dirname "$0")/../.."
REPO=$PWD
fail=0
say() { printf '%-4s %s\n' "$1" "$2"; }

bash -n install/lib/dots.sh 2>/dev/null && say ok "syntax" || { say FAIL "syntax"; exit 1; }

T=$(mktemp -d); trap 'rm -rf "$T"' EXIT

# ── The dry run says what it would do, and does nothing ────────────────────
dry=$(HOME="$T" ASHEN_CONFIG_SRC="$REPO" bash install/lib/dots.sh --dry-run 2>&1)
[ -z "$(ls -A "$T")" ] && say ok "dry run wrote nothing" \
                       || { say FAIL "dry run created files"; fail=1; }
# Checked by the path each package LANDS at, not by its directory name in the
# repo: gtk arrives as .config/gtk-3.0 and wallpapers as Pictures/Wallpapers, so
# grepping the package name silently passes on the ones that are renamed.
while read -r label want; do
    printf '%s' "$dry" | grep -qE "would place +$want +[0-9]+ file" \
      && say ok "dry run covers $label" \
      || { say FAIL "$label not placed (looked for '$want')"; fail=1; }
done <<'WANT'
hypr hypr
kitty kitty
zsh zsh
zshrc \.zshrc
cava cava
fastfetch fastfetch
gtk-3 gtk-3\.0
gtk-4 gtk-4\.0
gtkrc \.gtkrc-2\.0
matugen matugen
quickshell quickshell
wallpapers Pictures
p10k \.p10k\.zsh
WANT
# The repo's own directories are NOT dotfiles and must never be copied into a home.
for bad in docs/ scripts/ install/ PKGBUILD; do
    printf '%s' "$dry" | grep -q "$bad" && { say FAIL "$bad would be copied into HOME"; fail=1; } \
                                        || say ok "$bad not copied"
done

# ── The real thing, into the throwaway HOME ────────────────────────────────
HOME="$T" ASHEN_CONFIG_SRC="$REPO" bash install/lib/dots.sh >/dev/null 2>&1
[ -e "$T/.zshrc" ] && say ok ".zshrc placed" || { say FAIL ".zshrc missing"; fail=1; }
[ -e "$T/.config/hypr/hyprland.lua" ] && say ok "hyprland.lua placed" \
                                      || { say FAIL "hyprland.lua missing"; fail=1; }

# The GTK dirs must be REAL directories. Folded into a symlink at the repo,
# matugen would write its generated gtk.css straight into the git tree.
for d in .config/gtk-3.0 .config/gtk-4.0; do
    if [ -L "$T/$d" ]; then say FAIL "$d is a symlink into the repo"; fail=1
    elif [ -d "$T/$d" ]; then say ok "$d is a real directory"
    else say FAIL "$d missing"; fail=1; fi
done

# Anything under hypr/ meant to be run stays executable.
if compgen -G "$T/.config/hypr/*.sh" >/dev/null; then
    [ -x "$(compgen -G "$T/.config/hypr/*.sh" | head -1)" ] \
      && say ok "hypr scripts executable" || { say FAIL "hypr scripts not executable"; fail=1; }
else
    say ok "no hypr scripts to chmod"
fi

# ── Nothing of the user's is destroyed ─────────────────────────────────────
# In a SECOND throwaway home that already has a real .zshrc, the way a machine
# does before Ashen touches it. The file is removed before being written: with
# --link, .zshrc is a symlink into the repo after the run above, and writing
# "through" it would edit the repo itself.
U=$(mktemp -d); trap 'rm -rf "$T" "$U"' EXIT
rm -f "$U/.zshrc"; echo "MINE" > "$U/.zshrc"
[ -L "$U/.zshrc" ] && { say FAIL "probe would write through a symlink"; fail=1; }
HOME="$U" ASHEN_CONFIG_SRC="$REPO" bash install/lib/dots.sh >/dev/null 2>&1
[ -f "$U/.zshrc.bak" ] && grep -q MINE "$U/.zshrc.bak" \
  && say ok "an existing file is kept as .bak" \
  || { say FAIL "the user's file was destroyed"; fail=1; }
# And the repo it links to is untouched by any of this.
grep -q MINE "$REPO/zsh/.zshrc" && { say FAIL "THE REPO WAS WRITTEN THROUGH A LINK"; fail=1; } \
                                || say ok "the repo was not written through a link"

# ── Running it twice changes nothing ───────────────────────────────────────
sum1=$(find "$T" -type f -exec md5sum {} + | sort -k2 | md5sum)
HOME="$T" ASHEN_CONFIG_SRC="$REPO" bash install/lib/dots.sh >/dev/null 2>&1
sum2=$(find "$T" -type f -exec md5sum {} + | sort -k2 | md5sum)
[ "$sum1" = "$sum2" ] && say ok "idempotent" \
                      || { say FAIL "a second run changed the home"; fail=1; }

exit $fail

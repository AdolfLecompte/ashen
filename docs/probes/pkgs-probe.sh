#!/usr/bin/env bash
# Everything setup-system.sh learned the hard way, asserted so it cannot be lost.
set -uo pipefail
cd "$(dirname "$0")/../.."
fail=0
say() { printf '%-4s %s\n' "$1" "$2"; }

bash -n install/lib/pkgs.sh 2>/dev/null || { say FAIL "syntax"; exit 1; }
# shellcheck source=/dev/null
source install/lib/pkgs.sh

has()   { printf '%s\n' "${PKGS_OFFICIAL[@]}" "${PKGS_AUR[@]}" | grep -qx "$1"; }
want()  { has "$1" && say ok "$1 listed" || { say FAIL "$1 MISSING"; fail=1; }; }
never() { has "$1" && { say FAIL "$1 must not be listed"; fail=1; } || say ok "$1 absent"; }

# Fonts the QML asks for BY FAMILY NAME. A miss renders tofu, not a fallback.
want ttf-jetbrains-mono-nerd
want ttf-material-symbols-variable
want noto-fonts-emoji
never ttf-material-symbols-variable-git   # Conflicts With the official one
never quickshell-git                      # the rice targets the 0.3.0 API
want adw-gtk-theme                        # July audit: adw-gtk3 aborts the transaction
never adw-gtk3
never papirus-folders                     # re-runs itself under sudo; ashen-folders.sh replaced it
never stow                                # dotfiles are placed by lib/dots.sh now

# The shell the user actually runs, none of which was listed anywhere before.
for p in zsh-theme-powerlevel10k zsh-autosuggestions zsh-syntax-highlighting \
         fzf zoxide eza bat fd; do want "$p"; done

# Nothing was dropped on the way over from setup-system.sh. Frozen as a fixture
# rather than read from that file: it is deleted in task 8, and a safety net that
# disappears with the thing it guards is not one. These are deliberately out:
#   stow             -> lib/dots.sh places the dotfiles now
#   papirus-folders  -> re-runs itself under sudo; ashen-folders.sh replaced it
#   zenity           -> the shell picks pictures and folders with its own dialog
#                       (services/Picker.qml, components/DirField.qml); the only
#                       zenity left in the tree is a window rule naming its class
#   python           -> it only ran the web cover lookup, gone in 3.1.0: every
#                       surface reads the cover straight from the player
missing=0
while read -r p; do
    [ -z "$p" ] && continue
    case "$p" in stow|papirus-folders|zenity|python) continue ;; esac
    has "$p" || { say FAIL "$p was in setup-system.sh and is gone"; missing=1; fail=1; }
done < docs/probes/fixtures/setup-system-packages.txt
[ "$missing" -eq 0 ] && say ok "nothing lost from setup-system.sh"

# A failing package must not end the run.
grep -qE '^\s*set -e\b' install/lib/pkgs.sh && { say FAIL "set -e would abort the run"; fail=1; } \
                                            || say ok "no set -e"
# One transaction per package, never a batch.
grep -qE 'pacman -S[^|]*\$\{PKGS' install/lib/pkgs.sh && { say FAIL "batch install"; fail=1; } \
                                                      || say ok "no batch install"
# The PulseAudio swap survived: pipewire-pulse Conflicts With it and does not Replace it.
grep -q 'pulseaudio' install/lib/pkgs.sh && say ok "pulseaudio swap kept" \
                                         || { say FAIL "pulseaudio swap lost"; fail=1; }
# libpulse is NOT removed with it: pipewire-pulse uses it.
grep -qE 'pacman -R[^\n]*libpulse' install/lib/pkgs.sh && { say FAIL "would remove libpulse"; fail=1; } \
                                                       || say ok "libpulse left alone"
# The video group, or no webcam in any browser.
grep -q 'usermod -aG video' install/lib/pkgs.sh && say ok "video group kept" \
                                                || { say FAIL "video group lost"; fail=1; }
# Services are enabled only when not already.
grep -q 'systemctl is-enabled' install/lib/pkgs.sh && say ok "services checked before enabling" \
                                                   || { say FAIL "services step lost"; fail=1; }

# ── Behaviour, not just the lists ─────────────────────────────────────────
# THE fault this whole project exists to fix: a bad target must not take the
# packages after it down with it. Driven with a stand-in for pacman so the
# system is never touched.
out=$(bash -c '
source install/lib/pkgs.sh
fake() { [ "$3" = "ashen-no-such-package" ] && return 1; return 0; }
pacman() { return 1; }
ASHEN_LOG=/dev/null
PKG_OK=(); PKG_HAVE=(); PKG_FAILED=()
pkgs_install fake hyprland ashen-no-such-package ttf-jetbrains-mono-nerd cava
echo "${#PKG_OK[@]} ${#PKG_FAILED[@]}"
printf "%s\n" "${PKG_OK[@]}"
')
counts=$(printf '%s\n' "$out" | head -1)
[ "$counts" = "3 1" ] && say ok "one bad target does not abort the rest" \
                      || { say FAIL "expected '3 1', got '$counts'"; fail=1; }
printf '%s\n' "$out" | grep -qx ttf-jetbrains-mono-nerd \
  && say ok "the font AFTER the failure still installs" \
  || { say FAIL "packages after the failure were skipped"; fail=1; }

# The dry run says everything and touches nothing.
before=$(pacman -Qq 2>/dev/null | md5sum)
dry=$(bash -c 'source install/lib/pkgs.sh; ASHEN_DRY=1 pkgs_install "pacman -S" hyprland cava; ASHEN_DRY=1 pkgs_services')
after=$(pacman -Qq 2>/dev/null | md5sum)
[ "$before" = "$after" ] && say ok "dry run installed nothing" \
                         || { say FAIL "dry run touched the system"; fail=1; }
printf '%s' "$dry" | grep -q 'would install  hyprland' && say ok "dry run names its packages" \
                                                       || { say FAIL "dry run said nothing"; fail=1; }
printf '%s' "$dry" | grep -q 'would enable   NetworkManager' && say ok "dry run names its services" \
                                                             || { say FAIL "dry run skipped services"; fail=1; }

# ── The AUR package and the installer must not drift ──────────────────────
# Every package the installer puts in has to be reachable from the PKGBUILD too,
# as a hard dependency or an optional one. Installing from the AUR used to give a
# zsh with no autosuggestions and no highlighting because the .zshrc named plugins
# the package never pulled in.
python3 - <<'CHECK'
import re, sys
pk = open("PKGBUILD", encoding="utf-8").read()
def block(name):
    m = re.search(r"^%s=\((.*?)^\)" % name, pk, re.S | re.M)
    return m.group(1) if m else ""
hard = {t for line in block("depends").splitlines()
          if not line.strip().startswith("#") for t in line.split()}
soft = {re.split(r"[:\s]", l.strip().strip("'\""))[0]
        for l in block("optdepends").splitlines() if l.strip().startswith("'")}
sh = open("install/lib/pkgs.sh", encoding="utf-8").read()
off = {t for line in re.search(r"^PKGS_OFFICIAL=\((.*?)^\)", sh, re.S | re.M).group(1).splitlines()
         if not line.strip().startswith("#") for t in line.split()}
# Toolchain the package does not need: makepkg brings them.
off -= {"git", "base-devel"}
gone = sorted(off - hard - soft)
if gone:
    print("FAIL packages the installer needs and the PKGBUILD forgot: " + ", ".join(gone))
    sys.exit(1)
print("ok   PKGBUILD covers every installer package")
CHECK
[ $? -eq 0 ] || fail=1

# The README prints both lists. A list nobody checks is a list that drifts, and
# this one drifted in both directions before the container caught it.
for p in $(bash -c 'source install/lib/pkgs.sh; echo "${PKGS_OFFICIAL[@]}"'); do
    grep -q -- "$p" README.md || { say FAIL "README does not list $p"; fail=1; miss=1; }
done
[ "${miss:-0}" -eq 0 ] && say ok "the README lists every official package"
for p in $(bash -c 'source install/lib/pkgs.sh; echo "${PKGS_AUR[@]}"'); do
    grep -q -- "$p" README.md || { say FAIL "README does not list $p"; fail=1; missa=1; }
done
[ "${missa:-0}" -eq 0 ] && say ok "the README lists every AUR package"

exit $fail

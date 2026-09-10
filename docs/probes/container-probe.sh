#!/usr/bin/env bash
# The installer, against a machine that has never seen Ashen.
#
# Everything else in docs/probes reads the scripts; this one RUNS them, on a
# clean Arch container, which is the only place where "it works here" stops
# being an argument. Needs a docker daemon: `sudo systemctl start docker`.
#
#   ./container-probe.sh          names, dry run, dotfiles  (~1 min, no downloads)
#   ./container-probe.sh --full   also installs every official package (~1.5 GB)
set -uo pipefail
cd "$(dirname "$0")/../.."
fail=0
say() { printf '%-4s %s\n' "$1" "$2"; }

IMG=archlinux:latest
FULL=0
[ "${1:-}" = "--full" ] && FULL=1

docker info >/dev/null 2>&1 || {
    say FAIL "no docker daemon -- sudo systemctl start docker"
    exit 1
}

# The repo goes in as a bind mount, read-only: the container must not be able to
# write to the checkout it is testing, or a probe that "passes" may have edited
# the thing it was checking.
RUN=(docker run --rm -v "$PWD":/ashen:ro "$IMG" bash -c)

# ── The package names ─────────────────────────────────────────────────────
# The failure this is built for: ONE bad name aborted the whole transaction and
# a fresh machine came up with no Nerd Font. `pacman -Sp` resolves every target
# and downloads nothing, so an unknown name is named here rather than at 3 am on
# somebody else's laptop.
out=$("${RUN[@]}" '
    set -uo pipefail
    source /ashen/install/lib/pkgs.sh
    pacman -Sy --noconfirm >/dev/null 2>&1
    pacman -Sp --print-format "%n" "${PKGS_OFFICIAL[@]}" >/dev/null 2>/tmp/err
    rc=$?
    if [ $rc -ne 0 ]; then echo "UNRESOLVED"; grep -oE "target not found: \S+" /tmp/err; fi
    echo "COUNT=${#PKGS_OFFICIAL[@]}"
' 2>&1)
if printf '%s' "$out" | grep -q UNRESOLVED; then
    say FAIL "some official packages do not exist:"
    printf '%s\n' "$out" | grep 'target not found' | sed 's/^/       /'
    fail=1
else
    n=$(printf '%s' "$out" | grep -oP 'COUNT=\K[0-9]+')
    say ok "all $n official packages resolve on a clean Arch"
fi

# ── The AUR names ─────────────────────────────────────────────────────────
# No helper in a container, and building one costs more than the answer is
# worth. The AUR's own API says whether a name exists.
aur=$(bash -c '
    source install/lib/pkgs.sh
    q=""; for p in "${PKGS_AUR[@]}"; do q="$q&arg[]=$p"; done
    curl -fsSL --max-time 10 "https://aur.archlinux.org/rpc/v5/info?${q#&}" \
      | grep -o "\"Name\":\"[^\"]*\"" | wc -l
    echo "WANT=${#PKGS_AUR[@]}"')
got=$(printf '%s' "$aur" | head -1)
want=$(printf '%s' "$aur" | grep -oP 'WANT=\K[0-9]+')
if [ "${got:-0}" -ge "${want:-99}" ]; then
    say ok "all $want AUR packages exist"
else
    say FAIL "only $got of $want AUR packages exist"; fail=1
fi

# ── The script itself, on a machine with nothing ──────────────────────────
# As a user, not root: `sudo -v` is skipped by a dry run, and running the whole
# thing as root would hide every permission assumption.
out=$("${RUN[@]}" '
    useradd -m tester >/dev/null 2>&1
    su tester -c "bash /ashen/install/run.sh --dry-run" 2>&1
' 2>&1)
printf '%s' "$out" | grep -q 'would create' \
  && say ok "the dry run completes on a bare container" \
  || { say FAIL "dry run did not reach the end:"; printf '%s\n' "$out" | tail -5 | sed 's/^/       /'; fail=1; }
printf '%s' "$out" | grep -qi 'not an Arch' \
  && { say FAIL "it did not recognise Arch"; fail=1; } \
  || say ok "it recognises Arch"

# A dry run must not write ANYTHING -- including its own log. Compared against
# the home BEFORE it ran, not against empty: `useradd -m` lays down .bashrc and
# friends from /etc/skel, and counting those as the installer's doing is how
# this assert failed the first time it was written.
out=$("${RUN[@]}" '
    useradd -m tester >/dev/null 2>&1
    ls -A /home/tester | sort > /tmp/before
    su tester -c "bash /ashen/install/run.sh --dry-run" >/dev/null 2>&1
    ls -A /home/tester | sort > /tmp/after
    grep -vxF -f /tmp/before /tmp/after | tr "\n" " "   # no diffutils in the base image
' 2>&1)
[ -z "$(printf '%s' "$out" | tr -d '[:space:]')" ] \
  && say ok "the dry run leaves the home untouched" \
  || { say FAIL "dry run wrote into a home: $out"; fail=1; }

# ── The dotfiles, placed for real ─────────────────────────────────────────
# Read-only mount, so this copies the checkout first -- which is also what
# `ashen-setup --link` does on a real machine when stow is missing.
out=$("${RUN[@]}" '
    pacman -Sy --noconfirm git zsh >/dev/null 2>&1
    useradd -m tester >/dev/null 2>&1
    cp -r /ashen /home/tester/ashen && chown -R tester /home/tester/ashen
    su tester -c "ASHEN_CONFIG_SRC=/home/tester/ashen /home/tester/ashen/scripts/ashen-setup --link" >/dev/null 2>&1
    for f in .config/hypr/hyprland.lua .config/quickshell/ashen/shell.qml .config/zsh/.zshrc .p10k.zsh; do
        [ -e "/home/tester/$f" ] && echo "HAVE $f" || echo "MISS $f"
    done
' 2>&1)
miss=$(printf '%s\n' "$out" | grep -c '^MISS')
if [ "$miss" -eq 0 ]; then
    say ok "the dotfiles land where the shell looks for them"
else
    say FAIL "$miss dotfiles did not land:"
    printf '%s\n' "$out" | grep '^MISS' | sed 's/^/       /'
    fail=1
fi

# ── The whole package list, actually installed ────────────────────────────
if [ "$FULL" -eq 1 ]; then
    say ok "installing every official package for real -- this downloads ~1.5 GB"
    out=$("${RUN[@]}" '
        set -uo pipefail
        source /ashen/install/lib/pkgs.sh
        pacman -Sy --noconfirm >/dev/null 2>&1
        pkgs_drop_pulseaudio
        bad=0
        for p in "${PKGS_OFFICIAL[@]}"; do
            pacman -S --needed --noconfirm "$p" >/dev/null 2>&1 || { echo "FAILED $p"; bad=1; }
        done
        echo "DONE bad=$bad"
    ' 2>&1)
    printf '%s' "$out" | grep -q 'bad=0' \
      && say ok "every official package installs, one transaction each" \
      || { say FAIL "packages that would not install:"; printf '%s\n' "$out" | grep '^FAILED' | sed 's/^/       /'; fail=1; }
fi

exit $fail

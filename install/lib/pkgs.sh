#!/usr/bin/env bash
# What Ashen needs, and installing it one package at a time.
#
# The comments on these lists are the July audit. They are not decoration: each
# one records a package that broke an install once. Do not tidy them away.

PKGS_OFFICIAL=(
    hyprland kitty zsh git base-devel
    qt6-base qt6-declarative qt6-5compat
    # The STABLE build, never quickshell-git: the rice targets the 0.3.0 API and
    # the -git package tracks a newer, drifting one.
    quickshell
    pipewire pipewire-pulse pipewire-alsa wireplumber libpulse
    networkmanager bluez bluez-utils udisks2 upower power-profiles-daemon
    brightnessctl lm_sensors pciutils
    wl-clipboard cliphist grim slurp wf-recorder
    hypridle ffmpeg wlsunset
    # In `extra` since 2026, not the AUR: awww paints the wallpaper and matugen
    # is where the whole colour scheme comes from.
    awww matugen
    nemo fastfetch cava xdg-utils libnotify
    #   curl            <- lyrics (services/Lyrics)
    #   imagemagick     <- wallpaper thumbnails (scripts/ashen-wallpaper-thumbs.sh)
    #   pacman-contrib  <- `checkupdates` for the updates readout (services/Updates)
    #   gtk3            <- `gtk-launch`, how a notification action opens its app
    #   qt6ct           <- conf/env.lua points QT_QPA_PLATFORMTHEME at it and
    #                      ashen-accent.sh writes its palette
    curl imagemagick pacman-contrib gtk3 qt6ct
    # adw-gtk-theme, NOT adw-gtk3: that name does not exist in the repos and a
    # single bad target used to abort the whole transaction.
    papirus-icon-theme adw-gtk-theme
    # Fonts the QML asks for BY FAMILY NAME -- a miss renders tofu, not a fallback:
    #   "JetBrainsMono NF"         <- ttf-jetbrains-mono-nerd
    #   "Material Symbols Rounded" <- ttf-material-symbols-variable (official 'extra',
    #                                 NOT the -git: -git Conflicts With this one)
    #   "Noto Color Emoji"         <- noto-fonts-emoji (emoji in what apps send:
    #                                 notification bodies, clipboard entries)
    ttf-jetbrains-mono-nerd ttf-material-symbols-variable noto-fonts-emoji
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk polkit-gnome
    # The shell Ashen actually ships. p10k is loaded from the distro package, so
    # there is no theme to clone; the plugins are sourced from /usr/share/zsh.
    # None of these was on any list before, which is why a fresh install's prompt
    # looked nothing like the one in the screenshots.
    zsh-autosuggestions zsh-syntax-highlighting
    # What the shipped aliases and keybindings reach for: ls->eza, cat->bat,
    # cd->zoxide, plus fzf's bindings and the fd it searches with.
    fzf zoxide eza bat fd
)

# AUR-only on vanilla Arch. CachyOS ships some in its own repos and the helper
# resolves those transparently.
# papirus-folders is deliberately NOT here: it re-runs itself under sudo, which a
# hardened sudoers refuses, and it only knows the colours Papirus ships.
# scripts/ashen-folders.sh replaced it.
PKGS_AUR=(
    # Checked against a clean Arch container and the AUR's own API on
    # 2026-09-07, because the lists had drifted in BOTH directions: awww and
    # matugen have landed in `extra` and are no longer in the AUR at all, while
    # mpvpaper and zsh-theme-powerlevel10k were sitting in the official list
    # and do not exist there -- they are AUR, and this machine only had them
    # because CachyOS ships them in its own repos.
    grimblast-git bibata-cursor-theme
    mpvpaper zsh-theme-powerlevel10k
)

SERVICES=(NetworkManager bluetooth power-profiles-daemon)

ASHEN_LOG="${ASHEN_LOG:-$HOME/.cache/ashen-install.log}"

PKG_OK=(); PKG_HAVE=(); PKG_FAILED=()

# Ashen is PipeWire-only. pipewire-pulse CONFLICTS WITH pulseaudio -- it does not
# Replace it -- so on any machine still running the old daemon the install stops
# dead. Swap it out first. libpulse is left alone: it is the client library apps
# link against, and pipewire-pulse uses it.
pkgs_drop_pulseaudio() {
    local installed
    installed=$(pacman -Qq pulseaudio pulseaudio-alsa pulseaudio-bluetooth \
        pulseaudio-jack pulseaudio-equalizer pulseaudio-zeroconf pulseaudio-lirc \
        pulseaudio-rtp 2>/dev/null)
    [ -z "$installed" ] && return 0
    if [ "${ASHEN_DRY:-0}" -eq 1 ]; then
        printf '  would remove PulseAudio: %s\n' "$(echo "$installed" | tr '\n' ' ')"
        return 0
    fi
    # shellcheck disable=SC2086
    sudo pacman -R --noconfirm $installed >>"$ASHEN_LOG" 2>&1
}

# One transaction per package. `pacman -S a b c` is atomic: one bad target and
# the other 46 never install, which is how a fresh machine ended up with no Nerd
# Font and nothing said about it.
pkgs_install() {
    local mgr=$1; shift
    local p n=$# i=0
    for p in "$@"; do
        i=$(( i + 1 ))
        # What the surface says while this runs: how far, and on what. The bar
        # is drawn from the same numbers, so the two cannot disagree.
        if declare -F tui_note >/dev/null; then
            tui_note "${TUI_PKG_STEP:-0}" "$(tui_bar "$i" "$n" 18)  $i/$n  $p"
        fi
        if [ "${ASHEN_DRY:-0}" -eq 1 ]; then
            printf '  would install  %s\n' "$p"
            PKG_OK+=("$p")
            continue
        fi
        if pacman -Q "$p" &>/dev/null; then
            PKG_HAVE+=("$p")
        elif $mgr --needed --noconfirm "$p" >>"$ASHEN_LOG" 2>&1; then
            PKG_OK+=("$p")
        else
            PKG_FAILED+=("$p")
            # Above the surface, so it is still there when the redraw moves on.
            declare -F tui_say >/dev/null && tui_say "${C_BAD}✗${RESET} $p — see the log"
        fi
    done
}

# Which AUR helper this machine has, if any.
pkgs_aur_helper() {
    local h
    for h in paru yay pikaur trizen; do
        command -v "$h" >/dev/null 2>&1 && { printf '%s -S' "$h"; return 0; }
    done
    return 1
}

pkgs_services() {
    local svc
    for svc in "${SERVICES[@]}"; do
        if [ "${ASHEN_DRY:-0}" -eq 1 ]; then
            printf '  would enable   %s\n' "$svc"; continue
        fi
        systemctl is-enabled --quiet "$svc" 2>/dev/null && continue
        sudo systemctl enable --now "$svc" >>"$ASHEN_LOG" 2>&1
    done
}

# /dev/video* is root:video rw----, so a webcam in a browser, in Discord, or in
# any screenshare-with-camera needs the user in the `video` group.
pkgs_video_group() {
    if id -nG "$USER" | tr ' ' '\n' | grep -qx video; then
        printf '  already in the video group\n'; return 0
    fi
    if [ "${ASHEN_DRY:-0}" -eq 1 ]; then
        printf '  would add %s to the video group\n' "$USER"; return 0
    fi
    sudo usermod -aG video "$USER" >>"$ASHEN_LOG" 2>&1
}

# What happened, named with its cause and with the command to retry it.
pkgs_report() {
    printf '\n  %s installed · %s already there · %s failed\n' \
        "${#PKG_OK[@]}" "${#PKG_HAVE[@]}" "${#PKG_FAILED[@]}"
    if [ "${#PKG_FAILED[@]}" -gt 0 ]; then
        printf '\n  failed:\n'
        printf '    %s\n' "${PKG_FAILED[@]}"
        printf '\n  retry with:\n    sudo pacman -S %s\n' "${PKG_FAILED[*]}"
    fi
    printf '\n  full log:  %s\n' "$ASHEN_LOG"
}

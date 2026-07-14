# Ashen

A monochrome Hyprland + Quickshell rice.

Hyprland · Quickshell · Kitty · Zsh + Powerlevel10k · PipeWire · matugen

---

<p align="center">
  <img src="https://github.com/user-attachments/assets/bbf668fc-dec3-41fc-b85b-98f470968e3b" width="49%" />
  <img src="https://github.com/user-attachments/assets/90688d3d-8a15-478d-bc21-243aa9ed7a71" width="49%" />
</p>
<p align="center">
  <img src="https://github.com/user-attachments/assets/2b3fd5b0-7691-42d9-9382-384ae500c49e" width="49%" />
  <img src="https://github.com/user-attachments/assets/4d62fbea-c0a3-459a-af28-d8ee252774bd" width="49%" />
</p>

## Requires

Official repos:
```
hyprland kitty zsh stow git base-devel
pipewire pipewire-pulse pipewire-alsa wireplumber
networkmanager bluez bluez-utils udisks2 upower
brightnessctl lm_sensors
wl-clipboard cliphist grim slurp wf-recorder
hypridle mpvpaper ffmpeg
nemo zenity fastfetch cava
papirus-icon-theme ttf-jetbrains-mono-nerd
qt6-base qt6-declarative
xdg-desktop-portal-hyprland polkit-gnome
```

AUR (via `paru` or similar):
```
quickshell-allflags-git awww matugen papirus-folders
bibata-cursor-theme ttf-material-symbols-variable-git grimblast-git
```

Plus [Oh My Zsh](https://ohmyz.sh) and [Powerlevel10k](https://github.com/romkatv/powerlevel10k) (not packaged, see their own install instructions).

> If your system locale created localized XDG user folders (e.g. `~/Imágenes` instead of `~/Pictures`), create the English ones manually — Ashen's scripts expect `~/Pictures/Wallpapers`, `~/Pictures/Screenshots` and `~/Videos` literally, regardless of system language:
> ```bash
> mkdir -p ~/Pictures/Wallpapers ~/Pictures/Screenshots ~/Videos
> ```

## Install

```bash
git clone git@github.com:AdolfLecompte/ashen.git ~/ashen
cd ~/ashen
stow -t ~ cava dconf fastfetch gtk hypr icons kitty matugen quickshell scripts sddm zsh
bash scripts/setup-system.sh
```

`setup-system.sh` also rewrites any hardcoded paths in the repo to match your `$HOME`, so it works regardless of username.

Set Zsh as your default shell if it isn't already (`chsh -s $(which zsh)`), enable `NetworkManager`, `bluetooth` and `sddm` (`systemctl enable --now ...`), then log in through SDDM selecting the Hyprland session.

## Usage

- `SUPER + SUPER_L` — launcher
- `SUPER + SHIFT + W` — wallpaper picker (drives Dynamic theming)
- `SUPER + I` — settings
- `SUPER + T` — terminal

## Status

Pre-1.0.0. SDDM theme is in the repo but not enabled by default yet.

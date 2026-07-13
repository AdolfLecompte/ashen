# Ashen

A monochrome Hyprland + Quickshell rice. One accent color ("ghost") over a grayscale palette, with optional dynamic theming from your wallpaper.

Hyprland · Quickshell · Kitty · Zsh + Powerlevel10k · PipeWire · matugen

---

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/bbf668fc-dec3-41fc-b85b-98f470968e3b" />

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/90688d3d-8a15-478d-bc21-243aa9ed7a71" />

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/2b3fd5b0-7691-42d9-9382-384ae500c49e" />

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/4d62fbea-c0a3-459a-af28-d8ee252774bd" />


## Install

```bash
git clone git@github.com:AdolfLecompte/ashen.git ~/ashen
cd ~/ashen
stow -t ~ cava dconf fastfetch gtk hypr icons kitty matugen quickshell scripts sddm zsh
bash scripts/setup-system.sh
```

Requires Hyprland, `quickshell-allflags-git`, `kitty`, `zsh`, `stow`, PipeWire, `awww`, `matugen`, `papirus-icon-theme` + `papirus-folders`, Bibata cursors, and a Nerd Font + Material Symbols Rounded. Most are on the official repos; the rest are on the AUR.

## Usage

- `SUPER + SUPER_L` — launcher
- `SUPER + SHIFT + W` — wallpaper picker (drives Dynamic theming)
- `SUPER + I` — settings
- `SUPER + T` — terminal

## Status

Pre-1.0.0. SDDM theme is in the repo but not enabled by default yet.

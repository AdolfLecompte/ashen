<div align="center">

<pre>
          ░   ░  ░    ░ ░   ░     ░    ░  ░ ░   ░           
   ░▒░                                               ░▒░    
  ░▒░     ░░░░░╗ ░░░░░░░╗░░╗  ░░╗░░░░░░░╗░░░╗   ░░╗    ░▒░  
 ░▒▓▒░   ░░╔══░░╗░░╔════╝░░║  ░░║░░╔════╝░░░░╗  ░░║   ░▒▓▒░ 
░▒▓█▓▒░  ▒▒▒▒▒▒▒║▒▒▒▒▒▒▒╗▒▒▒▒▒▒▒║▒▒▒▒▒╗  ▒▒╔▒▒╗ ▒▒║  ░▒▓█▓▒░
░▒▓█▓▒░  ▓▓╔══▓▓║╚════▓▓║▓▓╔══▓▓║▓▓╔══╝  ▓▓║╚▓▓╗▓▓║  ░▒▓█▓▒░
 ░▒▓▒░   ██║  ██║███████║██║  ██║███████╗██║ ╚████║   ░▒▓▒░ 
  ░▒░    ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝    ░▒░  
   ░▒▒░                                             ░▒▒░    
   ▓▓▒▒░░   a  g h o s t  i n  t h e  s h e l l   ░░▒▒▓▓    
</pre>

A monochrome Hyprland + Quickshell rice for Arch.

<img alt="compositor: Hyprland" src="https://img.shields.io/badge/compositor-Hyprland-81d3de?style=for-the-badge&labelColor=0e1415">

<img alt="last commit" src="https://img.shields.io/github/last-commit/AdolfLecompte/ashen?style=for-the-badge&label=last%20commit&labelColor=0e1415&color=252b2c&display_timestamp=author">
<img alt="stars" src="https://img.shields.io/github/stars/AdolfLecompte/ashen?style=for-the-badge&label=stars&labelColor=0e1415&color=81d3de">
<img alt="repo size" src="https://img.shields.io/github/repo-size/AdolfLecompte/ashen?style=for-the-badge&label=repo%20size&labelColor=0e1415&color=252b2c">
<img alt="license" src="https://img.shields.io/github/license/AdolfLecompte/ashen?style=for-the-badge&label=license&labelColor=0e1415&color=81d3de">

`Hyprland` · `Quickshell` · `Kitty` · `Zsh + Powerlevel10k` · `PipeWire` · `matugen`

</div>

---

## Install

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/AdolfLecompte/ashen/main/install/boot.sh)"
```

That line is the whole thing. What it does, in order:

1. **Checks this is Arch.** No pacman, no install — it says so and stops.
2. **Fetches the repo into `~/ashen`.** The directory is not yours to choose: the
   shell's Lua and `services/Paths.qml` look there by name, and a checkout called
   `Ashen` used to disagree with them in silence.
3. **Hands over to `install/run.sh`**, which is what actually installs. Everything
   below is that script.

### What the installer does

It draws five steps and rewrites them in place as it goes:

```
  ✓ packages      ██████████████████  60/60
  ▸ dotfiles      35 files linked
  · login screen
  · services
  · folders
```

- **Packages, one transaction each.** `pacman -S a b c` is atomic: one bad name
  and the other fifty-nine never install. That is how a fresh machine came up
  with no Nerd Font and nothing said about it. Here a package that fails is
  printed above the steps — so it survives the redraw — and named again at the
  end with the command to retry it.
- **Dotfiles**, by symlink from the checkout, so editing `~/.config/hypr/…` edits
  the repo and there is no second copy to keep in sync.
- **The login screen**, if `sddm` is installed. It is never switched blind: the
  theme has to declare `QtVersion=6`, the Qt6 greeter has to exist **and resolve
  its libraries**, and only then is `/etc/sddm.conf` repointed — with a backup,
  and with the command to undo it printed at the end.
- **Services** (`NetworkManager`, `bluetooth`, `power-profiles-daemon`), the
  `video` group, and the XDG folders the scripts expect by their English names.

It ends by asking you to **reboot** — this changed the login screen, enabled
system services and added you to a group, and a logout shows none of that.

### Flags

| Flag | Effect |
|---|---|
| `--dry-run` | says everything, touches nothing — not even its own log |

### If it is already installed

Run the same line again. That is the update: it fetches the repo and installs
whatever the new version needs, so new configs **and** the packages they depend
on arrive in one pass. Nothing is reinstalled if it is current, and a checkout
with local changes is not force-updated — the installer says so and carries on
with what is there.

### By hand

```bash
git clone https://github.com/AdolfLecompte/ashen.git ~/ashen
bash ~/ashen/install/run.sh
```

Same script, same result — `boot.sh` only does the two things above it.

**Clone to `~/ashen` and nowhere else.** The shell's Lua and its scripts call
each other by absolute path (`$HOME/ashen/scripts/…`), so the name is part of the
contract, not a preference.

Only the dotfiles, without the packages:

```bash
stow -t ~ cava dconf fastfetch gtk hypr kitty matugen quickshell wallpapers zsh
```

Or with no `stow` at all — `ashen-setup --link` makes the same symlinks, and
without `--link` it copies instead, which is what the package does on a machine
that has no checkout:

```bash
ASHEN_CONFIG_SRC=~/ashen ~/ashen/scripts/ashen-setup --link
```

Either way only the config packages are touched: `docs/`, `scripts/` and the rest
of the repo stay where they are. Then set Zsh as your shell
(`chsh -s $(which zsh)`), enable `NetworkManager`, `bluetooth` and
`power-profiles-daemon`, and start Hyprland from your display manager or a TTY.

> **The configs are symlinks into the checkout.** Editing `~/.config/hypr/…` or
> `~/.config/quickshell/ashen/…` edits the repo — there is no second copy to keep
> in sync, and no step that copies one over the other.

> **XDG folders are read by their English names.** If your locale made
> `~/Imágenes` instead of `~/Pictures`, make the English ones too: the scripts
> look for `~/Pictures/Wallpapers`, `~/Pictures/Screenshots` and `~/Videos`
> literally. The installer creates them for you.

## What's in it

A Quickshell shell (`quickshell/`) providing the bar, the panels and the lock
screen, driven by a Hyprland config written in **Lua** (`hypr/`).

- **Bar** — launcher, notifications, workspaces (incl. special workspaces), media,
  clock, tray, USB, screen recording, active window, keyboard layout, network,
  bluetooth, sound, battery, CPU and memory, power. Every capsule can be dragged
  to either end or the centre of any of the four edges, and each one chooses how
  much it says — `full`, `compact` or `icon`, offered only where they differ.
  Four shapes for the bar itself — pills, island, solid, framed — and an outline
  switch that draws the plate of whichever shape is in use instead of filling it.
- **Dock** — pinned and open applications on an edge of your choosing. A click
  launches, focuses, or hides to a special workspace, in that order; a
  right-click pins or unpins, and Settings has the list with a search.
- **Panels** — every pill opens a panel that grows out of it and leaves the same
  way. Their own outline switch, separate from the bar's.
- **Lock screen** — its own `WlSessionLock` surface: padlock intro, PAM auth,
  blurred wallpaper, media card with a live Cava visualiser, battery and power
  profiles.
- **Login screen** — an SDDM theme drawn with the shell's own bar and mark.
- **Desktop widgets** — clock, weather, updates, media, calendar, machine, placed
  by dragging them where you want them. Outline switch of their own too.
- **Game mode** — one key flattens the compositor (no animations, blur, shadows,
  rounding or gaps) and quiets the shell, then puts everything back exactly as it
  was, your screen layout included.
- **Wallpapers** — a picker you can search, video or still, and a different
  wallpaper on each screen when more than one is plugged in.
- **Process monitor** — CPU, GPU and traffic drawn as the last minute of samples,
  memory, drives and temperatures as levels.
- **Launcher, clipboard, emoji picker, glyph picker, settings.**
- **Four languages** — English, Spanish, Russian and German, switched on the spot.
- **Dynamic theming** — the wallpaper picker runs `matugen` over the image you
  choose and the whole shell re-colours from `~/.cache/ashen_scheme.json`.

## Requires

Everything below is what the shell actually shells out to. Missing one degrades a
specific feature rather than breaking the shell, except where noted.

### Official repos

```
hyprland kitty zsh git base-devel
qt6-base qt6-declarative qt6-5compat quickshell pipewire
pipewire-pulse pipewire-alsa wireplumber libpulse networkmanager
bluez bluez-utils udisks2 upower power-profiles-daemon
brightnessctl lm_sensors pciutils wl-clipboard cliphist
grim slurp wf-recorder hypridle ffmpeg
wlsunset awww matugen nemo
fastfetch cava xdg-utils libnotify curl
imagemagick pacman-contrib python gtk3 qt6ct
papirus-icon-theme adw-gtk-theme ttf-jetbrains-mono-nerd ttf-material-symbols-variable noto-fonts-emoji
xdg-desktop-portal-hyprland xdg-desktop-portal-gtk polkit-gnome zsh-autosuggestions zsh-syntax-highlighting
fzf zoxide eza bat fd
```

`qt6-5compat` is **required**, not optional: the shell imports
`Qt5Compat.GraphicalEffects` for the blur and the rounded image masks.

### AUR (via `paru`, `yay`, …)

```
grimblast-git bibata-cursor-theme mpvpaper zsh-theme-powerlevel10k
```

- **quickshell** must be built with **PAM** and the **Hyprland** modules — the lock
  screen authenticates through `PamContext` (config `login`) and the bar reads
  workspaces over Hyprland IPC. `quickshell-allflags-git` also works.
- **ttf-material-symbols-variable** is required: every icon in the shell is a
  Material Symbols Rounded codepoint. Without it the bar renders empty boxes.
- **awww** paints static images and gifs, **mpvpaper** paints video wallpapers.
  awww and matugen are in `extra` now; mpvpaper and the p10k theme are not, which
  is why they sit in the AUR list — checked against a clean Arch container, not
  against the machine this was written on, where CachyOS ships both in its own
  repos.

The shell is built on packages and nothing else: **zsh-theme-powerlevel10k**,
**zsh-autosuggestions** and **zsh-syntax-highlighting** are installed for you, so
there is nothing to clone and nothing to keep pulled. The shipped `.zshrc` sources
the prompt from the package itself, which is what makes it appear on plain Arch
and not only on a distro that happens to source it for you.

### What each command is used for

| Command | Feature that needs it |
|---|---|
| `hyprctl` | workspaces, window rules, keyboard layout switching |
| `wpctl` / `pactl` | volume, mute, output device, headphone detection |
| `brightnessctl` | brightness pill and OSD |
| `nmcli` | wifi/ethernet pill and network panel |
| `bluetoothctl` | bluetooth pill and panel |
| `powerprofilesctl` | power profile switcher (bar, settings, lock screen) |
| `upower` | battery time-remaining estimate |
| `udisksctl` / `lsblk` | USB pill: mount, unmount, eject |
| `cliphist` + `wl-copy` / `wl-paste` | clipboard history panel |
| `grimblast` | screenshots |
| `wf-recorder` + `ffmpeg` | screen recording |
| `cava` | audio visualiser (bar background, media panel, lock screen) |
| `awww` / `mpvpaper` / `matugen` | wallpapers (one per screen) and dynamic colour scheme |
| `hypridle` | idle → lock |
| `sddm` | the login screen — **optional and never installed for you**: switching a display manager is not the installer's call. Already have it? The theme is installed and pointed at. |
| `wlsunset` | night light (blue-light filter), manual and scheduled |
| `lm_sensors` | temperatures in the process panel |
| `curl` | cover art and lyrics for the playing track |
| `magick` (imagemagick) | thumbnails in the wallpaper and picture pickers |
| `checkupdates` (pacman-contrib) | pending-updates readout and its widget |
| `python` | the cover-art picker |
| `gtk-launch` (gtk3) | opening the app behind a notification action |
| `qt6ct` | Qt apps follow the palette (`QT_QPA_PLATFORMTHEME`) |
| `nvidia-utils` (`nvidia-smi`) | dGPU stats — **only** read when the GPU is already awake |

## Update

Re-run the install line. There is no second command, and no `git pull`: a pull
alone brings new configs without the packages they need, which is a shell that
half-starts.

One thing the installer cannot do for you: if you use one of the **fixed colour
schemes** instead of Dynamic, pick it again in Settings > Look after updating.
That palette is written by the shell itself, so a script cannot regenerate it.

### Coming from a much older version

Installs from before **1.5.1** rewrote the working tree at install time (an
install-time `sed` that is long gone), so their clone is dirty — and a dirty
tree is exactly what makes the self-update above skip itself, quietly leaving
you on the old code. Throw those local edits away first:

```bash
cd ~/ashen
git status                       # anything listed here is about to be discarded
git fetch origin
git reset --hard origin/main     # or `git stash` if you actually wrote something
bash install/run.sh
```

Two things to expect on that first run:

- **stow may report a conflict for a package.** That means a real file — not a
  symlink — is sitting where a config belongs; `~/.zshrc` is the usual one.
  Move it aside (`mv ~/.zshrc ~/.zshrc.mine`) and re-run. Only the package that
  conflicts is skipped, the other eight still land.
- **Log out and back in** afterwards if the bar looks half-dressed: an old
  session is still holding the previous Hyprland config and the old
  environment.

## Usage

| Keys | Action |
|---|---|
| `SUPER` (tap) | launcher |
| `SUPER + SHIFT + W` | wallpaper picker (drives dynamic theming) |
| `SUPER + I` | settings |
| `SUPER + T` | terminal |
| `SUPER + N` | notifications |
| `SUPER + SHIFT + V` | clipboard |
| `SUPER + SHIFT + S` | screenshot |
| `SUPER + SHIFT + R` | start / stop screen recording |
| `SUPER + SHIFT + G` | game mode |
| `SUPER + SHIFT + P` | process monitor |
| `SUPER + SHIFT + D` | arrange desktop widgets |
| `SUPER + L` | lock |
| `SUPER + Escape` | power menu |

Every one of these can be changed from **Settings → Input**.

The keyboard layout pill in the bar is **read-only**. Layouts are declared in
`hypr/.config/hypr/conf/input.lua` (`kb_layout = "us"`) and switched from
**Settings → System → Keyboard**.

## Notes

- The Hyprland config is **Lua** (`hyprland.lua` + `conf/*.lua`), not `hyprland.conf`.
  `hyprctl keyword` does **not** work against it — use `hyprctl eval '<lua>'` to try
  things at runtime.
- Shell IPC: `qs -c ashen ipc show` lists every callable target.
- Reload the shell with `pkill quickshell; setsid nohup quickshell -c ashen &`.
- Window opacity: a `windowrule` opacity value is **multiplied** by
  `active_opacity`/`inactive_opacity` unless you append `override`. That is why the
  browser rule reads `opacity 0.85 override 0.80 override`.

## Getting your bearings

The first time the shell runs it opens a welcome card with the keys that matter.
It comes back with `ashen-welcome`, and `ashen-welcome notes` shows what changed
in the version you are running — the same notes as `CHANGELOG.md`, because it
reads that file.

`ashen-widgets` does the same job for the desktop: `ashen-widgets` toggles the
editor, `ashen-widgets list` says what is out there and where.

## Status

3.1.0

## License

**GPL-3.0-or-later** — see [LICENSE](LICENSE).

Use it, change it, ship it. If you distribute it or anything built on it, that
has to come with its source and under this same licence: it stays free for
whoever gets it next. Charging for it is allowed; closing it is not.

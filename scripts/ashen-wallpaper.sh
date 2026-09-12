#!/usr/bin/env bash
# ── Ashen — wallpaper setter ──────────  by Adolf — github.com/AdolfLecompte ──
#    Handles both kinds of wallpaper behind a single entry point:
#      · still images + gif  ->  awww (its daemon animates gifs on its own)
#      · video (mp4/webm/mkv) ->  mpvpaper
#    Both draw on the background layer, but each mpvpaper surface is opaque and
#    covers only ITS OWN output, so a video on one screen and a still on another
#    coexist. What cannot coexist on the SAME output is the two of them.
#
#    Per-output. mpvpaper takes one output per process ("ALL" is its own special
#    value), so a screen that wants its own clip means a process per screen --
#    which is why ALL is gone from here and everything expands to the list of
#    connected monitors.
#
#    Dynamic palette: matugen only accepts stills, so for video/gif we hand it
#    a frame pulled with ffmpeg instead of the wallpaper itself.
#
#    usage: ashen-wallpaper.sh <path> [--output <NAME>] [--palette]
#      no --output    every connected screen, and the palette follows
#      --output X     that screen alone; --palette only if the caller says so,
#                     because WHICH screen is primary is the shell's decision
#                     (Displays.primaryKey) and nothing bash can read.
#      --palette-only refresh the shared frame and the colours from <path>
#                     without painting anything. The restore uses it: the
#                     screens are already back, only the palette is missing.
# ─────────────────────────────────────────────────────────────────────────
set -uo pipefail

# Sibling scripts are resolved next to this one, so the set works from the
# checkout and from /usr/bin alike.
HERE="$(dirname "$(readlink -f "$0")")"

WALL="${1:?usage: ashen-wallpaper.sh <path> [--output <NAME>] [--palette]}"
shift
[ -f "$WALL" ] || { echo "ashen-wallpaper: no such file: $WALL" >&2; exit 1; }

OUTPUT=""
PALETTE=0
PAINT=1
while [ $# -gt 0 ]; do
    case "$1" in
        --output) OUTPUT="${2:-}"; shift 2 ;;
        --palette) PALETTE=1; shift ;;
        --palette-only) PALETTE=1; PAINT=0; shift ;;
        *) echo "ashen-wallpaper: unknown argument: $1" >&2; exit 1 ;;
    esac
done
# Painting every screen IS the palette decision: there is no other screen to
# disagree with.
[ -n "$OUTPUT" ] || PALETTE=1

CACHE="$HOME/.cache"
FRAME="$CACHE/ashen_wall_frame.png"
FRAMES="$CACHE/ashen_frames"
STATE="$CACHE/ashen_wallpaper.txt"
# One line per screen, "<key>TAB<path>". A file and not a directory because
# FileView watches files, and services/Wallpaper.qml is what reads this.
STATES="$CACHE/ashen_wallpapers.txt"
OPT="$CACHE/ashen_wall_optimized"

is_video() {
    case "${1,,}" in
        *.mp4|*.webm|*.mkv|*.mov) return 0 ;;
        *) return 1 ;;
    esac
}

# matugen chokes on video and animated gif: give it a still frame instead
needs_frame() {
    case "${1,,}" in
        *.png|*.jpg|*.jpeg|*.webp) return 1 ;;
        *) return 0 ;;
    esac
}

# ── Who is out there ─────────────────────────────────────────────────────
# "<name>TAB<width>TAB<height>TAB<description>" per CONNECTED screen. Plain
# `hyprctl monitors` on purpose: `monitors all` keeps an output whose cable was
# pulled, and painting a wallpaper on one of those is painting on nothing.
monitor_table() {
    hyprctl monitors 2>/dev/null | awk '
        /^Monitor /             { name = $2; w = ""; h = "" }
        /^[ \t]+[0-9]+x[0-9]+@/ { split($1, m, "@"); split(m[1], r, "x"); w = r[1]; h = r[2] }
        /^[ \t]+description: /  { d = $0; sub(/^[ \t]*description: /, "", d)
                                  if (name != "") printf "%s\t%s\t%s\t%s\n", name, w, h, d }
    '
}

# A screen is its DESCRIPTION, never its name: HDMI-A-1 is handed out by port
# order and moves between reboots. Same rule as Displays.keyOf() in the shell,
# and the same fallback for a headless output with no description at all.
key_of() { [ -n "${2:-}" ] && printf '%s' "$2" || printf '%s' "$1"; }

# ── Remembering what each screen wears ───────────────────────────────────
state_get() {
    [ -f "$STATES" ] || return 0
    awk -F'\t' -v k="$1" '$1 == k { print $2; exit }' "$STATES"
}

# Writes <key> -> <path>, leaving every other screen's line alone.
state_set() {
    local key="$1" path="$2" tmp
    tmp="$(mktemp)" || return 0
    [ -f "$STATES" ] && awk -F'\t' -v k="$key" '$1 != k' "$STATES" > "$tmp"
    printf '%s\t%s\n' "$key" "$path" >> "$tmp"
    mv -f "$tmp" "$STATES"
}

# ── Video ────────────────────────────────────────────────────────────────
# Sites like moewalls ship 4K60 clips. On a 1080p panel that decodes four times
# the pixels you can actually see and drops frames non-stop, so anything larger
# than the screen it is going on gets downscaled once and cached. The original
# file is never touched. The target size rides in the cache name: two screens of
# different sizes are two different downscales of the same clip.
optimized_video() {
    local src="$1" mw="$2" mh="$3"
    local cached="$OPT/$(basename "${src%.*}")-${mw}x${mh}-opt.mp4"

    if [ -f "$cached" ] && [ "$cached" -nt "$src" ]; then
        printf '%s' "$cached"
        return
    fi

    local sw sh
    read -r sw sh <<< "$(ffprobe -v error -select_streams v:0 \
        -show_entries stream=width,height -of csv=p=0 "$src" 2>/dev/null | tr ',' ' ')"
    [ -n "${sw:-}" ] && [ -n "${sh:-}" ] || { printf '%s' "$src"; return; }

    # Already fits the screen: play it as-is
    if [ "$sw" -le "$mw" ] && [ "$sh" -le "$mh" ]; then
        printf '%s' "$src"
        return
    fi

    mkdir -p "$OPT"
    notify-send -a Ashen -i video-x-generic "Wallpaper" \
        "Optimizing ${sw}x${sh} video to ${mw}x${mh}…" 2>/dev/null

    if ffmpeg -y -loglevel error -i "$src" \
        -vf "scale=${mw}:${mh}:flags=lanczos,fps=30" \
        -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p -an \
        -movflags +faststart "$cached" 2>/dev/null
    then
        notify-send -a Ashen -i video-x-generic "Wallpaper" "Video optimized" 2>/dev/null
        printf '%s' "$cached"
    else
        # Transcode failed: fall back to the original rather than showing nothing
        rm -f "$cached"
        printf '%s' "$src"
    fi
}

# Kills the mpvpaper painting $1 -- empty kills every one of them. Which process
# owns which screen is read off the process itself rather than kept in pid files
# that go stale the first time one crashes. An "ALL" process is painting this
# screen too, so it always dies.
kill_video() {
    local want="${1:-}" pid out
    local -a args
    for pid in $(pgrep -x mpvpaper 2>/dev/null); do
        mapfile -d '' -t args < "/proc/$pid/cmdline" 2>/dev/null || continue
        # mpvpaper [options] <output> <path>
        out="${args[-2]:-}"
        [ -z "$want" ] || [ "$out" = "ALL" ] || [ "$out" = "$want" ] || continue
        kill "$pid" 2>/dev/null
    done
}

# ── Frames ───────────────────────────────────────────────────────────────
# Deterministic per-wallpaper frame path. basename keeps it legible; a cksum of
# the full path disambiguates same-named files living in different folders.
frame_for() {
    local src="$1"
    printf '%s/%s-%s.png' "$FRAMES" \
        "$(basename "${src%.*}")" \
        "$(printf '%s' "$src" | cksum | cut -d' ' -f1)"
}

# Pull a still frame from a video/gif wallpaper and print where it landed. Three
# consumers need it: the video bridge below, matugen (accepts stills only) and
# the lock screen, which can't draw a moving background layer. Runs regardless
# of colour mode, so the lock frame stays in sync with the wallpaper even when
# the dynamic palette is off.
#
# The still is cached permanently, keyed to the wallpaper, so a re-switch to a
# clip used before skips ffmpeg entirely and the bridge can paint with no decode
# latency.
ensure_frame() {
    local src="$1" persist
    needs_frame "$src" || { printf '%s' "$src"; return; }
    persist="$(frame_for "$src")"

    # Regenerate only when missing or older than the source file
    if [ ! -f "$persist" ] || [ "$src" -nt "$persist" ]; then
        mkdir -p "$FRAMES"
        # 2s in, so we skip fade-ins that would sample as pure black
        ffmpeg -y -loglevel error -ss 2 -i "$src" -frames:v 1 "$persist" 2>/dev/null \
            || ffmpeg -y -loglevel error -i "$src" -frames:v 1 "$persist" 2>/dev/null
    fi
    [ -f "$persist" ] && printf '%s' "$persist"
}

# ── Painting ─────────────────────────────────────────────────────────────
# Every visible transition awww ships except the plain fade -- one is rolled at
# random per switch. awww's own 'random' can't be filtered, so we curate here.
# Edit this list to add/drop effects.
TRANSITIONS=(left right top bottom wipe wave grow center any outer)

# Paint a still on the awww layer of one output: start the daemon if needed,
# then hand awww a random transition from the pool above.
paint() {
    local out="$1" img="$2"
    pgrep -x awww-daemon >/dev/null || { setsid awww-daemon >/dev/null 2>&1 < /dev/null & sleep 0.4; }
    local t="${TRANSITIONS[RANDOM % ${#TRANSITIONS[@]}]}"
    awww img "$img" --outputs "$out" \
        --transition-type "$t" --transition-duration 0.6 --transition-fps 60 2>/dev/null
}

# Put $2 on screen $1, whatever kind of wallpaper it is. $3/$4 are that screen's
# pixels, for the video downscale.
paint_output() {
    local out="$1" wall="$2" mw="$3" mh="$4" still play

    if is_video "$wall"; then
        command -v mpvpaper >/dev/null || {
            echo "ashen-wallpaper: mpvpaper not installed (paru -S mpvpaper)" >&2
            return 1
        }
        play="$(optimized_video "$wall" "$mw" "$mh")"
        still="$(ensure_frame "$wall")"

        # Bridge the gap while mpvpaper spins up libmpv (~1s): paint the still
        # frame first -- over whatever is currently showing -- then start the
        # video on top of it, so the empty Hyprland background never flashes
        # through. The frame is a still of this very clip, so the hand-off from
        # still to motion is seamless.
        [ -n "$still" ] && [ -f "$still" ] && paint "$out" "$still"
        kill_video "$out"
        # mpvpaper only supports the libmpv vo, so no vo= here.
        # panscan fills the screen instead of letterboxing an odd aspect ratio.
        # -p stops mpv decoding while the wallpaper is covered, which is what
        # keeps N screens of video from costing N decoders all the time.
        setsid mpvpaper -p -o "no-audio loop hwdec=auto panscan=1.0" \
            "$out" "$play" >/dev/null 2>&1 < /dev/null &
        # Leave the awww daemon alive holding the bridge frame under the opaque
        # mpvpaper surface -- it costs nothing (a static layer the compositor
        # skips) and it means a later switch to a still can paint on an already
        # running daemon and reveal it without a restart gap.
    else
        # Paint the new still on the awww layer *before* removing the video.
        # mpvpaper sits above awww, so the swap stays hidden until awww has
        # committed its frame underneath; only then do we kill mpvpaper,
        # revealing the still with no window where Hyprland's empty background
        # could flash through. The short settle gives awww time to buffer its
        # first frame before the reveal.
        paint "$out" "$wall"
        sleep 0.3
        kill_video "$out"
    fi
}

apply_colors() {
    [ "$(cat "$CACHE/ashen_scheme_mode.txt" 2>/dev/null)" = "dynamic" ] || return 0

    local src="$1"
    local type
    type="$(cat "$CACHE/ashen_dynamic_type.txt" 2>/dev/null || echo scheme-tonal-spot)"
    # Light or dark, chosen in Settings > Appearance. Dark unless told otherwise.
    mode="$(cat "$CACHE/ashen_theme_mode.txt" 2>/dev/null)"
    [ "$mode" = "light" ] || mode="dark"
    matugen image "$src" --mode "$mode" --source-color-index 0 --type "$type"
    # Order matters: the accent has to be resolved and substituted into what
    # matugen just wrote before anything reads those files, the border included.
    "$HERE/ashen-accent.sh"
    # The folders follow the accent too, but only if they were already wearing it.
    "$HERE/ashen-folders.sh" >/dev/null 2>&1
    "$HERE/ashen-apply-border.sh"
}

# ── Go ───────────────────────────────────────────────────────────────────
if [ "$PAINT" -eq 1 ]; then
    PAINTED=0
    while IFS=$'\t' read -r name w h desc; do
        [ -n "$name" ] || continue
        [ -z "$OUTPUT" ] || [ "$OUTPUT" = "$name" ] || continue
        paint_output "$name" "$WALL" "${w:-1920}" "${h:-1080}" || continue
        state_set "$(key_of "$name" "$desc")" "$WALL"
        PAINTED=$((PAINTED + 1))
    done < <(monitor_table)

    if [ "$PAINTED" -eq 0 ]; then
        echo "ashen-wallpaper: no screen to paint${OUTPUT:+ (no such output: $OUTPUT)}" >&2
        exit 1
    fi
fi

# The shared frame and the single-path state belong to the screen the colours
# come from: the lock screen and matugen read exactly one wallpaper, and this
# says which. A secondary screen changes its own line and nothing else.
if [ "$PALETTE" -eq 1 ]; then
    STILL="$(ensure_frame "$WALL")"
    # For a still wallpaper ensure_frame hands back the wallpaper itself, and
    # copying a jpg over a path everyone reads as a png helps nobody: the shared
    # frame only exists for the wallpapers QML cannot draw.
    if needs_frame "$WALL" && [ -n "$STILL" ] && [ -f "$STILL" ]; then
        cp -f "$STILL" "$FRAME"
    fi
    apply_colors "$STILL"
    printf '%s' "$WALL" > "$STATE"
fi

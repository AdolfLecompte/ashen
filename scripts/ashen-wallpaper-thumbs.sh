#!/usr/bin/env bash
# ── Ashen — wallpaper index for the picker ───────────────────────────────
#    Prints every wallpaper found, one per line, and THEN caches a thumb for
#    each one in ~/.cache/ashen_wall_thumbs/<name>.jpg. The list goes out
#    first so the picker opens at once; the picker falls back to the original
#    file while a thumb is still missing (videos have no fallback -- QML's
#    Image cannot decode them, which is why the cache started here).
# ─────────────────────────────────────────────────────────────────────────
set -uo pipefail

# The folder is settable from Settings > Appearance; the default stays put
# so the script keeps working when run by hand with no arguments.
DIR="${1:-$HOME/Pictures/Wallpapers}"
THUMBS="$HOME/.cache/ashen_wall_thumbs"
# Wide enough that the card in front still scales DOWN. It is as wide as its
# picture now -- ~820 px for a 16:9 wallpaper at the card's height -- and on a
# HiDPI panel that is well past 1000 real pixels.
THUMB_W=1400
mkdir -p "$THUMBS"

# The cache carries the width it was baked at. Raising THUMB_W used to leave
# every old thumb in place -- the picker kept showing 360px stills on a 370px
# card, which is exactly as blurry as it sounds.
STAMP="$THUMBS/.width"
if [ "$(cat "$STAMP" 2>/dev/null)" != "$THUMB_W" ]; then
    rm -f "$THUMBS"/*.jpg
    printf '%s\n' "$THUMB_W" > "$STAMP"
fi

mapfile -t FILES < <(find "$DIR" -maxdepth 2 -type f \
    \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \
       -o -iname '*.gif' -o -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' -o -iname '*.mov' \) \
    | sort)

# Pass 1: the list, then close stdout so the caller stops waiting on us.
for f in "${FILES[@]}"; do printf '%s\n' "$f"; done
exec 1>&-

# Pass 2: only what is missing or older than its source.
for f in "${FILES[@]}"; do
    thumb="$THUMBS/$(basename "$f").jpg"
    [ -f "$thumb" ] && [ ! "$f" -nt "$thumb" ] && continue
    case "${f,,}" in
        *.mp4|*.webm|*.mkv|*.mov)
            ffmpeg -y -loglevel error -ss 2 -i "$f" -frames:v 1 -vf "scale='min($THUMB_W,iw)':-1" "$thumb" 2>/dev/null \
                || ffmpeg -y -loglevel error -i "$f" -frames:v 1 -vf "scale='min($THUMB_W,iw)':-1" "$thumb" 2>/dev/null
            ;;
        *)
            # [0] takes the first frame, so animated gifs give one still.
            magick "$f[0]" -resize "${THUMB_W}x>" -quality 82 "$thumb" 2>/dev/null
            ;;
    esac
done

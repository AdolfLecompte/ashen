#!/usr/bin/env bash
# The login screen's face: ~/.face as a round PNG, in the one folder the sddm
# user can read (a home is drwx------). It is rounded here, not in the theme: a
# mask is a shader effect, and a greeter on software rendering draws none.
# Quiet no-op when there is no photo, no folder or no ImageMagick.
set -eu
src="$HOME/.face"
dir="$HOME/.cache/ashen-sddm"
[ -f "$src" ] && [ -d "$dir" ] || exit 0
command -v magick >/dev/null 2>&1 || exit 0

tmp="$dir/.face.tmp.png"
magick "$src[0]" -resize 256x256^ -gravity center -extent 256x256 -alpha set \
    \( -size 256x256 xc:none -fill white -draw "circle 128,128 128,0" \) \
    -compose DstIn -composite "$tmp"
mv -f "$tmp" "$dir/face.png"

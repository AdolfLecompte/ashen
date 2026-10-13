#!/usr/bin/env bash
# The mark: ANSI Shadow with the block faces fading into smoke, and the 3D edges
# left solid -- they are what keeps it legible where the faces are already ░.
ashen_logo() {
cat <<'ART'
    ░░░░░╗ ░░░░░░░╗░░╗  ░░╗░░░░░░░╗░░░╗   ░░╗
   ░░╔══░░╗░░╔════╝░░║  ░░║░░╔════╝░░░░╗  ░░║
   ▒▒▒▒▒▒▒║▒▒▒▒▒▒▒╗▒▒▒▒▒▒▒║▒▒▒▒▒╗  ▒▒╔▒▒╗ ▒▒║
   ▓▓╔══▓▓║╚════▓▓║▓▓╔══▓▓║▓▓╔══╝  ▓▓║╚▓▓╗▓▓║
   ██║  ██║███████║██║  ██║███████╗██║ ╚████║
   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝
ART
}

# On a terminal the faces take the accent and the edges sit dim: the same two
# layers the shell's AshenMark draws. Plain rows stay plain for pipes and probes.
ashen_logo_tinted() {
    ashen_logo | sed -E $'s/((░|▒|▓|█)+)/\e[35m\\1/g; s/((╗|╔|║|═|╝|╚)+)/\e[2;37m\\1\e[0m/g; s/$/\e[0m/'
}

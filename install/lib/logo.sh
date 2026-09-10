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

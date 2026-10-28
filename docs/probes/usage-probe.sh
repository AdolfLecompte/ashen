#!/usr/bin/env bash
# Screen time books its spans right: across midnight, across hours, adding up.
set -uo pipefail
cd "$(dirname "$0")"
QT_QPA_PLATFORM=offscreen timeout 20 qml6 usage-probe.qml >/dev/null 2>&1
code=$?
if [ "$code" -eq 0 ]; then printf 'ok   usage books spans across midnight and hours\n'; exit 0; fi
printf 'FAIL usage-probe.qml case %s\n' "$code"; exit 1

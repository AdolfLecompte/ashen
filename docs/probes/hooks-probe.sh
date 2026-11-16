#!/usr/bin/env bash
# The shell arms its hooks at start. (That the Hooks page of the website names every event is
# checked by the website's own tests, in the AdolfLecompte.github.io repo.)
set -uo pipefail
cd "$(dirname "$0")/../.."
fail=0
say() { printf '%-4s %s\n' "$1" "$2"; }
grep -q 'Services.Hooks.arm()' quickshell/.config/quickshell/ashen/modules/ServiceLoader.qml \
    && say ok "hooks are armed at start" || { say FAIL "Hooks.arm() not called"; fail=1; }
exit $fail

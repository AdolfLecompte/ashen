#!/usr/bin/env bash
# Every hook event the shell fires is documented in the README.
set -uo pipefail
cd "$(dirname "$0")/../.."
fail=0
say() { printf '%-4s %s\n' "$1" "$2"; }
h=quickshell/.config/quickshell/ashen/services/Hooks.qml
missing=""
for e in $(grep -o '"[a-z-]*"' <<<"$(sed -n '/readonly property var events/,/]/p' "$h")" | tr -d '"'); do
    sed -n "/^### Hooks/,/^## /p" README.md | grep -q "\`$e\`" || missing="$missing $e"
done
[ -z "$missing" ] && say ok "every hook event is in the README" || { say FAIL "undocumented:$missing"; fail=1; }
grep -q 'Services.Hooks.arm()' quickshell/.config/quickshell/ashen/modules/ServiceLoader.qml \
    && say ok "hooks are armed at start" || { say FAIL "Hooks.arm() not called"; fail=1; }
exit $fail

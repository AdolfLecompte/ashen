#!/usr/bin/env bash
# The utility pill is gone when nothing names its machinery any more.
set -uo pipefail
cd "$(dirname "$0")/../../quickshell/.config/quickshell/ashen"
fail=0
for sym in "Pills.tools" "isTool" "utilEdge" "setChipRect" "chipEdgeOf" \
           "SourceEdge" "utilPillLen" "utilPillThick" "UtilChip"; do
    hits=$(grep -rn -- "$sym" . 2>/dev/null | wc -l)
    if [ "$hits" -ne 0 ]; then
        printf 'FAIL %-16s still named %s times\n' "$sym" "$hits"; fail=1
    else
        printf 'ok   %-16s gone\n' "$sym"
    fi
done
exit $fail

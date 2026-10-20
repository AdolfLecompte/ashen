#!/usr/bin/env bash
# The bar's spec and the docked style.
#
# Every pill paints with the bar's spec (Sizes.first). The second bar was
# tried in 3.6 and removed: the dock covers that ground. "framed" is gone:
# "docked" took its place, and old profiles migrate.
set -uo pipefail
cd "$(dirname "$0")/../.."
fail=0
say() { printf '%-4s %s\n' "$1" "$2"; }
check() { if eval "$2"; then say ok "$1"; else say FAIL "$1"; fail=1; fi }

r=quickshell/.config/quickshell/ashen

# ── Data ──
check "no second bar left in the code" "! grep -rq 'bar2\|Sizes\.second\|left2\|setBar2' $r/services $r/modules $r/shell.qml"
check "three bar sections" "grep -q 'sectionIds: \[\"left\", \"centre\", \"right\"\]' $r/services/Prefs.qml"
check "an old layout's bar-2 pills go home" "grep -q 'const orphans' $r/services/Prefs.qml"
check "framed migrates to docked" "grep -q 'function migrateStyle' $r/services/Prefs.qml"
check "no framed left outside the migration" \
    "[ -z \"\$(grep -rn '\"framed\"' $r/services $r/modules $r/shell.qml | grep -v migrateStyle | grep -v 'framed.*docked')\" ]"

# ── Specs ──
check "BarSpec exists and is registered" "[ -f $r/services/BarSpec.qml ] && grep -q '^BarSpec ' $r/services/qmldir"
check "Sizes has the bar's spec" "grep -q 'property BarSpec first' $r/services/Sizes.qml"
check "Sizes answers edgeAt" "grep -q 'function edgeAt' $r/services/Sizes.qml"
check "barFramed is gone" "! grep -rq 'barFramed' $r/services $r/modules $r/shell.qml"

# ── Bars ──
check "BarFrame is gone" "[ ! -f $r/modules/bar/BarFrame.qml ]"
check "shell builds one bar" "[ \$(grep -c '^    Bar ' $r/shell.qml) -eq 1 ]"
missing=""
for f in $r/modules/bar/components/*.qml; do
    if grep -q 'Pills\.fills\|pillPlate\|Pills\.isOutlined' "$f" && ! grep -q 'property var spec' "$f"; then
        missing="$missing $(basename "$f")"
    fi
done
check "every painted pill knows its bar${missing:+ (missing:$missing)}" "[ -z '$missing' ]"

# ── Settings ──
for l in en es de ru; do
    check "$l names docked" "grep -q '\"settings.bar.docked\"' $r/i18n/$l.json"
    check "$l dropped framed" "! grep -q '\"settings.bar.framed\"' $r/i18n/$l.json"
    check "$l dropped the second bar" "! grep -q '\"settings.bar.second\"' $r/i18n/$l.json"
done

# ── Dock ──
check "DockItems is registered" "grep -q '^singleton DockItems ' $r/services/qmldir"
check "Prefs keeps dock pills and links" "grep -q 'property string dockPills' $r/services/Prefs.qml && grep -q 'property string dockLinks' $r/services/Prefs.qml"
for l in en es de ru; do
    check "$l names the dock's shortcuts" "grep -q '\"dock.action.nightlight\"' $r/i18n/$l.json"
done

# ── Panels ──
check "DropCard asks which bar" "grep -q 'edgeAt(' $r/modules/widgets/DropCard.qml"
check "MorphCard asks which bar" "grep -q 'edgeAt(' $r/modules/widgets/MorphCard.qml"

exit $fail

#!/usr/bin/env bash
# The login screen. Three things have already broken here twice, so they are
# asserted rather than looked at: the PUA glyphs vanish whenever the file is
# rewritten, SddmComponents makes SDDM fall back to its default in silence, and
# the mark's rows drift from the ones the terminal prints.
set -uo pipefail
cd "$(dirname "$0")/../.."
fail=0
say() { printf '%-4s %s\n' "$1" "$2"; }

main=sddm/ashen/Main.qml
conf=sddm/ashen/theme.conf

[ -f "$main" ] && say ok "theme present" || { say FAIL "$main missing"; exit 1; }

grep -q 'import SddmComponents' "$main" \
  && { say FAIL "imports SddmComponents -- SDDM will fall back to its default"; fail=1; } \
  || say ok "no SddmComponents"

# Every glyph is a private-use codepoint; an empty string is what a lost glyph
# looks like, and it renders as nothing at all.
n=$(python3 -c "
import io,sys
s=io.open('$main',encoding='utf-8').read()
print(sum(1 for c in s if 0xE000<=ord(c)<=0xF8FF))")
[ "$n" -eq 5 ] && say ok "five glyphs survive" || { say FAIL "expected 5 PUA glyphs, found $n"; fail=1; }

python3 -c "
import io,sys,re
s=io.open('$main',encoding='utf-8').read()
sys.exit(0 if not re.search(r'text: \"\"\s*(//|\$)', s) else 1)" \
  && say ok "no empty glyph strings" || { say FAIL "an empty text: \"\" -- a glyph was eaten"; fail=1; }

# textConstants is NOT injected by sddm-greeter-qt6 0.21: reading it throws and
# the binding silently leaves the text empty. Found on the real greeter, after
# the offscreen harness had happily supplied one.
python3 -c "
import io,sys,re
s=io.open('$main',encoding='utf-8').read()
code=[l for l in s.split('\n') if not l.strip().startswith('//')]
sys.exit(1 if any('textConstants' in l for l in code) else 0)" \
  && say ok "no textConstants" \
  || { say FAIL "uses textConstants -- the greeter does not inject it"; fail=1; }

# The mark is the same artifact fastfetch prints, at the size that still reads.
python3 - <<'PY'
import io, sys
art = io.open('fastfetch/.config/fastfetch/ashen.txt', encoding='utf-8').read()
rows = [l[2:] for l in art.split('\n') if l.startswith('$1')]
rows = [r[3:] for r in rows if r.strip()][:6]
qml = io.open('sddm/ashen/Main.qml', encoding='utf-8').read()
want = '\\n'.join(rows)
sys.exit(0 if want in qml else 1)
PY
[ $? -eq 0 ] && say ok "mark matches fastfetch's rows" \
  || { say FAIL "the mark drifted from fastfetch/ashen.txt"; fail=1; }

grep -q 'font.pixelSize: 12' "$main" && say ok "mark at 12px" \
  || { say FAIL "mark size changed -- past ~14px the ramp reads as dots"; fail=1; }

# The pickers draw their own popup. A ComboBox popup is NOT covered by the
# control's opacity -- it is its own item, so without this it arrives in Qt's
# default style, white and square, on top of Ashen.
grep -q 'component Picker: ComboBox' "$main" && say ok "styled picker" \
  || { say FAIL "no Picker component -- the popups fall back to Qt's default"; fail=1; }
grep -q 'popup: Popup' "$main" && say ok "popup is drawn here" \
  || { say FAIL "the popup is not styled"; fail=1; }

# Every dot the same size: one wider than the rest reads as a mistake.
grep -q 'width: last ? 20' "$main" \
  && { say FAIL "a dot is wider than the others"; fail=1; } \
  || say ok "dots are uniform"

# sddm.conf(5) loads the .conf.d directories FIRST and /etc/sddm.conf LAST,
# "with the latter having highest precedence" -- the opposite of systemd. A
# theme installed only through the drop-in never appears if that file names
# another one, which is exactly what this machine had.
lib=install/lib/sddm.sh
grep -q '/etc/sddm.conf.d/10-ashen.conf' "$lib" && say ok "writes the drop-in" \
  || { say FAIL "no drop-in"; fail=1; }
grep -q 'sddm.conf.ashen-bak' "$lib" && say ok "backs up sddm.conf before repointing" \
  || { say FAIL "repoints sddm.conf without a backup"; fail=1; }
grep -qE "sed -i.*Current.*ashen" "$lib" && say ok "repoints /etc/sddm.conf" \
  || { say FAIL "leaves /etc/sddm.conf, which outranks the drop-in"; fail=1; }

# The gate for "only one user" must sit on the control, not on a MouseArea
# under it: the ComboBox is on top and takes the press itself, so a gate
# underneath never runs and the one-row popup opens anyway.
python3 -c "
import io,sys
s=io.open('$main',encoding='utf-8').read()
i=s.find('objectName: \"userPicker\"')
sys.exit(0 if i!=-1 and 'enabled: userModel.count > 1' in s[i:i+800] else 1)" \
  && say ok "user picker gated on the control" \
  || { say FAIL "the one-user gate is not on the picker"; fail=1; }

# The one that took the login screen away: SDDM picks the GREETER BINARY from
# the theme's metadata. No QtVersion=6 and it starts /usr/bin/sddm-greeter,
# which is Qt5; a Qt6-only machine has none of those libraries, so it exits 127
# ("Auth: sddm-helper exited with 127") and the machine sits at the boot
# console with no login screen at all.
meta=sddm/ashen/metadata.desktop
grep -q '^QtVersion=6' "$meta" && say ok "declares QtVersion=6" \
  || { say FAIL "no QtVersion=6 -- sddm will start the Qt5 greeter and die"; fail=1; }
grep -q '^MainScript=Main.qml' "$meta" && say ok "names its main script" \
  || { say FAIL "no MainScript"; fail=1; }
grep -q '^ConfigFile=theme.conf' "$meta" && say ok "names its config file" \
  || { say FAIL "no ConfigFile -- the palette never loads"; fail=1; }
# And the installer refuses to point sddm at a theme that would not come up.
grep -q 'QtVersion=6' install/lib/sddm.sh && say ok "the installer checks it too" \
  || { say FAIL "the installer would happily install a theme that cannot start"; fail=1; }

# Present is not runnable: /usr/bin/sddm-greeter EXISTS here and still dies
# with 127 for want of Qt5 libraries. The installer checks the libraries too.
grep -q "ldd /usr/bin/sddm-greeter-qt6" install/lib/sddm.sh \
  && say ok "the installer checks the greeter's libraries" \
  || { say FAIL "the installer trusts a binary it never tried to resolve"; fail=1; }
grep -q 'to undo:' install/lib/sddm.sh \
  && say ok "it prints the way back" \
  || { say FAIL "it changes the login screen without saying how to undo it"; fail=1; }

# The palette is the shell's, not an invented one.
for k in surface snow mist ash ghost accentText error background radius; do
    grep -q "^$k=" "$conf" && say ok "theme.conf has $k" \
      || { say FAIL "theme.conf missing $k"; fail=1; }
done
grep -q '^surface=#1c1c21' "$conf" && say ok "surface is Colors.surface" \
  || { say FAIL "surface is not the shell's #1c1c21"; fail=1; }

# The bar's numbers come from services/Sizes.qml and must not drift.
grep -q 'readonly property int barH: 56'  "$main" && say ok "barH 56"  || { say FAIL "barH drifted"; fail=1; }
grep -q 'readonly property int pillH: 44' "$main" && say ok "pillH 44" || { say FAIL "pillH drifted"; fail=1; }
grep -q 'readonly property int pillR: 10' "$main" && say ok "pillR 10" || { say FAIL "pillR drifted"; fail=1; }

# And it loads: the harness reports through its exit code, since qml6 prints
# nothing from console.log and a broken theme is otherwise silent.
if command -v qml6 >/dev/null 2>&1; then
    ( cd docs/probes/sddm && timeout 60 env QT_QPA_PLATFORM=offscreen qml6 harness.qml >/dev/null 2>&1 )
    [ $? -eq 0 ] && say ok "theme loads and renders" \
      || { say FAIL "the theme did not build a scene"; fail=1; }
else
    say ok "qml6 absent -- render skipped"
fi

exit $fail

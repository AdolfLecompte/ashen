#!/usr/bin/env bash
# Text is text.
#
# A QML Text left to its default, AutoText, decides for itself whether what it
# holds is HTML. Much of what the shell shows comes from outside -- the
# clipboard, notifications, track titles, network names -- and on 2026-09-13 a
# clipboard entry holding an <img> tag was parsed as rich text and Qt 6.11.2
# crashed inside QQuickTextPrivate::updateLayout, taking the bar with it.
#
# So every Text says what it is. Plain unless it declares otherwise; the release
# notes are the one rich-text surface, and they escape what they are given.
set -uo pipefail
cd "$(dirname "$0")/../.."
fail=0
say() { printf '%-4s %s\n' "$1" "$2"; }

root=quickshell/.config/quickshell/ashen

missing=$(python3 - "$root" <<'PY'
import re, glob, sys
root = sys.argv[1]
opener = re.compile(r"^\s*(?:[\w.]+\s*:\s*)?(?:component\s+\w+\s*:\s*)?Text\s*\{")
out = []
for f in sorted(glob.glob(root + "/modules/**/*.qml", recursive=True) + [root + "/shell.qml"]):
    L = open(f, encoding="utf-8").read().split("\n")
    for i, l in enumerate(L):
        if not opener.match(l):
            continue
        depth = 0; body = []
        for j in range(i, len(L)):
            body.append(L[j]); depth += L[j].count("{") - L[j].count("}")
            if depth == 0: break
        if "textFormat" not in "\n".join(body):
            out.append("%s:%d" % (f[len(root) + 1:], i + 1))
print("\n".join(out))
PY
)
if [ -z "$missing" ]; then
    say ok "every Text declares its textFormat"
else
    say FAIL "Text left to AutoText (would parse outside content as HTML):"
    printf '%s\n' "$missing" | sed 's/^/       /'
    fail=1
fi

# Rich text only where it is meant, and fed escaped.
rich=$(grep -rln 'Text\.StyledText\|Text\.RichText' "$root/modules" | sed "s|$root/||")
if [ "$rich" = "modules/intro/IntroPanel.qml" ]; then
    say ok "the release notes are the only rich text"
else
    say FAIL "rich text outside the release notes: $rich"; fail=1
fi
if grep -q 'replace(/</g, "&lt;")' "$root/services/Release.qml"; then
    say ok "release notes escape angle brackets before markdown"
else
    say FAIL "Release.rich() no longer escapes its input"; fail=1
fi

# What an app sends in a notification is stripped of markup on the way in.
if grep -q 'summary: root.plain(' "$root/services/Notifications.qml" \
   && grep -q 'body: root.plain(' "$root/services/Notifications.qml"; then
    say ok "notification summary and body are taken in as plain text"
else
    say FAIL "notification text reaches the views unstripped"; fail=1
fi

exit $fail

#!/usr/bin/env bash
# Version comparison, one case per run. The QML answers with its exit code and
# nothing else -- see the note in version-probe.qml.
set -uo pipefail
cd "$(dirname "$0")"
fail=0
check() {   # a  b  expected(1|0)  why
    if QT_QPA_PLATFORM=offscreen qml6 version-probe.qml -- "$1" "$2" "$3" >/dev/null 2>&1; then
        printf 'ok   newer(%-8s %-8s) = %s   %s\n' "$1" "$2" "$3" "$4"
    else
        printf 'FAIL newer(%-8s %-8s) should be %s   %s\n' "$1" "$2" "$3" "$4"; fail=1
    fi
}

check 2.2.0  2.1.0  1 "a later release"
check 2.1.0  2.2.0  0 "an older one"
check 2.1.0  2.1.0  0 "the same one"
check 2.10.0 2.9.0  1 "THE case a string comparison gets wrong"
check 2.9.0  2.10.0 0 "…and its mirror"
check v2.2.0 2.1.0  1 "the tag carries a v, the CHANGELOG heading does not"
check v2.1.0 2.1.0  0 "same version, one of them tagged"
check 2.2    2.2.0  0 "shorter is not smaller by accident"
check 2.2.1  2.2    1 "…but a third part still counts"
check 2.4.0  v2.3.0 1 "a checkout ahead of the newest tag is not an error"

exit $fail

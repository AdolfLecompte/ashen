#!/usr/bin/env bash
# While arranging, the bare-widget layer must be gone: left mapped with an
# empty mask it sits above the main layer and eats every drag. Needs the shell
# running with at least one plate-less widget; otherwise it says so and passes.
set -uo pipefail
layers() { hyprctl layers 2>/dev/null | grep -c 'ashen:bare'; }
qs -c ashen ipc call widgets list >/dev/null 2>&1 || { echo "skip shell not running"; exit 0; }
[ "$(layers)" -gt 0 ] || { echo "skip no plate-less widget on this desktop"; exit 0; }
fail=0
qs -c ashen ipc call widgets edit >/dev/null 2>&1; sleep 1.5
[ "$(layers)" -eq 0 ] && echo "ok   bare layer unmapped while arranging" || { echo "FAIL bare layer still mapped while arranging"; fail=1; }
qs -c ashen ipc call widgets edit >/dev/null 2>&1; sleep 1.5
[ "$(layers)" -gt 0 ] && echo "ok   bare layer back at rest" || { echo "FAIL bare layer did not come back"; fail=1; }
exit $fail

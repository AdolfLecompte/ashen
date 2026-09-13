#!/usr/bin/env bash
# Every probe, in order. The one thing to run before touching the installer.
cd "$(dirname "$0")"
fail=0; total=0
for p in logo tui pkgs zsh dots run boot sddm keys coords text; do
    out=$("./$p-probe.sh" 2>&1); rc=$?
    n=$(printf '%s' "$out" | grep -c '^ok')
    total=$((total + n))
    if [ $rc -eq 0 ]; then printf '  \033[32mok\033[0m   %-6s %2d asserts\n' "$p" "$n"
    else printf '  \033[31mFAIL\033[0m %-6s\n' "$p"; printf '%s\n' "$out" | grep '^FAIL' | sed 's/^/         /'; fail=1; fi
done
printf '\n  %d asserts\n' "$total"

# Deliberately NOT in the loop: it needs a docker daemon, the network and a
# couple of minutes, and a suite you stop running because it is slow protects
# nothing. It is the one that catches what only breaks on somebody else's Arch.
if docker info >/dev/null 2>&1; then
    printf '  %s\n' "container-probe.sh is available (docker is up) — run it before a release"
else
    printf '  %s\n' "container-probe.sh needs a docker daemon; skipped"
fi
exit $fail

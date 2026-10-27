#!/usr/bin/env bash
# `ashen rollback` goes back to where the last update started, keeps local
# edits, and refuses when they collide. Runs on a throwaway clone and HOME.
set -uo pipefail
cd "$(dirname "$0")/../.."
fail=0
say() { printf '%-4s %s\n' "$1" "$2"; }

T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir -p "$T/home/.cache" "$T/bin"
# The shell is never touched: everything rollback restarts is a stub.
for b in pkill setsid hyprctl qs pgrep; do
    printf '#!/bin/sh\n[ "$(basename "$0")" = pgrep ] && exit 1\nexit 0\n' > "$T/bin/$b"
    chmod +x "$T/bin/$b"
done
git clone -q . "$T/repo" 2>/dev/null || { say FAIL "clone"; exit 1; }
R="$T/repo"
run() { HOME="$T/home" ASHEN_DIR="$R" PATH="$T/bin:$PATH" bash scripts/ashen rollback >/dev/null 2>&1; }

run && say FAIL "rolled back with no update recorded" || say ok "nothing to roll back says so"

prev=$(git -C "$R" rev-parse HEAD~1); echo "$prev" > "$T/home/.cache/ashen-before-update"
# A tracked file the rollback does not touch, so the local edit cannot collide.
keep=$(comm -23 <(git -C "$R" ls-files | sort) <(git -C "$R" diff --name-only HEAD~1 HEAD | sort) | grep -m1 -E '^(LICENSE|docs/DESIGN.md)$' || git -C "$R" ls-files | head -1)
echo "local edit" >> "$R/$keep"
run && [ "$(git -C "$R" rev-parse HEAD)" = "$prev" ] && say ok "goes back to the recorded commit" \
    || { say FAIL "did not go back"; fail=1; }
tail -1 "$R/$keep" | grep -q "local edit" && say ok "local edits survive" \
    || { say FAIL "local edit lost"; fail=1; }

git -C "$R" reset -q --hard 'HEAD@{1}'
git -C "$R" rev-parse HEAD~1 > "$T/home/.cache/ashen-before-update"
f=$(git -C "$R" diff --name-only HEAD~1 HEAD | head -1); echo x >> "$R/$f"
head=$(git -C "$R" rev-parse HEAD)
run && say FAIL "overwrote a colliding local edit" \
    || { [ "$(git -C "$R" rev-parse HEAD)" = "$head" ] && say ok "refuses when local edits collide" \
         || { say FAIL "moved despite the collision"; fail=1; }; }

exit $fail

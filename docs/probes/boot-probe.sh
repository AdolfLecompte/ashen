#!/usr/bin/env bash
# boot.sh is the only thing that travels over curl. It must be small, and it
# must choose the directory itself.
set -uo pipefail
cd "$(dirname "$0")/../.."
fail=0
say() { printf '%-4s %s\n' "$1" "$2"; }

bash -n install/boot.sh 2>/dev/null && say ok "syntax" || { say FAIL "syntax"; exit 1; }

# Small enough to read before piping it to a shell. Anyone who runs a curl|bash
# should be able to; a 300-line bootstrap is not auditable at a glance.
n=$(grep -vcE '^\s*(#|$)' install/boot.sh)
[ "$n" -le 60 ] && say ok "$n lines of code, auditable" \
                || { say FAIL "$n lines: too big for a curl|bash"; fail=1; }

# THE fault it closes: the installer picks the directory, lower case, so a clone
# named Ashen can no longer disagree with the $HOME/ashen paths in the lua and
# in Paths.qml.
grep -q 'ASHEN_DIR="\$HOME/ashen"' install/boot.sh && say ok "clones to ~/ashen, lower case" \
                                                   || { say FAIL "directory not pinned"; fail=1; }
grep -q '/Ashen' install/boot.sh && { say FAIL "names an upper-case Ashen"; fail=1; } \
                                 || say ok "no upper-case path"

# It refuses politely on a system it cannot serve.
grep -q 'command -v pacman' install/boot.sh && say ok "checks for Arch" \
                                             || { say FAIL "no Arch check"; fail=1; }
# Running it again updates rather than failing on an existing clone.
grep -q 'git -C .* pull' install/boot.sh && say ok "an existing clone is updated" \
                                          || { say FAIL "second run would fail"; fail=1; }
# And it hands over rather than duplicating run.sh.
grep -q 'install/run.sh' install/boot.sh && say ok "hands over to run.sh" \
                                          || { say FAIL "does not call run.sh"; fail=1; }

# ── It actually works, in a throwaway HOME ────────────────────────────────
# Cloned from a stand-in repo, not from this checkout: `git clone` only carries
# what is COMMITTED, and install/ is not yet. Testing against this working tree
# would be testing the commit state, not boot.sh.
T=$(mktemp -d); S=$(mktemp -d); trap 'rm -rf "$T" "$S"' EXIT
mkdir -p "$S/install"
cat > "$S/install/run.sh" <<'STUB'
#!/usr/bin/env bash
echo "would install  (stand-in run.sh reached, args: $*)"
STUB
git -C "$S" init -q 2>/dev/null
git -C "$S" add -A 2>/dev/null
git -C "$S" -c user.email=p@p -c user.name=p commit -qm stub 2>/dev/null

out=$(HOME="$T" ASHEN_SOURCE="$S" bash install/boot.sh --dry-run 2>&1)
rc=$?
[ "$rc" -eq 0 ] && say ok "dry run exits 0" || { say FAIL "exited $rc: $out"; fail=1; }
[ -d "$T/ashen" ] && say ok "clone landed at ~/ashen" || { say FAIL "no ~/ashen"; fail=1; }
[ -d "$T/Ashen" ] && { say FAIL "created ~/Ashen"; fail=1; } || say ok "no ~/Ashen"
printf '%s' "$out" | grep -q 'would install' && say ok "run.sh took over" \
                                             || { say FAIL "run.sh never ran"; fail=1; }
# Second run: updates, does not fall over.
out2=$(HOME="$T" ASHEN_SOURCE="$S" bash install/boot.sh --dry-run 2>&1)
[ $? -eq 0 ] && say ok "second run survives an existing clone" \
             || { say FAIL "second run failed: $out2"; fail=1; }

# A directory that is not a checkout is refused, not clobbered.
V=$(mktemp -d); mkdir -p "$V/ashen"; echo mine > "$V/ashen/keepme"
err=$(HOME="$V" ASHEN_SOURCE="$S" bash install/boot.sh --dry-run 2>&1)
[ -f "$V/ashen/keepme" ] && say ok "an existing ~/ashen is never clobbered" \
                         || { say FAIL "DESTROYED an existing ~/ashen"; fail=1; }
printf '%s' "$err" | grep -q 'not a git checkout' && say ok "and it says why" \
                                                  || { say FAIL "refused silently"; fail=1; }
rm -rf "$V"

# The README documents the line people will paste.
grep -q 'install/boot.sh' README.md && say ok "README carries the curl line" \
                                     || { say FAIL "README not updated"; fail=1; }
exit $fail

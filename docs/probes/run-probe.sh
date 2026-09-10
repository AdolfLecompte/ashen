#!/usr/bin/env bash
# run.sh must say everything and, in a dry run, touch nothing.
set -uo pipefail
cd "$(dirname "$0")/../.."
fail=0
say() { printf '%-4s %s\n' "$1" "$2"; }

bash -n install/run.sh 2>/dev/null && say ok "syntax" || { say FAIL "syntax"; exit 1; }

# A failing package must never end the run: set -e would do exactly that.
grep -qE '^\s*set -e\b' install/run.sh && { say FAIL "set -e would abort the run"; fail=1; } \
                                       || say ok "no set -e"
# The terminal is given back on every path.
grep -q '_tui_open' install/run.sh && say ok "opens the tui" || { say FAIL "no _tui_open"; fail=1; }
# Root is asked for once, not per package.
[ "$(grep -c 'sudo -v' install/run.sh)" -ge 1 ] && say ok "sudo asked once" \
                                                || { say FAIL "no sudo -v"; fail=1; }

T=$(mktemp -d); trap 'rm -rf "$T"' EXIT

before=$(pacman -Qq 2>/dev/null | md5sum)
out=$(HOME="$T" bash install/run.sh --dry-run 2>&1)
rc=$?
after=$(pacman -Qq 2>/dev/null | md5sum)

[ "$rc" -eq 0 ] && say ok "dry run exits 0" || { say FAIL "dry run exited $rc"; fail=1; }
[ "$before" = "$after" ] && say ok "dry run installed nothing" \
                         || { say FAIL "DRY RUN TOUCHED THE SYSTEM"; fail=1; }
[ -z "$(ls -A "$T" 2>/dev/null)" ] && say ok "dry run wrote no dotfiles" \
                                  || { say FAIL "dry run wrote into HOME"; fail=1; }

# It names every stage, or a silent step is a step nobody can debug.
for want in "would install  hyprland" "would install  ttf-jetbrains-mono-nerd" \
            "would install  zsh-theme-powerlevel10k" "would enable   NetworkManager" \
            "would place    hypr" "video group"; do
    printf '%s' "$out" | grep -q "$want" && say ok "names: $want" \
                                         || { say FAIL "missing from output: $want"; fail=1; }
done
# The rehearsal is READABLE: a per-file dump is 200 lines nobody reads.
lines=$(printf '%s' "$out" | wc -l)
[ "$lines" -le 120 ] && say ok "rehearsal is $lines lines, readable" \
                     || { say FAIL "rehearsal is $lines lines: too long to read"; fail=1; }
printf '%s' "$out" | grep -q 'would place    quickshell' && say ok "dotfiles counted per package" \
                                                         || { say FAIL "dotfiles not summarised"; fail=1; }
# No step is silent: a step that prints nothing cannot be debugged.
printf '%s' "$out" | grep -qE 'video group' && \
  printf '%s' "$out" | grep -qE '(already in the video group|would add)' \
  && say ok "the video step says something" \
  || { say FAIL "video step is silent"; fail=1; }

# The mark is drawn -- at the TOP now, where it stays on screen for the whole
# install rather than arriving after it.
printf '%s' "$out" | grep -q '██║  ██║███████║' && say ok "draws the mark" \
                                                || { say FAIL "no mark"; fail=1; }
# It used to end on "enjoy". It ends on REBOOT now, and that is the assert that
# matters: this install changed the login screen, three services and a group, so
# a logout would show a machine that looks half-installed.
printf '%s' "$out" | grep -qi 'reboot' && say ok "asks for a reboot" \
  || { say FAIL "the ending does not ask for a reboot"; fail=1; }
# And the mark is drawn once, not twice.
n=$(printf '%s' "$out" | grep -c '██║  ██║')
[ "$n" -eq 1 ] && say ok "the mark is drawn once" \
  || { say FAIL "the mark is drawn $n times"; fail=1; }

# ── The fault this project exists to fix, end to end ───────────────────────
# A package that cannot exist is injected, and the run must carry on past it and
# report it with a retry line.
cp install/lib/pkgs.sh "$T/pkgs.bak"
sed -i 's/^    hyprland kitty/    ashen-no-such-package hyprland kitty/' install/lib/pkgs.sh
out2=$(HOME="$T" bash install/run.sh --dry-run 2>&1)
cp "$T/pkgs.bak" install/lib/pkgs.sh
printf '%s' "$out2" | grep -q "would install  ttf-jetbrains-mono-nerd" \
  && say ok "packages after a bad target still run" \
  || { say FAIL "a bad target stopped the run"; fail=1; }

exit $fail

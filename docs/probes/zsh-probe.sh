#!/usr/bin/env bash
# The shipped zsh must stand up on plain Arch, not only on CachyOS.
set -uo pipefail
cd "$(dirname "$0")/../.."
fail=0
say() { printf '%-4s %s\n' "$1" "$2"; }
files="zsh/.zshrc zsh/.config/zsh/.zshrc"

for f in $files; do [ -f "$f" ] || { say FAIL "$f missing"; exit 1; }; done

# Oh My Zsh is gone, and with it the four git clones the installer had to make.
grep -qE 'oh-my-zsh|ZSH_THEME' $files && { say FAIL "still on oh-my-zsh"; fail=1; } \
                                      || say ok "no oh-my-zsh"
# The prompt is loaded by US, from the distro package. Without this line a plain
# Arch machine gets no p10k at all: today it works only because CachyOS's own
# zsh config sources the theme (cachyos-config.zsh:88).
grep -q 'zsh-theme-powerlevel10k/powerlevel10k.zsh-theme' $files \
  && say ok "sources the p10k package" || { say FAIL "no p10k source: bare prompt on plain Arch"; fail=1; }
# ...and not twice, where CachyOS already did it.
grep -q '$+functions\[p10k\]' $files \
  && say ok "guarded against double load" || { say FAIL "unguarded p10k source"; fail=1; }
# The config ships at the path p10k configure writes AND cachyos looks in.
[ -f zsh/.p10k.zsh ] && say ok "p10k ships to ~/.p10k.zsh" || { say FAIL "no zsh/.p10k.zsh"; fail=1; }
[ -f zsh/.config/zsh/.p10k.zsh ] && { say FAIL "old p10k path still present"; fail=1; } \
                                 || say ok "old p10k path gone"
# The plugins come from the packages, not from a cloned custom dir.
grep -q '/usr/share/zsh/plugins/zsh-autosuggestions' $files \
  && say ok "autosuggestions from the package" || { say FAIL "autosuggestions not sourced"; fail=1; }
grep -q '/usr/share/zsh/plugins/zsh-syntax-highlighting' $files \
  && say ok "syntax highlighting from the package" || { say FAIL "highlighting not sourced"; fail=1; }
# The tools the aliases reach for.
grep -q "alias ls='eza" $files && say ok "eza alias" || { say FAIL "eza alias missing"; fail=1; }
grep -q "alias cat='bat" $files && say ok "bat alias" || { say FAIL "bat alias missing"; fail=1; }
grep -q 'zoxide init zsh' $files && say ok "zoxide" || { say FAIL "zoxide missing"; fail=1; }
grep -q 'fzf' $files && say ok "fzf" || { say FAIL "fzf missing"; fail=1; }
# The CachyOS block survives, guarded, with its orphan-scan trick.
grep -q 'cachyos-zsh-config' $files && say ok "cachyos block kept" \
                                    || { say FAIL "cachyos block lost"; fail=1; }
grep -q 'Qtdq' $files && say ok "the 450ms orphan-scan trick kept" \
                      || { say FAIL "orphan-scan trick lost"; fail=1; }
# Nothing personal to this machine travels.
for bad in flutter dotnet GOPATH '\.claude' zsh_history_codium 'unsetopt CORRECT'; do
    grep -q "$bad" $files && { say FAIL "$bad must not ship"; fail=1; } \
                          || say ok "$bad absent"
done
# The fastfetch header still comes back with `clear` and on a new terminal.
grep -q 'fastfetch.sh' $files && say ok "fastfetch hook kept" \
                              || { say FAIL "fastfetch hook lost"; fail=1; }
# Syntax.
for f in $files; do
    zsh -n "$f" 2>/dev/null && say ok "syntax $f" || { say FAIL "syntax $f"; fail=1; }
done
exit $fail

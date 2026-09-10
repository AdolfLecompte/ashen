# ══════════════════════════════════════════
#   Ashen — Zsh Config
# ══════════════════════════════════════════

# CachyOS ships its own zsh config, and its `cleanup` alias interpolates
# `pacman -Qtdq` AT SOURCE TIME -- a full orphan scan (~450ms) on every single
# shell, just to build a string. Shadow that one query while the file is read,
# then define cleanup as a function, which is what it should have been.
if [ -r /usr/share/cachyos-zsh-config/cachyos-config.zsh ]; then
    pacman() { [[ "$1" == "-Qtdq" ]] && return 0; command pacman "$@"; }
    source /usr/share/cachyos-zsh-config/cachyos-config.zsh
    unfunction pacman
    unalias cleanup 2>/dev/null
    cleanup() { sudo pacman -Rsn $(pacman -Qtdq); }
fi

# The prompt comes from the distro package, not from a cloned theme dir. The
# block above already sourced it on CachyOS, so this is a no-op there -- and it
# is the WHOLE prompt on plain Arch, where nothing else would have loaded it.
#
# Checked for on disk, not just for being loaded: powerlevel10k lives in the AUR,
# the installer skips the AUR list on a machine with no helper AND SAYS SO, and
# an unguarded source then printed "no such file or directory" on every single
# shell that opened afterwards. Missing the prompt is a choice that machine made;
# an error on every prompt is not.
[[ -r /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme ]] \
    && (( ! $+functions[p10k] )) \
    && source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme

# ── Completions ───────────────────────────────────────────
# fpath FIRST: compinit reads it as it runs, so a directory added on the line
# after is a directory it never saw -- everything in site-functions was going
# uncompleted. -i rather than the bare call: on a fresh machine a group-writable
# completion directory makes compinit print a wall of text and then BLOCK on a
# [y/n], below the instant prompt, which is the one place p10k says a question
# must never be. Insecure directories are skipped instead of asked about.
fpath=(/usr/share/zsh/site-functions $fpath)
autoload -Uz compinit && compinit -i

# ── Plugins ───────────────────────────────────────────────
# Straight from the packages. Oh My Zsh was carrying these through a custom dir
# that the installer had to clone; the repos ship them.
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#585b70"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
bindkey '^ ' autosuggest-accept

source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ── FZF ───────────────────────────────────────────────────
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh
export FZF_DEFAULT_OPTS="
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
  --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
  --height=40% --border=rounded --layout=reverse"
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'

# ── Zoxide ────────────────────────────────────────────────
eval "$(zoxide init zsh --cmd cd)"

# ── Aliases ───────────────────────────────────────────────
alias ls='eza --icons --group-directories-first'
alias ll='eza -lah --icons --group-directories-first --git'
alias lt='eza --tree --icons --level=2'
alias cat='bat --style=plain'
alias grep='grep --color=auto'
alias hyprconf='cd ~/.config/hypr'
alias ashen='cd ~/ashen'
alias gs='git status'
alias ga='git add .'
alias gc='git commit -m'
alias gp='git push'

# ── History ───────────────────────────────────────────────
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

export PATH="$HOME/.local/bin:$PATH"

# Working from a checkout instead of the package: the helper scripts
# (ashen-widgets, ashen-wallpaper…) live in the repo and nowhere else, and the
# package installs them to /usr/bin. Harmless when there is no checkout.
[[ -d "$HOME/ashen/scripts" ]] && export PATH="$HOME/ashen/scripts:$PATH"

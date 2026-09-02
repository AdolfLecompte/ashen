# ══════════════════════════════════════════
#   Ashen — Zsh Config
# ══════════════════════════════════════════

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

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

# Plugins
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    z
)

source $ZSH/oh-my-zsh.sh

# Aliases
alias ls='ls --color=auto'
alias ll='ls -lah --color=auto'
alias la='ls -A --color=auto'
alias grep='grep --color=auto'
alias hyprconf='cd ~/.config/hypr'
alias ashen='cd ~/ashen'
alias gs='git status'
alias ga='git add .'
alias gc='git commit -m'
alias gp='git push'

# Powerlevel10k
[[ -f ~/.config/zsh/.p10k.zsh ]] && source ~/.config/zsh/.p10k.zsh
export PATH="$HOME/.local/bin:$PATH"

# Working from a checkout instead of the package: the helper scripts
# (ashen-widgets, ashen-wallpaper…) live in the repo and nowhere else, and the
# package installs them to /usr/bin. Harmless when there is no checkout.
[[ -d "$HOME/ashen/scripts" ]] && export PATH="$HOME/ashen/scripts:$PATH"


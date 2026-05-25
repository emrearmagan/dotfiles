source ~/.env

#Only run in interative shells
[[ ! -t 1 ]] && return

source ~/.config/alias/.alias
source ~/.config/alias/.custom
source ~/.config/alias/.macos
source ~/.config/alias/.fzf
source ~/.config/alias/.functions

# use vim motions
set -o vi
export EDITOR=nvim
export VISUAL=nvim
# Pretty-print man pages with bat; col strips raw backspace formatting (^H).
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# ----------------------
# Export
# ----------------------
export PATH=/opt/homebrew/bin:$PATH
export PATH="/opt/homebrew/opt/openssh/bin:$PATH"
export PATH="/opt/homebrew/opt/postgresql@18/bin:$PATH"
export PATH="$HOME/.config/scripts:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
export GOBIN="$HOME/go/bin"
export PATH="$GOBIN:$PATH"

export LUA_PATH="lua/?.lua;lua/?/init.lua;;" # i dont know why but i need this for 'busted' to work

# zsh-autosuggestions, zsh-vi-mode, syntax highlighting, and fzf-tab
fpath+=("$(brew --prefix)/share/zsh-completions")
autoload -Uz compinit
_zcompdump_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
[[ -d $_zcompdump_dir ]] || mkdir -p $_zcompdump_dir
compinit -d "$_zcompdump_dir/zcompdump"

source $(brew --prefix)/share/fzf-tab/fzf-tab.zsh
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $(brew --prefix)/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh

source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
source /opt/homebrew/opt/fzf/shell/completion.zsh
eval $(thefuck --alias)
if [[ -z "${__STARSHIP_INIT_DONE:-}" ]]; then
  eval "$(starship init zsh)"
  __STARSHIP_INIT_DONE=1
fi
eval "$(zoxide init zsh)"

# ----------------------
# Configuration
# ----------------------
# fzf-tab defaults
zstyle ':completion:*' menu no
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':fzf-tab:*' fzf-flags --height=30% --layout=reverse --style=minimal --preview-window=right
zstyle ':fzf-tab:*' fzf-bindings 'tab:accept'
zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':fzf-tab:complete:*' fzf-preview 'if [[ -d $realpath ]]; then eza -1 --icons --color=always --group-directories-first -- $realpath; else bat --style=numbers --color=always --line-range=:200 -- $realpath; fi'

setopt appendhistory        # Enable history appending instead of overwriting the history file
setopt sharehistory       # Share command history across multiple terminal sessions
setopt hist_ignore_space    # Ignore commands that start with a space in history
setopt hist_ignore_all_dups # Ignore duplicate commands in history
setopt hist_save_no_dups    # Save only unique commands in history
setopt hist_ignore_dups     # Ignore duplicates in history when searching
setopt hist_find_no_dups    # Prevent finding duplicate commands in history search

# -------------------------------------------------------
# Catppuccin Mocha — minimal LS_COLORS
# -------------------------------------------------------
export LS_COLORS="\
di=94:\        # directories: blue
ex=92:\        # executables: green
fi=97:\        # regular files: soft white
"
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

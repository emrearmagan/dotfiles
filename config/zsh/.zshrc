source ~/.env
source ~/.config/alias/.alias
source ~/.config/alias/.custom
source ~/.config/alias/.macos
source ~/.config/alias/.functions


# use vim motions
set -o vi

# ----------------------
# Export
# ----------------------
#Prompt
export PS1='%F{117}%n: %F{110}%~%f %# '
export GOPATH=$HOME/development/go
export GOPATH=$HOME/.go

export PATH=/opt/homebrew/bin:$PATH
export PATH="/opt/homebrew/opt/openssh/bin:$PATH"
export PATH="/opt/homebrew/opt/postgresql@18/bin:$PATH"

# zsh-autosuggestions and highlighting
fpath+=("$(brew --prefix)/share/zsh-completions")
# INFO: really like the completion but get messy with autosuggestions. For example cd 'suggestion' when pressing tab auto complete takes in and it looks like:
# cd <auto-completed>'suggestion' - please FIX
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $(brew --prefix)/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh

source <(fzf --zsh)
eval $(thefuck --alias)
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"

# ----------------------
# Configuration
# ----------------------

setopt appendhistory        # Enable history appending instead of overwriting the history file
# setopt sharehistory       # Share command history across multiple terminal sessions
setopt hist_ignore_space    # Ignore commands that start with a space in history
setopt hist_ignore_all_dups # Ignore duplicate commands in history
setopt hist_save_no_dups    # Save only unique commands in history
setopt hist_ignore_dups     # Ignore duplicates in history when searching
setopt hist_find_no_dups    # Prevent finding duplicate commands in history search

# ----------------------
# Completion Styling
# ----------------------
# Configure case-insensitive completion matching
# This allows tab-completion to match case-insensitively
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

zstyle ':autocomplete:*' inline no
zstyle ':autocomplete:*' list-lines 5
zstyle ':autocomplete:menu:*' select yes
zstyle ':autocomplete:list-choices:*' color cyan

# -------------------------------------------------------
# Catppuccin Mocha — minimal LS_COLORS
# -------------------------------------------------------
export LS_COLORS="\
di=94:\        # directories: blue
ex=92:\        # executables: green
fi=97:\        # regular files: soft white
"
bindkey              '^I'         menu-complete
bindkey "$terminfo[kcbt]" reverse-menu-complete
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Initialize zsh completion system
# no need to call compinit anymore as it's called by zsh-autocomplete. When deleting zsh-completions, remember to add this back.
# autoload -Uz compinit && compinit

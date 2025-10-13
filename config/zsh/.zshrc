source ~/.env
source ~/.alias/.alias
source ~/.alias/.custom
source ~/.alias/.macos
source ~/.alias/.functions


# ----------------------
# Export
# ----------------------
#Prompt
export PS1='%F{green}%n: (%~)%f '

# Go
export GOPATH=$HOME/development/go
export GOPATH=$HOME/.go

#Brew
export PATH=/opt/homebrew/bin:$PATH

# zsh-autosuggestions and highlighting
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source <(fzf --zsh)
eval "$(starship init zsh)"

# ----------------------
# Configuration
# ----------------------

# use vim motions
set -o vi

# Enable history appending instead of overwriting the history file
setopt appendhistory
# Share command history across multiple terminal sessions
# setopt sharehistory
# Ignore commands that start with a space in history
setopt hist_ignore_space
# Ignore duplicate commands in history
setopt hist_ignore_all_dups
# Save only unique commands in history
setopt hist_save_no_dups
# Ignore duplicates in history when searching
setopt hist_ignore_dups
# Prevent finding duplicate commands in history search
setopt hist_find_no_dups

# ----------------------
# Completion Styling
# ----------------------
# Configure case-insensitive completion matching
# This allows tab-completion to match case-insensitively
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

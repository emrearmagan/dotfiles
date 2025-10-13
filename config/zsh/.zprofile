eval "$(/opt/homebrew/bin/brew shellenv)"
eval "$(starship init zsh)"

# This is suppose to configure fzf to always use rg. But not sure how to verify..
export FZF_DEFAULT_COMMAND='rg --files --hidden --glob "!.git/*"'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS='
  --layout=reverse
  --height=100%
  --border=rounded
  --style=minimal
  --prompt="❯ "
  --pointer="➤"
  --marker="✓"
  --preview "bat --style=numbers --color=always --line-range=:500 {}"
  --preview-window=right:60%
'

# Currently used by lazygit to find the config file.
export XDG_CONFIG_HOME="$HOME/.config"

export LANG=de_DE.UTF-8
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"

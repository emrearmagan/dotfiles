eval "$(/opt/homebrew/bin/brew shellenv)"

# This is suppose to configure fzf to always use rg. But not sure how to verify..
export FZF_DEFAULT_COMMAND='rg --files --hidden --glob "!.git/*"'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

export LANG=de_DE.UTF-8

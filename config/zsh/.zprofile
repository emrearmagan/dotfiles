eval "$(/opt/homebrew/bin/brew shellenv)"

# --- Homebrew OpenSSH agent (supports YubiKey / FIDO2)
# macOS's built-in ssh-agent cannot sign with FIDO2 keys.
# This starts the Homebrew version automatically on login so YubiKey SSH works.
export SSH_AUTH_SOCK=/opt/homebrew/var/run/ssh-agent.socket
if [ ! -S "$SSH_AUTH_SOCK" ]; then
  eval $(/opt/homebrew/bin/ssh-agent -a $SSH_AUTH_SOCK) >/dev/null
fi

#This is suppose to configure fzf to always use rg. But not sure how to verify..
export FZF_DEFAULT_COMMAND='rg --files'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS='
  --height=100%
  --border=rounded
  --style=minimal
  --prompt="❯ "
  --pointer="➤"
  --marker="✓"
  --preview "bat --style=numbers --color=always --line-range=:500 {}"
  --preview-window=right:60%
'
export FZF_CTRL_R_OPTS="--preview ''"
export FZF_ALT_C_OPTS="--preview ''"

# Currently used by lazygit to find the config file.
export XDG_CONFIG_HOME="$HOME/.config"

# LLM config location - use XDG standard instead of macOS default
# https://github.com/simonw/llm
export LLM_USER_PATH="$HOME/.config/io.datasette.llm"

export LANG=de_DE.UTF-8
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/ripgreprc"

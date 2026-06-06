eval "$(/opt/homebrew/bin/brew shellenv)"

# --- Homebrew OpenSSH agent (supports YubiKey / FIDO2)
# macOS's built-in ssh-agent cannot sign with FIDO2 keys.
# This starts the Homebrew version automatically on login so YubiKey SSH works.
export SSH_AUTH_SOCK=/opt/homebrew/var/run/ssh-agent.socket
if [ ! -S "$SSH_AUTH_SOCK" ]; then
  eval $(/opt/homebrew/bin/ssh-agent -a $SSH_AUTH_SOCK) >/dev/null
fi

# Currently used by lazygit to find the config file.
export XDG_CONFIG_HOME="$HOME/.config"

export LANG=en_US.UTF-8
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/ripgreprc"

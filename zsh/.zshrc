source ~/.env
source ~/.alias
source ~/.alias.macos
source ~/.functions
source <(fzf --zsh)

#Brew
export PATH=/opt/homebrew/bin:$PATH

#Prompt
export PS1='%F{green}%n@%m: (%~)%f '

#Go
export GOROOT=/usr/local/go
export GOPATH=$HOME/development/go
export GOPATH=$HOME/.go
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:$GOPATH/bin

# zsh-autosuggestions and highlighting
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

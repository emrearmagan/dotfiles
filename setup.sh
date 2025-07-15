#!/usr/bin/env zsh
############################
# This script creates symlinks from the home directory to any desired dotfiles in $HOME/dotfiles
# And also installs Homebrew Packages and Casks (Apps)
# And also sets up iTerm
#
# ** THIS SCRIPT IS NO LONGER MAINTAINED **
############################

# Define color codes
GREEN='\033[0;32m'
NC='\033[0m' # No Color
RED='\033[0;31m'

dotfiledir="$(pwd)"
echo $dotfiledir

# list of files/folders to symlink: associative array (source -> target)
typeset -A files_to_symlink
files_to_symlink=(
    ["config/zsh/.zshrc"]="$HOME/.zshrc"
    ["config/zsh/.zprofile"]="$HOME/.zprofile"

    ["config/system/alias/.alias"]="$HOME/.alias/.alias"
    ["config/system/alias/.alias.custom"]="$HOME/.alias/.custom"
    ["config/system/alias/.alias.macos"]="$HOME/.alias/.macos"
    ["config/system/alias/.functions"]="$HOME/.alias/.functions"

    ["homebrew/Brewfile"]="$HOME/Brewfile"

    ["config/git/.gitconfig"]="$HOME/.gitconfig"
    ["config/git/.gitignore_global"]="$HOME/.gitignore_global"

    ["config/tmux/.tmux.conf"]="$HOME/.tmux.conf"
    ["config/neovim/nvim"]="$HOME/.config/nvim"
    ["config/bat"]="$HOME/.config/bat"
)

# change to the dotfiles directory
echo "Changing to the ${dotfiledir} directory"

# Function to create symlinks safely
create_symlink() {
    local source="$1"
    local target="$2"

    # Check if the target already exists
    if [[ -e "${target}" ]]; then
        if [[ -L "${target}" ]]; then
            # If the target is a symlink, safely replace it
            echo "Replacing symlink: $target"
            # ln -sfn "$source" "$target"
        else
            # If the target is a regular file or directory, warn the user
            echo -e "${RED}Warning: $target already exists and is not a symlink.${NC}"
            echo -e "${RED}Skipping $target${NC}"
        fi
    else
        # Ensure parent directories exist
        mkdir -p "$(dirname "${target}")"
        # Create a new symlink
        echo "Creating symlink: $target"
        ln -s "$source" "$target"
    fi
}

echo -e "${GREEN}Creating symlinks...${NC}"

for src in ${(k)files_to_symlink}; do
    create_symlink "$dotfiledir/$src" "${files_to_symlink[$src]}"
done

echo -e "${GREEN}Symlink creation complete!${NC}"

# Set up iTerm2 preferences if it is installed
if [ -d "/Applications/iTerm.app" ]; then
  echo "Setting up iTerm2 preferences..."

  # Specify the preferences directory
  defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string "${dotfiledir}/config/iterm"

  # Tell iTerm2 to use the custom preferences in the directory
  defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool true

  echo -e "${GREEN}iTerm Complete!${NC}"
else
  echo "Error: iTerm2 is not installed. Skipping iTerm2 setup."
fi


# Run the Homebrew Script
sh ./homebrew/brew.sh
echo -e "${GREEN}Installation Complete!${NC}"
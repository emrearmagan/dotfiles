#!/usr/bin/env zsh
############################
# This script creates symlinks from the home directory to any desired dotfiles in $HOME/dotfiles
# And also installs Homebrew Packages and Casks (Apps)
# And also sets up iTerm
############################

# Define color codes
GREEN='\033[0;32m'
NC='\033[0m' # No Color
RED='\033[0;31m'

dotfiledir="$(pwd)"
echo dotfiledir

# list of files/folders to symlink in ${homedir}
files=(
    zsh/.zshrc
    zsh/.zprofile
    system/.alias
    system/.alias.macos
    system/.functions
    homebrew/Brewfile
    git/.gitconfig
    git/.gitignore_global
    tmux/.tmux.conf
    neovim/.config/nvim # make sure to give nvim. We dont want to override everything inside .config
)

# change to the dotfiles directory
echo "Changing to the ${dotfiledir} directory"

# Function to create symlinks safely
create_symlink() {
    local source="${dotfiledir}/$1"
    local target="${HOME}/${1#*/}" # Strip the top-level directory for the target

    # Check if the target already exists
    if [[ -e "${target}" ]]; then
        if [[ -L "${target}" ]]; then
            # If the target is a symlink, safely replace it
            echo "Replacing symlink: ${target}"
            ln -sfn "${source}" "${target}"
        else
            # If the target is a regular file or directory, warn the user
            echo -e "${RED}Warning: ${target} already exists and is not a symlink.${NC}"
            echo -e "${RED}Skipping ${target}${NC}"
        fi
    else
        # Create a new symlink
        #mkdir -p "$(dirname "${target}")" # Ensure parent directories exist
        echo "Creating symlink: ${target}"
        ln -s "${source}" "${target}"
    fi
}

echo -e "${GREEN}Creating symlinks...${NC}"

for file in "${files[@]}"; do
    create_symlink "${file}"
done

echo -e "${GREEN}Symlink creation complete!${NC}"

# Set up iTerm2 preferences if it is installed
if [ -d "/Applications/iTerm.app" ]; then
  echo "Setting up iTerm2 preferences..."

  # Specify the preferences directory
  defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string "${dotfiledir}/iterm"

  # Tell iTerm2 to use the custom preferences in the directory
  defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool true

  echo -e "${GREEN}iTerm Complete!${NC}"
else
  echo "Error: iTerm2 is not installed. Skipping iTerm2 setup."
fi


# Run the Homebrew Script
sh ./homebrew/brew.sh

echo -e "${GREEN}Installation Complete!${NC}"
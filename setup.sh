#!/usr/bin/env zsh
############################
# This script creates symlinks from the home directory to any desired dotfiles in $HOME/dotfiles
# And also installs Homebrew Packages and Casks (Apps)
# And also sets up iTerm
############################

# Define color codes
GREEN='\033[0;32m'
NC='\033[0m' # No Color

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
    neovim/.config
)

# change to the dotfiles directory
echo "Changing to the ${dotfiledir} directory"

# create symlinks (will overwrite old dotfiles)
for file in "${files[@]}"; do
    if [[ -e "${dotfiledir}/${file}" ]]; then
        #echo "Creating symlink to "${HOME}/${file##*/}" in home directory."
        # ln -sf "${dotfiledir}/${file}" "${HOME}/${file##*/}"
    else
        echo "Warning: ${dotfiledir}/${file} does not exist."
    fi
done

# Function to create symlinks recursively
create_symlink() {
    local source="${dotfiledir}/$1"
    local target="${HOME}/${1#*/}" # Strip the top-level folder

    if [[ -d "${source}" ]]; then
        # Handle directories recursively
        for item in "${source}"/*; do
            local relative_path="${1}/$(basename "${item}")"
            create_symlink "${relative_path}"
        done
    elif [[ -f "${source}" ]]; then
        # Handle files
        mkdir -p "$(dirname "${target}")" # Ensure parent directory exists

        echo "Creating symlink: ${target}"
        ln -sfn "${source}" "${target}"
    else
        echo "Warning: Source does not exist: ${source}"
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
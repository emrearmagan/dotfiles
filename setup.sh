#!/usr/bin/env zsh
############################
# This script creates symlinks from the home directory to any desired dotfiles in $HOME/dotfiles
# And also installs Homebrew Packages and Casks (Apps)
# And also sets up iTerm
############################

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
)

# change to the dotfiles directory
echo "Changing to the ${dotfiledir} directory"

# create symlinks (will overwrite old dotfiles)
for file in "${files[@]}"; do
    if [[ -e "${dotfiledir}/${file}" ]]; then
        echo "Creating symlink to $file in home directory."
        ln -sf "${dotfiledir}/${file}" "${HOME}/${file##*/}"
    else
        echo "Warning: ${dotfiledir}/${file} does not exist."
    fi
done

# Set up iTerm2 preferences if it is installed
if [ -d "/Applications/iTerm.app" ]; then
  echo "Setting up iTerm2 preferences..."

  # Specify the preferences directory
  defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string "${dotfiledir}/iterm"

  # Tell iTerm2 to use the custom preferences in the directory
  defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool true

  echo "iTerm Complete!"
else
  echo "Error: iTerm2 is not installed. Skipping iTerm2 setup."
fi


# Run the Homebrew Script
sh ./homebrew/brew.sh


echo "Installation Complete!"
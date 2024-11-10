#!/usr/bin/env zsh
############################
# This script creates symlinks from the home directory to any desired dotfiles in $HOME/dotfiles
# And also installs MacOS Software
# And also installs Homebrew Packages and Casks (Apps)
# And also sets up VS Code
# And also sets up Sublime Text
############################

dotfiledir="$(pwd)"
echo dotfiledir
# list of files/folders to symlink in ${homedir}
files=(.zshrc .zprofile system/.alias system/.alias.macos system/.functions homebrew/Brewfile)

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

# Run the MacOS Script
#./macOS.sh#

# Run the Homebrew Script
sh ./homebrew/brew.sh

# Run the Sublime Script
#./sublime.sh

echo "Installation Complete!"
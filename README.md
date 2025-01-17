# Emre`s dotfiles

## Installation
⚠ **Warning:** Before using these dotfiles, you should **fork this repository**, review the code, and remove anything you **don’t want or need**.  
**Use at your own risk!**

### **1. Clone the Repository**
```sh
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

### **2. Run the Setup Script**
```sh
sh setup.sh
```
This script will:
- Create **symlinks** for configuration files in your home directory.
- Set up **iTerm2 preferences** (if installed).
- Install **Homebrew packages** from the `Brewfile`.

---

## **Folder Structure**
```
dotfiles/
│── bat/          # Configuration for bat (better cat)
│── git/          # Git config and global ignore
│── homebrew/     # Homebrew setup and Brewfile
│── iterm/        # iTerm2 preferences
│── neovim/       # Neovim configuration
│── system/       # System-wide aliases and functions
│── tmux/         # Tmux configuration
│── zsh/          # Zsh config files (.zshrc, .zprofile)
│── setup.sh      # Setup script to symlink files and install dependencies
```

---

## **What `setup.sh` Does**
- **Creates symlinks** for:
  - `.zshrc`, `.zprofile` (Zsh configuration)
  - `.alias`, `.functions` (System-wide aliases)
  - `.gitconfig`, `.gitignore_global`
  - `.tmux.conf`
  - **Neovim & bat configurations** (inside `~/.config/`)
- **Sets up iTerm2 preferences** (if iTerm2 is installed).
- **Runs the Homebrew installation script**.

---

## **Customization**
If you want to customize your setup:
- Modify **`setup.sh`** to add/remove symlinks.
- Edit the **Brewfile** to include/exclude Homebrew packages.
- Change **Neovim, Zsh, Git, or Tmux configs** as needed.

---

## **License**
MIT License – Use freely, but **at your own risk**.
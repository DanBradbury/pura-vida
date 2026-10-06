#!/usr/bin/env bash
# Pura Vida setup for macOS

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

parse_args "$@"

if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is designed for macOS only."
    exit 1
fi

print_status "Starting macOS setup..."
is_dry_run && print_warning "Dry-run mode: nothing will be installed or changed."

# Install Xcode Command Line Tools if not already installed
if ! xcode-select -p &> /dev/null; then
    print_status "Installing Xcode Command Line Tools..."
    run xcode-select --install
    if ! is_dry_run; then
        print_warning "Please complete the Xcode Command Line Tools installation and re-run this script."
        exit 1
    fi
else
    print_success "Xcode Command Line Tools already installed"
fi

keep_sudo_alive

# Oh My Zsh first: its installer replaces ~/.zshrc, so later additions must come after it
install_oh_my_zsh
set_default_shell_zsh

# Install Homebrew if not already installed
if ! command -v brew &> /dev/null; then
    print_status "Installing Homebrew..."
    run_shell 'NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
else
    print_success "Homebrew already installed"
fi

# Add Homebrew to PATH (Apple Silicon installs to /opt/homebrew)
if [[ $(uname -m) == "arm64" ]]; then
    append_line_once 'eval "$(/opt/homebrew/bin/brew shellenv)"' "$HOME/.zprofile"
    [[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
fi

print_status "Updating Homebrew..."
run brew update

brew_install() {
    local pkg="$1"
    if brew list "$pkg" &> /dev/null; then
        print_success "$pkg already installed"
    else
        print_status "Installing $pkg..."
        run brew install "$@"
    fi
}

brew_install mise
brew_install macvim
brew_install vim
brew_install gh
brew_install iterm2 --cask
brew_install font-caskaydia-mono-nerd-font --cask
brew_install copilot-cli --cask
brew_install codex --cask
brew_install claude-code --cask
brew_install claude --cask
brew_install grok-bot --cask
brew_install obsidian --cask
brew_install mas

# Add mise to zsh profile
append_line_once 'eval "$(mise activate zsh)"' "$HOME/.zshrc"

install_mise_languages

# Divvy from the Mac App Store
if is_dry_run; then
    print_dry "mas install 1000076140  # Divvy"
elif ! mas account &> /dev/null; then
    print_warning "Please sign into the Mac App Store manually, then run:"
    print_warning "mas install 1000076140  # Divvy"
else
    print_status "Installing Divvy from App Store..."
    mas install 1000076140 || print_warning "Divvy install failed; install it from the App Store."
fi

github_auth

if is_dry_run; then
    print_success "Dry run complete. Re-run without --dry-run to install for real."
    exit 0
fi

# Verify installations
print_status "Verifying installations..."
verify_mise_languages

for program in mvim vim gh copilot codex claude; do
    if command -v "$program" &> /dev/null; then
        print_success "$program installed successfully"
    else
        print_error "$program installation failed"
    fi
done

if [[ -d "/Applications/iTerm.app" ]]; then
    print_success "iTerm2 installed successfully"
else
    print_error "iTerm2 installation failed"
fi

for app in Claude "Grok Bot" Obsidian; do
    if [[ -d "/Applications/$app.app" ]] || [[ -d "$HOME/Applications/$app.app" ]]; then
        print_success "$app installed successfully"
    else
        print_error "$app installation failed"
    fi
done

if brew list --cask font-caskaydia-mono-nerd-font &> /dev/null; then
    print_success "CaskaydiaMono Nerd Font installed successfully"
else
    print_error "CaskaydiaMono Nerd Font installation failed"
fi

if mas list 2>/dev/null | grep -q "Divvy"; then
    print_success "Divvy installed successfully"
else
    print_warning "Divvy may not be installed. Check App Store manually."
fi

if [[ -d "$HOME/.oh-my-zsh" ]]; then print_success "Oh My Zsh installed"; else print_error "Oh My Zsh installation failed"; fi

echo
print_success "Setup complete! ¡Pura vida! 🌴"
print_status "In iTerm2, open Settings > Profiles > Text > Font and select 'CaskaydiaMono Nerd Font Mono'."
pause_for_user "Press Enter after selecting the font, or to skip this step for now..."
print_status "Please restart your terminal to ensure zsh is active and mise is properly loaded."

#!/bin/bash

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is designed for macOS only."
    exit 1
fi

print_status "Starting macOS setup..."

# Install Xcode Command Line Tools if not already installed
if ! xcode-select -p &> /dev/null; then
    print_status "Installing Xcode Command Line Tools..."
    xcode-select --install
    print_warning "Please complete the Xcode Command Line Tools installation and re-run this script."
    exit 1
else
    print_success "Xcode Command Line Tools already installed"
fi

# Install Homebrew if not already installed
if ! command -v brew &> /dev/null; then
    print_status "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ $(uname -m) == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    print_success "Homebrew already installed"
fi

# Update Homebrew
print_status "Updating Homebrew..."
brew update

# Install mise
if ! command -v mise &> /dev/null; then
    print_status "Installing mise..."
    brew install mise
else
    print_success "mise already installed"
fi

# Ensure zsh is the default shell
if [[ "$SHELL" != "/bin/zsh" ]] && [[ "$SHELL" != "/usr/local/bin/zsh" ]]; then
    print_status "Setting zsh as default shell..."
    if ! grep -q "/bin/zsh" /etc/shells; then
        echo "/bin/zsh" | sudo tee -a /etc/shells
    fi
    chsh -s /bin/zsh
    print_success "Default shell changed to zsh. Please restart your terminal after the script completes."
fi

# Add mise to zsh profile
SHELL_RC="$HOME/.zshrc"
if ! grep -q 'mise activate' "$SHELL_RC" 2>/dev/null; then
    print_status "Adding mise to $SHELL_RC..."
    echo 'eval "$(mise activate)"' >> "$SHELL_RC"
fi

# Activate mise for current session
eval "$(mise activate)"

# Install languages with mise
print_status "Installing Python with mise..."
mise install python@latest
mise global python@latest

print_status "Installing Ruby with mise..."
mise install ruby@latest
mise global ruby@latest

print_status "Installing Go with mise..."
mise install go@latest
mise global go@latest

print_status "Installing Java with mise..."
mise install java@latest
mise global java@latest

print_status "Installing Node.js with mise..."
mise install node@latest
mise global node@latest

print_status "Installing Rust with mise..."
mise install rust@latest
mise global rust@latest

# Install programs via Homebrew
print_status "Installing MacVim..."
brew install macvim

print_status "Installing Vim..."
brew install vim

print_status "Installing GitHub CLI..."
brew install gh

print_status "Installing iTerm2..."
brew install --cask iterm2

# Install mas (Mac App Store command line interface)
if ! command -v mas &> /dev/null; then
    print_status "Installing mas (Mac App Store CLI)..."
    brew install mas
fi

# Check if signed into App Store
if ! mas account &> /dev/null; then
    print_warning "Please sign into the Mac App Store manually, then run:"
    print_warning "mas install 1000076140  # Divvy"
else
    print_status "Installing Divvy from App Store..."
    mas install 1000076140  # Divvy's App Store ID
fi

# Verify installations
print_status "Verifying installations..."

# Check mise-managed languages
languages=("python" "ruby" "go" "java" "node" "rust")
for lang in "${languages[@]}"; do
    if mise which "$lang" &> /dev/null; then
        version=$(mise current "$lang" 2>/dev/null || echo "unknown")
        print_success "$lang installed: $version"
    else
        print_error "$lang installation failed"
    fi
done

# Check Homebrew-installed programs
programs=("mvim" "vim" "gh")
for program in "${programs[@]}"; do
    if command -v "$program" &> /dev/null; then
        print_success "$program installed successfully"
    else
        print_error "$program installation failed"
    fi
done

# Check if iTerm2 is installed
if [[ -d "/Applications/iTerm.app" ]]; then
    print_success "iTerm2 installed successfully"
else
    print_error "iTerm2 installation failed"
fi

# Check if Divvy is installed
if mas list | grep -q "Divvy"; then
    print_success "Divvy installed successfully"
else
    print_warning "Divvy may not be installed. Check App Store manually."
fi

# Install Oh My Zsh if not already installed
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    print_status "Installing Oh My Zsh..."
    echo
    print_warning "Oh My Zsh installation will start. Please follow the prompts."
    print_status "When Oh My Zsh installation completes, it may start a new shell."
    print_status "If that happens, type 'exit' to return to this setup script."
    echo
    read -p "Press Enter to continue with Oh My Zsh installation..."
    
    # Install Oh My Zsh (this might start a new shell)
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true
    
    # Re-add mise to .zshrc since Oh My Zsh might have overwritten it
    if [[ -f "$HOME/.zshrc" ]] && ! grep -q 'mise activate' "$HOME/.zshrc"; then
        print_status "Re-adding mise to .zshrc..."
        echo 'eval "$(mise activate)"' >> "$HOME/.zshrc"
    fi
    
    print_success "Oh My Zsh installation completed!"
    echo
else
    print_success "Oh My Zsh already installed"
fi

# GitHub CLI Authentication
if command -v gh &> /dev/null; then
    print_status "Setting up GitHub CLI authentication..."
    echo
    print_warning "Please authenticate with GitHub using the GitHub CLI."
    print_status "This will open your browser to complete the authentication process."
    echo
    read -p "Press Enter to continue with GitHub authentication..."
    
    if gh auth login; then
        print_success "GitHub CLI authentication completed!"
    else
        print_warning "GitHub CLI authentication failed or was skipped."
        print_status "You can run 'gh auth login' later to authenticate."
    fi
    echo
fi

print_success "Setup complete!"
print_status "Please restart your terminal to ensure zsh is active and mise is properly loaded."

# Display installed versions
print_status "Installed versions:"
echo "Python: $(mise current python 2>/dev/null || echo 'Not available')"
echo "Ruby: $(mise current ruby 2>/dev/null || echo 'Not available')"
echo "Go: $(mise current go 2>/dev/null || echo 'Not available')"
echo "Java: $(mise current java 2>/dev/null || echo 'Not available')"
echo "Node.js: $(mise current node 2>/dev/null || echo 'Not available')"
echo "Rust: $(mise current rust 2>/dev/null || echo 'Not available')"
echo "MacVim: $(mvim --version | head -n1 2>/dev/null || echo 'Not available')"
echo "Vim: $(vim --version | head -n1 2>/dev/null || echo 'Not available')"
echo "GitHub CLI: $(gh --version 2>/dev/null || echo 'Not available')"
echo "iTerm2: $(test -d "/Applications/iTerm.app" && echo "Installed" || echo "Not available")"
echo "Oh My Zsh: $(test -d "$HOME/.oh-my-zsh" && echo "Installed" || echo "Not available")"

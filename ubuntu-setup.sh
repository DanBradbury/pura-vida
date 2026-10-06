#!/usr/bin/env bash
# Pura Vida setup for Ubuntu LTS (22.04 / 24.04+)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

parse_args "$@"

if [[ "$(uname -s)" != "Linux" ]] || [[ ! -f /etc/os-release ]]; then
    print_error "This script is designed for Ubuntu only."
    exit 1
fi

# shellcheck disable=SC1091
. /etc/os-release
if [[ "${ID:-}" != "ubuntu" ]] && [[ "${ID_LIKE:-}" != *ubuntu* ]]; then
    print_error "This script is designed for Ubuntu (detected: ${PRETTY_NAME:-unknown})."
    exit 1
fi
if [[ "${VERSION:-}" != *LTS* ]]; then
    print_warning "${PRETTY_NAME:-This release} is not an LTS release; continuing anyway."
fi

ARCH="$(dpkg --print-architecture)"            # amd64 / arm64
CODENAME="${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}"
KEYRINGS=/etc/apt/keyrings
APT_UPDATED=0

apt_update() {
    run sudo apt-get update -y
    APT_UPDATED=1
}

apt_install() {
    [[ "$APT_UPDATED" == "1" ]] || apt_update
    run sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
}

is_desktop() { [[ -n "${XDG_CURRENT_DESKTOP:-}" ]] || dpkg -s ubuntu-desktop &> /dev/null; }

print_status "Starting Ubuntu setup on ${PRETTY_NAME} (${ARCH})..."
is_dry_run && print_warning "Dry-run mode: nothing will be installed or changed."

keep_sudo_alive

# --- Base packages -----------------------------------------------------------
print_status "Installing base packages and language build dependencies..."
apt_install \
    build-essential ca-certificates curl git gnupg unzip zip fontconfig \
    zsh vim software-properties-common pkg-config autoconf bison \
    libssl-dev libreadline-dev zlib1g-dev libyaml-dev libffi-dev libgdbm-dev \
    libncurses-dev libsqlite3-dev libbz2-dev liblzma-dev tk-dev uuid-dev libxml2-dev

if is_desktop; then
    print_status "Desktop detected: installing gVim (vim-gtk3, the MacVim equivalent)..."
    apt_install vim-gtk3
fi

run sudo install -d -m 0755 "$KEYRINGS"

# --- GitHub CLI --------------------------------------------------------------
if ! command -v gh &> /dev/null; then
    print_status "Installing GitHub CLI..."
    run_shell "curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee $KEYRINGS/githubcli-archive-keyring.gpg > /dev/null"
    run sudo chmod go+r "$KEYRINGS/githubcli-archive-keyring.gpg"
    run_shell "echo 'deb [arch=$ARCH signed-by=$KEYRINGS/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main' | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null"
    apt_update
    apt_install gh
else
    print_success "GitHub CLI already installed"
fi

# --- Docker Engine -----------------------------------------------------------
if ! command -v docker &> /dev/null; then
    print_status "Installing Docker Engine..."
    run sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o "$KEYRINGS/docker.asc"
    run sudo chmod a+r "$KEYRINGS/docker.asc"
    run_shell "echo 'deb [arch=$ARCH signed-by=$KEYRINGS/docker.asc] https://download.docker.com/linux/ubuntu $CODENAME stable' | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null"
    apt_update
    apt_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
else
    print_success "Docker already installed"
fi
if ! id -nG "${USER:-$(id -un)}" | grep -qw docker; then
    print_status "Adding ${USER:-$(id -un)} to the docker group (use docker without sudo)..."
    run sudo usermod -aG docker "${USER:-$(id -un)}"
fi

# --- lazygit -----------------------------------------------------------------
if ! command -v lazygit &> /dev/null; then
    print_status "Installing lazygit..."
    case "$ARCH" in
        amd64) LG_ARCH=x86_64 ;;
        arm64) LG_ARCH=arm64 ;;
        *) LG_ARCH="" ;;
    esac
    if [[ -z "$LG_ARCH" ]]; then
        print_warning "No lazygit build for $ARCH; skipping."
    else
        run_shell "set -e
            tmp=\$(mktemp -d)
            ver=\$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep -Po '\"tag_name\": *\"v\\K[^\"]*')
            curl -fsSL -o \"\$tmp/lazygit.tar.gz\" \"https://github.com/jesseduffield/lazygit/releases/download/v\${ver}/lazygit_\${ver}_Linux_${LG_ARCH}.tar.gz\"
            tar -xzf \"\$tmp/lazygit.tar.gz\" -C \"\$tmp\" lazygit
            sudo install \"\$tmp/lazygit\" -D -t /usr/local/bin/
            rm -rf \"\$tmp\""
    fi
else
    print_success "lazygit already installed"
fi

# --- Nerd Font (Cascadia Mono) -----------------------------------------------
FONT_DIR="$HOME/.local/share/fonts/CascadiaMono"
if [[ ! -d "$FONT_DIR" ]]; then
    print_status "Installing CaskaydiaMono Nerd Font..."
    run_shell "set -e
        tmp=\$(mktemp -d)
        curl -fsSL -o \"\$tmp/CascadiaMono.zip\" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaMono.zip
        mkdir -p '$FONT_DIR'
        unzip -oq \"\$tmp/CascadiaMono.zip\" -d '$FONT_DIR'
        rm -rf \"\$tmp\"
        fc-cache -f > /dev/null"
else
    print_success "CaskaydiaMono Nerd Font already installed"
fi

# --- Shell: zsh + Oh My Zsh --------------------------------------------------
install_oh_my_zsh
set_default_shell_zsh

# --- mise + languages --------------------------------------------------------
export PATH="$HOME/.local/bin:$PATH"
if ! command -v mise &> /dev/null; then
    print_status "Installing mise..."
    run_shell "curl -fsSL https://mise.run | sh"
else
    print_success "mise already installed"
fi
# shellcheck disable=SC2016
append_line_once 'eval "$(~/.local/bin/mise activate zsh)"' "$HOME/.zshrc"
append_line_once 'eval "$(~/.local/bin/mise activate bash)"' "$HOME/.bashrc"

install_mise_languages

# --- AI coding CLIs ----------------------------------------------------------
# mise exec makes the newly installed Node/npm available before shell activation.
for tool in copilot codex; do
    case "$tool" in
        copilot) package=@github/copilot ;;
        codex) package=@openai/codex ;;
    esac
    if mise exec -- which "$tool" &> /dev/null; then
        print_success "$tool already installed"
    else
        print_status "Installing $tool..."
        run mise exec -- npm install -g "$package"
    fi
done

# --- Desktop apps ------------------------------------------------------------
if is_desktop; then
    case "$ARCH" in
        amd64|arm64)
            if dpkg -s claude-desktop 2>/dev/null | grep -q '^Status: install ok installed$'; then
                print_success "Claude Desktop already installed"
            else
                print_status "Installing Claude Desktop..."
                run sudo curl -fsSL https://downloads.claude.ai/claude-desktop/key.asc -o "$KEYRINGS/claude-desktop.asc"
                run sudo chmod a+r "$KEYRINGS/claude-desktop.asc"
                run_shell "echo 'deb [arch=$ARCH signed-by=$KEYRINGS/claude-desktop.asc] https://downloads.claude.ai/claude-desktop/apt/stable stable main' | sudo tee /etc/apt/sources.list.d/claude-desktop.list > /dev/null"
                apt_update
                apt_install claude-desktop
            fi ;;
        *) print_warning "No Claude Desktop build for $ARCH; skipping." ;;
    esac

    if snap list obsidian &> /dev/null; then
        print_success "Obsidian already installed"
    else
        print_status "Installing Obsidian..."
        command -v snap &> /dev/null || apt_install snapd
        run sudo snap install obsidian --classic
    fi
else
    print_status "No desktop detected: skipping Claude Desktop and Obsidian."
fi

# --- GitHub auth -------------------------------------------------------------
github_auth

# --- Verify ------------------------------------------------------------------
if is_dry_run; then
    print_success "Dry run complete. Re-run without --dry-run to install for real."
    exit 0
fi

print_status "Verifying installations..."
verify_mise_languages
for program in zsh vim gh docker lazygit mise; do
    if command -v "$program" &> /dev/null; then
        print_success "$program installed"
    else
        print_error "$program installation failed"
    fi
done
for program in copilot codex; do
    if mise exec -- which "$program" &> /dev/null; then
        print_success "$program installed"
    else
        print_error "$program installation failed"
    fi
done
if is_desktop; then
    if [[ "$ARCH" == amd64 ]] || [[ "$ARCH" == arm64 ]]; then
        if dpkg -s claude-desktop 2>/dev/null | grep -q '^Status: install ok installed$'; then
            print_success "Claude Desktop installed"
        else
            print_error "Claude Desktop installation failed"
        fi
    fi
    if snap list obsidian &> /dev/null; then
        print_success "Obsidian installed"
    else
        print_error "Obsidian installation failed"
    fi
fi
if [[ -d "$HOME/.oh-my-zsh" ]]; then print_success "Oh My Zsh installed"; else print_error "Oh My Zsh installation failed"; fi
if fc-list 2>/dev/null | grep -qi "CaskaydiaMono"; then print_success "CaskaydiaMono Nerd Font installed"; else print_warning "Nerd Font not detected"; fi

echo
print_success "Setup complete! ¡Pura vida! 🌴"
print_status "Log out and back in so zsh becomes your shell and the docker group applies."

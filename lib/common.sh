#!/usr/bin/env bash
# Shared helpers for pura-vida setup scripts. Source, don't execute.

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

DRY_RUN="${DRY_RUN:-0}"
SKIP_GH_AUTH="${SKIP_GH_AUTH:-0}"

print_status()  { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
print_dry()     { echo -e "${MAGENTA}[DRY-RUN]${NC} $1"; }

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Options:
  -n, --dry-run        Print what would be done without changing anything
      --skip-gh-auth   Don't run 'gh auth login' at the end
  -h, --help           Show this help
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--dry-run) DRY_RUN=1 ;;
            --skip-gh-auth) SKIP_GH_AUTH=1 ;;
            -h|--help) usage; exit 0 ;;
            *) print_error "Unknown option: $1"; usage; exit 1 ;;
        esac
        shift
    done
    export DRY_RUN SKIP_GH_AUTH
}

is_dry_run() { [[ "$DRY_RUN" == "1" ]]; }

# Running as root without sudo installed (e.g. minimal containers): make `sudo` a passthrough.
if [[ "$EUID" -eq 0 ]] && ! command -v sudo &> /dev/null; then
    sudo() {
        while [[ "${1:-}" == -* ]]; do shift; done
        "$@"
    }
    export -f sudo
fi

# Run a command (argv form), or just print it in dry-run mode.
run() {
    if is_dry_run; then
        print_dry "$*"
    else
        "$@"
    fi
}

# Run a shell snippet (for pipes/redirects), or just print it in dry-run mode.
run_shell() {
    if is_dry_run; then
        print_dry "$1"
    else
        bash -c "$1"
    fi
}

# Append a line to a file unless it is already present.
append_line_once() {
    local line="$1" file="$2"
    if grep -qxF "$line" "$file" 2>/dev/null; then
        return 0
    fi
    if is_dry_run; then
        print_dry "append '$line' to $file"
    else
        echo "$line" >> "$file"
    fi
}

has_tty() { { : < /dev/tty; } 2>/dev/null; }

# Prompt the user, reading from the terminal even when the script is piped into bash.
pause_for_user() {
    if is_dry_run; then
        print_dry "would prompt: $1"
        return 0
    fi
    if has_tty; then
        read -r -p "$1" < /dev/tty || true
    fi
}

# Ask for sudo up front and keep the credential alive for the run.
keep_sudo_alive() {
    if is_dry_run; then
        print_dry "sudo -v (request administrator privileges)"
        return 0
    fi
    print_status "Requesting administrator privileges..."
    if has_tty; then
        sudo -v < /dev/tty
    else
        sudo -v
    fi
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
}

MISE_LANGUAGES=("python" "ruby" "go" "java" "node" "rust")

install_mise_languages() {
    for lang in "${MISE_LANGUAGES[@]}"; do
        print_status "Installing ${lang} with mise..."
        run mise use --global --yes "${lang}@latest"
    done
}

verify_mise_languages() {
    for lang in "${MISE_LANGUAGES[@]}"; do
        if mise which "$lang" &> /dev/null; then
            print_success "$lang installed: $(mise current "$lang" 2>/dev/null || echo unknown)"
        else
            print_error "$lang installation failed"
        fi
    done
}

# Must run before anything else writes to ~/.zshrc: the installer replaces it with its template.
install_oh_my_zsh() {
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        print_success "Oh My Zsh already installed"
        return 0
    fi
    print_status "Installing Oh My Zsh..."
    # --unattended: don't drop into a new zsh mid-script or change the login shell (handled separately)
    run_shell 'RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'
}

set_default_shell_zsh() {
    local zsh_path
    zsh_path="$(command -v zsh || echo /bin/zsh)"
    if [[ "$(basename "${SHELL:-}")" == "zsh" ]]; then
        print_success "zsh is already the default shell"
        return 0
    fi
    print_status "Setting zsh as default shell..."
    if ! grep -qx "$zsh_path" /etc/shells 2>/dev/null; then
        run_shell "echo '$zsh_path' | sudo tee -a /etc/shells > /dev/null"
    fi
    run sudo chsh -s "$zsh_path" "${USER:-$(id -un)}"
    print_success "Default shell set to zsh. Log out and back in for it to take effect."
}

github_auth() {
    if [[ "$SKIP_GH_AUTH" == "1" ]]; then
        print_status "Skipping GitHub CLI authentication (--skip-gh-auth)."
        return 0
    fi
    if is_dry_run; then
        print_dry "gh auth login"
        return 0
    fi
    command -v gh &> /dev/null || return 0
    if gh auth status &> /dev/null; then
        print_success "GitHub CLI already authenticated"
        return 0
    fi
    if ! has_tty; then
        print_warning "No terminal available; run 'gh auth login' later."
        return 0
    fi
    print_status "Setting up GitHub CLI authentication..."
    pause_for_user "Press Enter to continue with GitHub authentication..."
    if gh auth login < /dev/tty; then
        print_success "GitHub CLI authentication completed!"
    else
        print_warning "GitHub CLI authentication failed or was skipped."
        print_status "You can run 'gh auth login' later to authenticate."
    fi
}

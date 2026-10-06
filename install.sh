#!/usr/bin/env bash
# Pura Vida bootstrapper.
#
#   curl -fsSL https://raw.githubusercontent.com/DanBradbury/pura-vida/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/DanBradbury/pura-vida/main/install.sh | bash -s -- --dry-run
#
# Shows the banner, detects the OS, fetches the repo (if not run from a checkout)
# and hands off to mac-setup.sh or ubuntu-setup.sh with the same arguments.

# Everything lives in main() so bash reads the whole file before running anything when piped.
main() {
    set -euo pipefail

    local repo="${PURA_VIDA_REPO:-DanBradbury/pura-vida}"
    local ref="${PURA_VIDA_REF:-main}"

    local arg
    for arg in "$@"; do
        case "$arg" in
            -h|--help)
                cat <<EOF
Pura Vida - one-line dev machine setup for macOS and Ubuntu LTS.

Usage:
  curl -fsSL https://raw.githubusercontent.com/$repo/$ref/install.sh | bash [-s -- options]

Options:
  -n, --dry-run        Print what would be done without changing anything
      --skip-gh-auth   Don't run 'gh auth login' at the end
  -h, --help           Show this help

Environment:
  PURA_VIDA_REF        Git branch/tag to install from (default: main)
EOF
                return 0 ;;
        esac
    done

    print_banner

    local platform_script
    case "$(uname -s)" in
        Darwin) platform_script="mac-setup.sh" ;;
        Linux)
            if [[ -f /etc/os-release ]] && grep -qiE '^(ID|ID_LIKE)=.*ubuntu' /etc/os-release; then
                platform_script="ubuntu-setup.sh"
            else
                echo "Sorry, only macOS and Ubuntu are supported right now." >&2
                return 1
            fi ;;
        *)
            echo "Sorry, only macOS and Ubuntu are supported right now." >&2
            return 1 ;;
    esac

    # Use the local checkout when run as ./install.sh, otherwise download the repo.
    local src_dir=""
    if [[ -n "${BASH_SOURCE[0]:-}" ]] && [[ -f "${BASH_SOURCE[0]}" ]]; then
        src_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    fi
    if [[ -z "$src_dir" ]] || [[ ! -f "$src_dir/$platform_script" ]] || [[ ! -f "$src_dir/lib/common.sh" ]]; then
        src_dir="$(mktemp -d "${TMPDIR:-/tmp}/pura-vida.XXXXXX")"
        trap 'rm -rf "'"$src_dir"'"' EXIT
        echo "Downloading $repo@$ref..."
        curl -fsSL "https://github.com/$repo/archive/$ref.tar.gz" | tar -xz -C "$src_dir" --strip-components=1
    fi

    # stdin may be the curl pipe; give the setup script the real terminal when there is one.
    if { : < /dev/tty; } 2>/dev/null; then
        bash "$src_dir/$platform_script" "$@" < /dev/tty
    else
        bash "$src_dir/$platform_script" "$@"
    fi
}

print_banner() {
    local y='' o='' b='' c='' g='' s='' w='' r=''
    if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
        y=$'\033[1;33m'; o=$'\033[0;33m'; b=$'\033[0;34m'; c=$'\033[1;36m'
        g=$'\033[0;32m'; s=$'\033[0;93m'; w=$'\033[1;37m'; r=$'\033[0m'
    fi
    cat <<EOF

${y}                                      \\     |     /${r}
${g}     __ _.--..--._ _ ${r}${y}            .     \\    |    /     .${r}
${g}  .-' _/   _/\\_   \\_'-. ${r}${y}           '.   .-"""""-.   .'${r}
${g} |__ /   _/\\__/\\_   \\__|${r}${y}      -- -- -  /         \\  - -- --${r}
${g}    |___/\\_\\${o}__/${g}  \\___|${r}${b}  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${r}
${o}           \\__/        ${c}~~~~   ~~~~~~~~~~   ${y}~ ~${c}   ~~~~~~~~   ~~~~${r}
${o}            \\__/     ${b}~~~~~~~~     ~~~~~~~~~${y}~ ~${b}~~~~~~     ~~~~~~~~${r}
${o}             \\__/  ${c}~~~~    ~~~~~~~~    ~~~~~${y}~${c}~~~    ~~~~~~~~    ~~~~${r}
${s}  ____________\\__/_____________________________________________________${r}
${s} .  .  :  .  . : .  .  .  :  .  . : .  .  :  .  .  :  .  . : .  .  : .  .${r}

${w}     ┏━┓╻ ╻┏━┓┏━┓   ╻ ╻╻╺┳┓┏━┓${r}
${w}     ┣━┛┃ ┃┣┳┛┣━┫   ┃┏┛┃ ┃┃┣━┫${r}     ${c}just the good life${r}
${w}     ╹  ┗━┛╹┗╸╹ ╹   ┗┛ ╹╺┻┛╹ ╹${r}     ${o}macOS · Ubuntu LTS${r}

EOF
}

main "$@"

# Pura Vida
Just the good life. Turn your new Mac or Ubuntu LTS machine into a fully-configured modern development machine by running a single command.

## Install
On a fresh macOS or Ubuntu LTS (22.04 / 24.04+) machine, paste this into a terminal:

```sh
curl -fsSL https://raw.githubusercontent.com/DanBradbury/pura-vida/main/install.sh | bash
```

Want to see what it would do first? Do a dry run (nothing is installed or changed):

```sh
curl -fsSL https://raw.githubusercontent.com/DanBradbury/pura-vida/main/install.sh | bash -s -- --dry-run
```

Options (pass after `bash -s --`):
- `-n`, `--dry-run`: print every command instead of running it
- `--skip-gh-auth`: skip the `gh auth login` step at the end
- `-h`, `--help`: show help

The installer detects your OS, then runs `mac-setup.sh` or `ubuntu-setup.sh`. Set `PURA_VIDA_REF=<branch>` to install from a different branch. From a clone you can also run `./install.sh --dry-run` directly.

## Inspiration
Things like [omakub.org](https://omakub.org/) and other 1-line installers ([install.sh](https://github.com/donnybrilliant/install.sh), etc) are pretty attractive in their own regards and I would recommend either if the description fits your bill.

The aim of the `pura-vida` setup is to remove the headache and initial tool indecision out of the mix and provide a set of tools to get you working effectively as soon as possible. This project is not for folks who already have their dotfiles fully-baked + copy-pasta already established for new machine setup.

## What's in the setup
| | macOS | Ubuntu LTS |
|---|---|---|
| Shell | zsh + Oh My Zsh | zsh + Oh My Zsh |
| Terminal | iTerm2 | (default GNOME Terminal) |
| Editor | vim + MacVim | vim + gVim (desktop only) |
| Git | GitHub CLI (`gh`) | GitHub CLI (`gh`), lazygit |
| AI coding | GitHub Copilot CLI, OpenAI Codex CLI, Claude Code CLI | GitHub Copilot CLI, OpenAI Codex CLI, Claude Code CLI |
| Desktop apps | Claude Desktop, Grok Bot, Obsidian | Claude Desktop, Grok Bot (amd64/arm64), Obsidian (desktop only) |
| Clipboard | | Pano (supported GNOME desktops only) |
| Containers | | Docker Engine + Compose |
| System monitor | | btop++ (`btop`) |
| Fonts | Nerd Font (Cascadia Mono) | Nerd Font (Cascadia Mono) |
| Languages | mise: Python/Ruby/Go/Java/Node.js/Rust | mise: Python/Ruby/Go/Java/Node.js/Rust |
| Window mgmt | Divvy (App Store) | |

macOS installs the AI tools and desktop apps through Homebrew casks. Ubuntu installs the CLIs through npm using mise-managed Node.js, Claude Desktop through Anthropic's apt repository, Grok Bot through the official release feed's `.deb` package, and Obsidian through Snap. Desktop apps are skipped on Ubuntu machines without a desktop environment. See [Grok Bot's installation guide](https://docs.x.ai/grok-bot/get-started#linux) and [release feed documentation](https://prod.cursor.com/docs/grok-bot/deployment).

Ubuntu GNOME desktops also install Pano's dependencies and a compatible [upstream release](https://github.com/oae/gnome-shell-pano/releases): `v19` for GNOME 42–44 (Ubuntu 22.04), or `v23-alpha5` for GNOME 45–48 (including Ubuntu 24.04). Other GNOME versions are skipped. If Pano cannot be enabled immediately, log out and back in, then run `gnome-extensions enable pano@elhan.io`. Toggle the clipboard with Super+Shift+V.

Both platforms install CaskaydiaMono Nerd Font (the patched Cascadia Mono font). After setup, the installer prompts you to select `CaskaydiaMono Nerd Font Mono` in iTerm2 on macOS or GNOME Terminal on Ubuntu desktops. Press Enter when done or to skip the step. For SSH sessions, install and select the font on the machine running your terminal.

After setup, run `copilot` and use `/login`, run `codex` and `claude` to sign in, and open Claude Desktop and Grok Bot to sign in. Grok Bot uses your Cursor account and requires an eligible plan. GitHub CLI authentication does not sign you into these tools.

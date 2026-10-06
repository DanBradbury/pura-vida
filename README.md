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
| Containers | | Docker Engine + Compose |
| Fonts | | Nerd Font (Cascadia Mono) |
| Languages | mise: Python/Ruby/Go/Java/Node.js/Rust | mise: Python/Ruby/Go/Java/Node.js/Rust |
| Window mgmt | Divvy (App Store) | |

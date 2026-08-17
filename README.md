# Dotfiles

Public, portable configuration backed by Git, with machine-specific settings kept locally.

## How it works

`init.sh` links files from this repository into their normal locations under `$HOME`. Existing files are moved to a timestamped directory under `~/.dotfiles-backup` before links are created.

For example:

```text
~/.zshrc       -> ~/.dotfiles/home/.zshrc
~/.tmux.conf   -> ~/.dotfiles/home/.tmux.conf
~/.config/nvim -> ~/.dotfiles/home/.config/nvim
```

The script is safe to rerun. It is normally needed only after the first clone or when a new managed application is added.

## New machine

Install Homebrew, then clone this repository:

```sh
git clone https://github.com/ryan-saffer/.dotfiles.git "$HOME/.dotfiles"
brew bundle --file "$HOME/.dotfiles/Brewfile"
sh "$HOME/.dotfiles/init.sh"
```

Install the remaining shell tools and tmux plugin manager:

```sh
git clone https://github.com/nvm-sh/nvm.git "$HOME/.nvm"
git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
mkdir -p "$HOME/workspace"
git clone https://github.com/bigH/git-fuzzy.git "$HOME/workspace/git-fuzzy"
```

Run `sh ~/.dotfiles/init.sh` again if an installer replaced one of the managed links.

## Local configuration

Everything under `local/` is ignored by Git and exists only on the current machine. Templates live under `examples/`.

```sh
mkdir -p "$HOME/.dotfiles/local/zsh" "$HOME/.dotfiles/local/tmux" \
  "$HOME/.dotfiles/local/git" "$HOME/.dotfiles/local/opencode"
cp "$HOME/.dotfiles/examples/local.zsh" "$HOME/.dotfiles/local/zsh/local.zsh"
cp "$HOME/.dotfiles/examples/local.tmux.conf" "$HOME/.dotfiles/local/tmux/local.conf"
cp "$HOME/.dotfiles/examples/local.gitconfig" "$HOME/.dotfiles/local/git/config"
cp "$HOME/.dotfiles/examples/local.opencode.json" "$HOME/.dotfiles/local/opencode/opencode.json"
sh "$HOME/.dotfiles/init.sh"
```

Use these files for machine paths, work aliases, project-specific tmux sessions, and Git identity. Because they are intentionally not committed, back them up separately if needed.

Git uses the machine-local identity by default and overrides it with `local/git/personal.conf` for every repository under `~/personal/`.

## Secrets

Never put credentials in shared or local Git-tracked files. Prefer a password manager; otherwise create `local/zsh/secrets.zsh`, restrict it with `chmod 600`, and rerun `init.sh`.

This repository is public. Check `git diff --cached` before every commit.

## Daily workflow

Configuration changes made through the usual paths modify this repository through the symlinks:

```sh
git -C "$HOME/.dotfiles" status
git -C "$HOME/.dotfiles" add .
git -C "$HOME/.dotfiles" commit -m "update dotfiles"
git -C "$HOME/.dotfiles" push
```

On another machine:

```sh
git -C "$HOME/.dotfiles" pull
```

Most changes take effect immediately. Restart or reload the relevant application when required.

## Finding files

- `vf` searches the current directory with FZF and opens the selected file in Neovim.
- `vf path/to/search` searches a specific directory.
- `vfh` searches your home directory while skipping caches and macOS application data.
- Type `nvim ` and press `Ctrl+T` to insert an FZF-selected file into the current command.

## Managed configuration

- Zsh shared preferences
- tmux shared preferences
- Neovim and its plugin lockfile
- OpenCode preferences and reusable skills
- Ghostty
- btop
- neofetch
- Shared Git configuration and global ignores

Authentication databases, caches, logs, downloaded extensions, generated state, and application data are deliberately excluded.

OpenCode is linked entry-by-entry so generated dependencies and authentication state can remain in `~/.config/opencode`. Its ignored `local.json` overlay is loaded through `OPENCODE_CONFIG` for machine-specific MCP servers and instructions.

Run `opencode` without Claude Code authentication, or `opencode-claude` to load `opencode-claude-auth` for that OpenCode process.

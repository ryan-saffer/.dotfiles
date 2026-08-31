#!/bin/sh

set -eu

DOTFILES_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
BACKUP_DIR=${DOTFILES_BACKUP_DIR:-"$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"}
BACKED_UP=0

link_path() {
  source_path=$1
  target_path=$2

  if [ ! -e "$source_path" ] && [ ! -L "$source_path" ]; then
    return
  fi

  if [ -L "$target_path" ] && [ "$(readlink "$target_path")" = "$source_path" ]; then
    printf 'ok      %s\n' "$target_path"
    return
  fi

  mkdir -p "$(dirname "$target_path")"

  if [ -e "$target_path" ] || [ -L "$target_path" ]; then
    relative_path=${target_path#"$HOME"/}
    backup_path="$BACKUP_DIR/$relative_path"
    mkdir -p "$(dirname "$backup_path")"
    mv "$target_path" "$backup_path"
    BACKED_UP=1
    printf 'backup  %s -> %s\n' "$target_path" "$backup_path"
  fi

  ln -s "$source_path" "$target_path"
  printf 'link    %s -> %s\n' "$target_path" "$source_path"
}

link_path "$DOTFILES_DIR/home/.zshrc" "$HOME/.zshrc"
link_path "$DOTFILES_DIR/home/.tmux.conf" "$HOME/.tmux.conf"
link_path "$DOTFILES_DIR/home/.gitconfig" "$HOME/.gitconfig"
link_path "$DOTFILES_DIR/home/.gitignore_global" "$HOME/.gitignore_global"
link_path "$DOTFILES_DIR/home/.agents/skills" "$HOME/.agents/skills"
for zsh_path in "$DOTFILES_DIR"/home/.config/zsh/*.zsh; do
  [ -e "$zsh_path" ] || continue
  link_path "$zsh_path" "$HOME/.config/zsh/${zsh_path##*/}"
done

for config_path in "$DOTFILES_DIR"/home/.config/*; do
  [ -e "$config_path" ] || continue
  [ "${config_path##*/}" = "zsh" ] && continue
  [ "${config_path##*/}" = "opencode" ] && continue
  link_path "$config_path" "$HOME/.config/${config_path##*/}"
done

# OpenCode stores generated dependencies and authentication beside its config,
# so manage only the explicitly shared entries rather than the whole directory.
for opencode_path in "$DOTFILES_DIR"/home/.config/opencode/*; do
  [ -e "$opencode_path" ] || continue
  link_path "$opencode_path" "$HOME/.config/opencode/${opencode_path##*/}"
done

link_path "$DOTFILES_DIR/local/zsh/local.zsh" "$HOME/.config/zsh/local.zsh"
link_path "$DOTFILES_DIR/local/zsh/secrets.zsh" "$HOME/.config/zsh/secrets.zsh"
link_path "$DOTFILES_DIR/local/tmux/local.conf" "$HOME/.config/tmux/local.conf"
link_path "$DOTFILES_DIR/local/git/config" "$HOME/.config/git/local.conf"
link_path "$DOTFILES_DIR/local/git/personal.conf" "$HOME/.config/git/personal.conf"
link_path "$DOTFILES_DIR/local/opencode/opencode.json" "$HOME/.config/opencode/local.json"
link_path "$DOTFILES_DIR/local/opencode/opencode-v2.json" "$HOME/.config/opencode/local-v2.json"
link_path "$DOTFILES_DIR/local/opencode/AGENTS.md" "$HOME/.config/opencode/AGENTS.md"
link_path "$DOTFILES_DIR/local/opencode/datadog.md" "$HOME/.config/opencode/datadog.md"

for script_path in "$DOTFILES_DIR"/local/bin/*; do
  [ -e "$script_path" ] || continue
  link_path "$script_path" "$HOME/.local/bin/${script_path##*/}"
done

if [ "$BACKED_UP" -eq 1 ]; then
  printf '\nExisting files were preserved in %s\n' "$BACKUP_DIR"
fi

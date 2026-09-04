#!/bin/sh

set -eu

DOTFILES_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
BACKUP_DIR=${DOTFILES_BACKUP_DIR:-"$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"}
BACKED_UP=0

ensure_local_directory() {
  directory_path=$1

  if [ -d "$directory_path" ]; then
    return
  fi

  if [ -e "$directory_path" ] || [ -L "$directory_path" ]; then
    printf 'error   %s exists and is not a directory\n' "$directory_path" >&2
    return 1
  fi

  mkdir -p "$directory_path"
  printf 'create  %s/\n' "$directory_path"
}

ensure_local_file() {
  file_path=$1
  template_path=${2:-}
  file_mode=${3:-}

  if [ -e "$file_path" ] || [ -L "$file_path" ]; then
    return
  fi

  mkdir -p "$(dirname "$file_path")"

  if [ -n "$template_path" ]; then
    if [ ! -f "$template_path" ]; then
      printf 'error   missing local template %s\n' "$template_path" >&2
      return 1
    fi

    cp "$template_path" "$file_path"
  else
    : > "$file_path"
  fi

  if [ -n "$file_mode" ]; then
    chmod "$file_mode" "$file_path"
  fi

  printf 'create  %s\n' "$file_path"
}

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

prepare_directory() {
  target_path=$1

  if [ -d "$target_path" ] && [ ! -L "$target_path" ]; then
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

  mkdir -p "$target_path"
}

# Bootstrap ignored machine-local configuration on a fresh clone. Existing
# local files are never changed.
ensure_local_directory "$DOTFILES_DIR/local/.agents/skills"
ensure_local_directory "$DOTFILES_DIR/local/bin"
ensure_local_directory "$DOTFILES_DIR/local/fastfetch"
ensure_local_file "$DOTFILES_DIR/local/zsh/local.zsh" "$DOTFILES_DIR/examples/local.zsh"
ensure_local_file "$DOTFILES_DIR/local/zsh/secrets.zsh" "$DOTFILES_DIR/examples/secrets.zsh" 600
ensure_local_file "$DOTFILES_DIR/local/tmux/local.conf" "$DOTFILES_DIR/examples/local.tmux.conf"
ensure_local_file "$DOTFILES_DIR/local/git/config" "$DOTFILES_DIR/examples/local.gitconfig"
ensure_local_file "$DOTFILES_DIR/local/git/personal.conf" "$DOTFILES_DIR/examples/local.gitconfig"
ensure_local_file "$DOTFILES_DIR/local/opencode/opencode.json" "$DOTFILES_DIR/examples/local.opencode.json"
ensure_local_file "$DOTFILES_DIR/local/opencode/opencode-v2.json" "$DOTFILES_DIR/examples/local.opencode-v2.json"
ensure_local_file "$DOTFILES_DIR/local/opencode/datadog.md"
ensure_local_file "$DOTFILES_DIR/local/bin/tmux-setup" "$DOTFILES_DIR/examples/tmux-setup" 755
ensure_local_file "$DOTFILES_DIR/local/fastfetch/logo.txt"

link_path "$DOTFILES_DIR/home/.zshrc" "$HOME/.zshrc"
link_path "$DOTFILES_DIR/home/.tmux.conf" "$HOME/.tmux.conf"
link_path "$DOTFILES_DIR/home/.gitconfig" "$HOME/.gitconfig"
link_path "$DOTFILES_DIR/home/.gitignore_global" "$HOME/.gitignore_global"

# Link skills entry-by-entry so shared and machine-local skills can coexist.
# A local skill with the same name overrides its shared counterpart.
prepare_directory "$HOME/.agents/skills"
for skill_path in "$DOTFILES_DIR"/home/.agents/skills/*; do
  [ -e "$skill_path" ] || continue
  skill_name=${skill_path##*/}
  if [ -e "$DOTFILES_DIR/local/.agents/skills/$skill_name" ]; then
    continue
  fi
  link_path "$skill_path" "$HOME/.agents/skills/$skill_name"
done
for skill_path in "$DOTFILES_DIR"/local/.agents/skills/*; do
  [ -e "$skill_path" ] || continue
  link_path "$skill_path" "$HOME/.agents/skills/${skill_path##*/}"
done

for zsh_path in "$DOTFILES_DIR"/home/.config/zsh/*.zsh; do
  [ -e "$zsh_path" ] || continue
  link_path "$zsh_path" "$HOME/.config/zsh/${zsh_path##*/}"
done

for config_path in "$DOTFILES_DIR"/home/.config/*; do
  [ -e "$config_path" ] || continue
  [ "${config_path##*/}" = "zsh" ] && continue
  [ "${config_path##*/}" = "opencode" ] && continue
  [ "${config_path##*/}" = "fastfetch" ] && continue
  link_path "$config_path" "$HOME/.config/${config_path##*/}"
done

# Keep the Fastfetch layout shared while allowing each machine to provide its
# own ignored logo file.
prepare_directory "$HOME/.config/fastfetch"
for fastfetch_path in "$DOTFILES_DIR"/home/.config/fastfetch/*; do
  [ -e "$fastfetch_path" ] || continue
  link_path "$fastfetch_path" "$HOME/.config/fastfetch/${fastfetch_path##*/}"
done
link_path "$DOTFILES_DIR/local/fastfetch/logo.txt" "$HOME/.config/fastfetch/logo.txt"

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
link_path "$DOTFILES_DIR/local/opencode/datadog.md" "$HOME/.config/opencode/datadog.md"
link_path "$DOTFILES_DIR/local/opencode/datadog.md" "$HOME/AGENTS.md"

for script_path in "$DOTFILES_DIR"/local/bin/*; do
  [ -e "$script_path" ] || continue
  link_path "$script_path" "$HOME/.local/bin/${script_path##*/}"
done

if [ "$BACKED_UP" -eq 1 ]; then
  printf '\nExisting files were preserved in %s\n' "$BACKUP_DIR"
fi

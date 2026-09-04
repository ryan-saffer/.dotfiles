if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=10000

setopt append_history
setopt share_history
setopt hist_ignore_dups
setopt hist_ignore_space
setopt interactive_comments

export GIT_EDITOR="nvim"
export EDITOR="nvim"
export VISUAL="nvim"
export PATH="$HOME/workspace/git-fuzzy/bin:$PATH"

export EZA_CONFIG_DIR="$HOME/.config/eza"

alias ls='eza --grid --width=80 --icons=auto --group-directories-first'
alias ll='eza --long --all --header --git --icons=auto --group-directories-first'
alias tree='eza --tree --icons=auto'
alias wip='git add . && git commit -m "feat(wip): wip"'
alias unwip='git reset --soft HEAD~1'
alias setup="$HOME/.local/bin/tmux-setup"
alias checkout='git checkout "$(git fuzzy branch)"'
alias rebase='git rebase "$(git fuzzy branch)"'
alias merge='git merge "$(git fuzzy branch)"'
alias gg='lazygit'

_nvim_find_file() {
  local root=$1
  shift

  local selected
  selected=$(fd --type f --hidden --exclude .git --exclude node_modules "$@" . "$root" 2>/dev/null |
    fzf \
      --prompt='Open file > ' \
      --height=80% \
      --layout=reverse \
      --border \
      --preview='bat --color=always --style=numbers --line-range=:500 -- {}') || return

  [[ -n "$selected" ]] && nvim -- "$selected"
}

vf() {
  _nvim_find_file "${1:-.}"
}

vfh() {
  _nvim_find_file "$HOME" --exclude Library --exclude .cache --exclude .Trash
}

cdh() {
  local selected
  selected=$(fd --type d --hidden --exclude .git --exclude node_modules . / 2>/dev/null |
    fzf \
      --prompt='Change directory > ' \
      --height=80% \
      --layout=reverse \
      --border) || return

  [[ -n "$selected" ]] && builtin cd -- "$selected"
}

alias f='vf'

export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}

_fzf_compgen_dir() {
  fd --type=d --hidden --exclude .git . "$1"
}

export SDKMAN_DIR="$HOME/.sdkman"
sdk() {
  unset -f sdk
  [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] || return 1
  source "$SDKMAN_DIR/bin/sdkman-init.sh"
  sdk "$@"
}

# NVM is useful but expensive to source, so load it only when first needed.
if [[ -n "${XDG_CONFIG_HOME:-}" ]]; then
  export NVM_DIR="$XDG_CONFIG_HOME/nvm"
else
  export NVM_DIR="$HOME/.nvm"
fi
_load_nvm() {
  [[ "${_nvm_loaded:-0}" -eq 1 ]] && return
  [[ -s "$NVM_DIR/nvm.sh" ]] || return 1
  unfunction nvm node npm npx 2>/dev/null
  source "$NVM_DIR/nvm.sh"
  typeset -g _nvm_loaded=1
}

nvm() {
  _load_nvm && nvm "$@"
}

node() {
  _load_nvm && command node "$@"
}

npm() {
  _load_nvm && command npm "$@"
}

npx() {
  _load_nvm && command npx "$@"
}

_find_nvmrc() {
  local directory=$PWD

  while [[ "$directory" != / ]]; do
    if [[ -r "$directory/.nvmrc" ]]; then
      REPLY="$directory/.nvmrc"
      return 0
    fi
    directory=${directory:h}
  done

  return 1
}

_use_project_node() {
  local nvmrc_path

  if _find_nvmrc; then
    nvmrc_path=$REPLY
    _load_nvm || return
    nvm use --silent "$(<"$nvmrc_path")"
  elif [[ -n "${NVM_BIN:-}" ]]; then
    [[ "$(nvm current)" == "$(nvm version default)" ]] || nvm use --silent default
  fi
}

autoload -Uz add-zsh-hook
add-zsh-hook chpwd _use_project_node
_use_project_node

[[ -r "$HOME/.local/bin/env" ]] && source "$HOME/.local/bin/env"
[[ -r "$HOME/.vite-plus/env" ]] && source "$HOME/.vite-plus/env"

# Expose the default Node to child processes such as Starship without eagerly loading NVM.
if [[ -r "$NVM_DIR/alias/default" ]]; then
  nvm_default_version="$(<"$NVM_DIR/alias/default")"
  nvm_default_bins=("$NVM_DIR"/versions/node/v${nvm_default_version#v}*/bin(NnOn))
  [[ -n "${nvm_default_bins[1]:-}" ]] && export PATH="${nvm_default_bins[1]}:$PATH"
  unset nvm_default_version nvm_default_bins
fi

export PATH="$HOME/.opencode/bin:$PATH"

opencode2() {
  OPENCODE_CONFIG="$HOME/.config/opencode/local-v2.json" command opencode2 "$@"
}

opencode() {
  opencode2 "$@"
}

opencode-v1() {
  OPENCODE_CONFIG="$HOME/.config/opencode/local.json" command opencode "$@"
}

opencode-claude() {
  OPENCODE_CONFIG="$HOME/.config/opencode/local.json" \
    OPENCODE_CONFIG_CONTENT='{"plugin":["opencode-claude-auth@latest"]}' \
    command opencode "$@"
}

git-prune-local-gone() {
  git fetch --prune

  local current_branch
  current_branch="$(git branch --show-current)"

  git for-each-ref --format='%(refname:short) %(upstream:track)' refs/heads \
    | awk '$2 == "[gone]" { print $1 }' \
    | while read -r branch; do
        if [[ "$branch" == "$current_branch" ]]; then
          echo "Skipping current branch: $branch"
          continue
        fi

        echo "Deleting local branch: $branch"
        git branch -D "$branch"
      done
}

function y() {
	local tmp cwd; tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd" || builtin true
	command rm -f -- "$tmp"
}

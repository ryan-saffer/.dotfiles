# Homebrew installs additional completion definitions here.
typeset -U fpath
for completion_dir in \
  /opt/homebrew/share/zsh-completions \
  /opt/homebrew/share/zsh/site-functions \
  /usr/local/share/zsh-completions \
  /usr/local/share/zsh/site-functions; do
  [[ -d "$completion_dir" ]] && fpath=("$completion_dir" $fpath)
done
unset completion_dir

autoload -Uz compinit
completion_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
[[ -d "$completion_cache" ]] || mkdir -p "$completion_cache"
completion_dump="$completion_cache/zcompdump-$ZSH_VERSION"
if [[ -s "$completion_dump" && "$completion_dump" -nt "$HOME/.config/zsh/interactive.zsh" ]]; then
  compinit -C -d "$completion_dump"
else
  compinit -d "$completion_dump"
fi
unset completion_cache completion_dump

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'

for completion_script in "${zsh_completion_scripts[@]}"; do
  [[ -r "$completion_script" ]] && source "$completion_script"
done
unset completion_script zsh_completion_scripts

# Use Emacs-style editing so Ctrl+E accepts the current autosuggestion.
bindkey -e

if (( $+commands[fzf] )); then
  # fzf 0.74.2 tries to restore zsh's read-only `zle` option after setup.
  eval "$(fzf --zsh)" 2>/dev/null

  _vfh_leader_widget() {
    if [[ "$BUFFER" == ' ' && "$CURSOR" -eq 1 ]]; then
      BUFFER=''
      CURSOR=0
      zle -I
      vfh
      zle reset-prompt
      return
    fi

    LBUFFER+=' '
  }
  zle -N _vfh_leader_widget
  bindkey ' ' _vfh_leader_widget
fi

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#ff00ff,bg=cyan,bold,underline'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
for autosuggestions in \
  /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh; do
  if [[ -r "$autosuggestions" ]]; then
    source "$autosuggestions"
    break
  fi
done
unset autosuggestions

if (( $+commands[starship] )); then
  eval "$(starship init zsh)"
fi

# Syntax highlighting must be sourced after all widget integrations.
for highlighting in \
  /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  if [[ -r "$highlighting" ]]; then
    source "$highlighting"
    break
  fi
done
unset highlighting

# Shared preferences are versioned; machine configuration and secrets are not.
source "$HOME/.config/zsh/shared.zsh"

[[ -r "$HOME/.config/zsh/secrets.zsh" ]] && source "$HOME/.config/zsh/secrets.zsh"
[[ -r "$HOME/.config/zsh/local.zsh" ]] && source "$HOME/.config/zsh/local.zsh"

# Interactive integrations load last so local PATH and fpath changes are visible.
source "$HOME/.config/zsh/interactive.zsh"
export PATH=$PATH:$HOME/.maestro/bin

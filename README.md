# Steps to set a new Mac up just how I like it

## Install oh-my-zsh

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

## Install zsh-autosuggestions

```bash
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```

## Install nvm

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
```

> Once installed, be sure to remove the lines it added to `.zshrc`. This is already done with the nvm plugin for oh-my-zsh.

## Install fzf

```bash
brew install fzf
```

## Install git fuzzy

```bash
git clone https://github.com/bigH/git-fuzzy.git ${HOME}/workspace/git-fuzzy
```

## Install zsh-syntax-highlighting

```bash
brew install zsh-syntax-highlighting
```

## Install oh-my-posh

```bash
brew install jandedobbeleer/oh-my-posh/oh-my-posh
```

## Install fd

```bash
brew install fd
```

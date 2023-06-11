# ============================================================================
# Initial configuration

# Lines configured by zsh-newuser-install
HISTFILE=~/.cache/zsh/histfile
HISTSIZE=1000
SAVEHIST=1000
setopt autocd extendedglob nomatch notify
unsetopt beep
bindkey -v
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename "$HOME/.config/zsh/.zshrc"

autoload -Uz compinit
compinit "$HOME/.cache/zsh/zcompdump-$ZSH_VERSION"
# End of lines added by compinstall

# ============================================================================
# Common

# Alias'

source "$HOME/.config/shell/alias.sh";

# WSL

if [[ $WSL_DISTRO_NAME ]]; then
  # NOTE: this doesn't get loaded for some reason
  source "$HOME/.config/shell/profile.sh";

  export DISPLAY="$(ip route | awk '/^default/{print $3; exit}'):0.0";
  source "$HOME/.config/shell/wsl.sh";
fi;

# ============================================================================
# External

if [[ $- == *i* ]]; then
  fastfetch;

  eval "$(starship init zsh)";
  eval "$(zoxide init zsh --hook pwd)";
  source <(cod init $$ zsh);

  export TTY="$(tty)";
  export GPG_TTY="$(tty)";
fi;

# ============================================================================
# User

source $HOME/.config/zsh/user/*;

export LOADED_ZSHRC=1;

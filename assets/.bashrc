#!/usr/bin/env bash

source "$HOME/.config/shell/alias.sh"

if [[ $WSL_DISTRO_NAME ]]; then
  # NOTE: this doesn't get loaded for some reason
  source "$HOME/.config/shell/profile.sh";

  export DISPLAY="$(ip route | awk '/^default/{print $3; exit}'):0.0";
  source "$HOME/.config/shell/wsl.sh";
fi;

if [[ $- == *i* ]]; then
  fastfetch;

  eval "$(starship init bash)";
  eval "$(zoxide init bash --hook pwd)";
  source <(cod init $$ bash);

  export TTY="$(tty)";
  export GPG_TTY="$(tty)";
fi;

# ============================================================================
# Bootstrap

# TODO: automatic
# Run this after install:

# curl -L https://git.io/fisher | source
# fisher install jorgebucaran/fisher
# fisher install jorgebucaran/autopair.fish
# fisher install franciscolourenco/done
# fisher install edc/bass

# ============================================================================
# Common

# Function
function nvm
  bass source ~/.nvm/nvm.sh -- no-use ';' nvm $argv
end

# Alias'

source "$HOME/.config/shell/alias.sh"
alias please='eval sudo $history[1]'

# Env

source "$HOME/.config/shell/env.sh"

# WSL

if set -q WSL_DISTRO_NAME
  # NOTE: this doesn't get loaded for some reason
  source "$HOME/.config/shell/profile.sh"

  export DISPLAY=(ip route | awk '/^default/{print $3; exit}'):0.0
  source "$HOME/.config/shell/wsl.sh"
end

# ============================================================================
# External

# Remove intrinsic prompt
set fish_greeting

if status --is-interactive
  fastfetch

  starship init fish | source
  zoxide init fish --hook pwd | source
  cod init $fish_pid fish | source

  fish_vi_cursor
  fish_vi_key_bindings

  set -x TTY (tty)
  set -x GPG_TTY (tty)
end

# ============================================================================
# User

source $HOME/.config/fish/user/*;

export LOADED_FISH_CONFIG=1;

#!/usr/bin/env bash

# PATH
# Ruby
export PATH="$HOME/.local/share/gem/ruby/3.0.0/bin:$PATH"
# Rust
export PATH="$HOME/.cargo/bin:$PATH"
# Yarn
export PATH="$HOME/.yarn/bin:$PATH"
# Dotnet
export PATH="$HOME/.dotnet/tools:$PATH"
export PATH="$HOME/.dotnet:$PATH"
# Python
export PATH="$HOME/.local/bin:$PATH"
# Nvim Mason
export PATH="$HOME/.local/share/nvim/mason/bin:$PATH"

export PATH="$HOME/bin:$PATH"
export PATH="$HOME/scripts:$PATH"

export PATH="bin:$PATH"
export PATH="scripts:$PATH"

# Directories
export REPOS="/opt/src/$USER/repos"

# Apps
export EDITOR=vim
export VISUAL=nvim
export SUDO_EDITOR=vim
export BROWSER=brave
export TERMINAL=kitty

# QT theme
export QT_STYLE_OVERRIDE=kvantum

# Starship
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"

# Man
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# VEnv
export VIRTUAL_ENV_DISABLE_PROMPT="1"

export LOADED_PROFILESH=1
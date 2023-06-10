#!/uxr/bin/env bash
set -eo pipefail

DEVICE=$1
HOST=$2

nix-shell \
  --packages git nixFlakes parted \
  --command " \
    curl -s https://gitlab.com/Hrle/dotfiles-nixos/-/raw/main/scripts/install-wrapped.sh | \
    bash -s $DEVICE $HOST"

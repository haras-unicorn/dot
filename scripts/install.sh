#!/uxr/bin/env sh

DEVICE=$1
HOST=$2

nix-shell \
  -p git nixFlakes parted \
  -c " \
    curl -s https://gitlab.com/Hrle/dotfiles-nixos/-/raw/main/scripts/install-wrapped.sh | \
    bash -s $DEVICE $HOST"

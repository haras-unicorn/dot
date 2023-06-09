#!/uxr/bin/env sh

abs() { echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"; }
ROOT_DIR="$(dirname "$(abs "$0")")"

DEVICE=$1
if [ ! -b "$DEVICE" ]; then
  printf "Please enter a valid block device\n"
  exit 1
fi

HOST=$2
if [ ! -d "$ROOT_DIR/hosts/$HOST" ]; then
  printf "Please enter a valid host\n"
  exit 1
fi

nix-shell \
  -p git nixFlakes parted \
  -c " \
    curl -s https://gitlab.com/Hrle/dotfiles-nixos/-/raw/main/scripts/install-wrapped.sh | \
    bash -s $DEVICE $HOST"

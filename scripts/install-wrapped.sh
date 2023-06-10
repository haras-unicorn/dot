#!/uxr/bin/env sh

DEVICE=$1
if [ ! -b "$DEVICE" ]; then
  printf "Please enter a valid block device\n"
  exit 1
fi

git clone https://gitlab.com/hrle/dotfiles-nixos /opt/dotfiles
HOST=$2
if [ ! -d "/opt/dotfiles/hosts/$HOST" ]; then
  printf "Please enter a valid host\n"
  exit 1
fi

parted --script "$DEVICE" mktable gpt
parted --script "$DEVICE" mkpart nixboot fat32 0% 8GB
parted --script "$DEVICE" toggle 1 esp
parted --script "$DEVICE" mkpart nixroot ext4 8GB 100%
mkfs.fat -F 32 /dev/disk/by-label/nixboot
mkfs.ext4 -f /dev/disk/by-label/nixroot
parted --script "$DEVICE" print

mount /dev/disk/by-label/nixroot /mnt
mkdir /mnt/boot
mount /dev/disk/by-label/nixboot /mnt/boot
dd if=/dev/zero of=/mnt/swap bs=1M count=8k
chmod 600 /mnt/swap
mkswap /mnt/swap
swapon /mnt/swap
mount | grep "$DEVICE"

nixos-install --root /mnt --flake "/opt/dotfiles#$HOST"
mkdir /mnt/opt
mv /opt/dotfiles /mnt/opt/dotfiles

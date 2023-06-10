#!/uxr/bin/env bash
set -eo pipefail

DEVICE=$1
if [ ! -b "$DEVICE" ]; then
  printf "Please enter a valid block device\n"
  exit 1
fi

rm -rf /opt

mkdir /opt
git clone https://gitlab.com/hrle/dotfiles-nixos /opt/dotfiles
HOST=$2
if [ ! -d "/opt/dotfiles/hosts/$HOST" ]; then
  printf "Please enter a valid host\n"
  exit 1
fi

if grep -q "$DEVICE" /proc/mounts; then
  umount -R /mnt
fi

parted --script "$DEVICE" mktable gpt
parted --script "$DEVICE" mkpart primary fat32 0% 8GB
parted --script "$DEVICE" name 1 nixboot
parted --script "$DEVICE" toggle 1 esp
parted --script "$DEVICE" mkpart primary ext4 8GB 100%
parted --script "$DEVICE" name 2 nixroot
mkfs.fat -F 32 /dev/disk/by-partlabel/nixboot
mkfs.ext4 /dev/disk/by-partlabel/nixroot
parted --script "$DEVICE" print

mount /dev/disk/by-partlabel/nixroot /mnt
mkdir /mnt/boot
mount /dev/disk/by-partlabel/nixboot /mnt/boot
dd if=/dev/zero of=/mnt/swap bs=1M count=8k
chmod 600 /mnt/swap
mkswap /mnt/swap
swapon /mnt/swap
mount | grep "$DEVICE"

nixos-install --root /mnt --flake "/opt/dotfiles#$HOST"
mkdir /mnt/opt
mv /opt/dotfiles /mnt/opt/dotfiles

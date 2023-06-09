#!/uxr/bin/env sh

DEVICE=$1
HOST=$2

part() {
  if echo "$1" | grep -q "nvme"; then
    echo "$1p$2"
  else
    echo "$1$2"
  fi
}

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

git clone https://gitlab.com/hrle/dotfiles-nixos /opt/dotfiles
nixos-install --root /mnt --flake "/opt/dotfiles#$HOST"
mkdir /mnt/opt
mv /opt/dotfiles /mnt/opt/dotfiles

#!/usr/bin/env bash
set -eo pipefail

if [[ "$SELF" == "" ]]; then
  printf "SELF should not be null\n"
  exit 1
fi

if [[ "$SYSTEM" == "" ]]; then
  printf "SYSTEM should not be null\n"
  exit 1
fi

DEVICE=$1
if [[ ! -b "$DEVICE" ]]; then
  printf "Please enter a valid block device\n"
  exit 1
fi

TABLE=$2
if [[ "$TABLE" != "gpt" && "$TABLE" != "msdos" ]]; then
  printf "Please enter a partition table format\n"
  exit 1
fi

HOST=$3
if [[ "$HOST" == "" ]]; then
  printf "Please enter a valid host\n"
  exit 1
fi

if [[ "$SECRETS" == "" ]]; then
  SECRETS=$4
fi

if [[ $DEVICE == /dev/nvme* ]]; then
  BOOT="${DEVICE}p1"
  ROOT="${DEVICE}p2"
else
  BOOT="${DEVICE}1"
  ROOT="${DEVICE}2"
fi

parted --script "$DEVICE" mklabel "$TABLE"
parted --script "$DEVICE" mkpart primary fat32 0% 1GB
parted --script "$DEVICE" toggle 1 esp
parted --script "$DEVICE" mkpart primary ext4 1GB 100%
mkfs.fat -F 32 "$BOOT"
mkfs.ext4 "$ROOT"

fatlabel "$BOOT" NIXBOOT
e2label "$ROOT" NIXROOT

if [ ! -d "/mnt" ]; then
  mkdir /mnt
fi
set +e
until mount /dev/disk/by-label/NIXROOT /mnt; do
  printf "Waiting for NIXROOT to come up...\n"
  sleep 1s
done
set -e
mkdir /mnt/boot
set +e
until mount /dev/disk/by-label/NIXBOOT /mnt/boot; do
  printf "Waiting for NIXBOOT to come up...\n"
  sleep 1s
done
set -e

mkdir /mnt/var
fallocate -l 4G /mnt/var/swap
chmod 600 /mnt/var/swap
mkswap /mnt/var/swap
swapon /mnt/var/swap

mkdir -p /mnt/etc/ssh
chown root:root /mnt/etc
chmod 755 /mnt/etc
chown root:root /mnt/etc/ssh
chmod 755 /mnt/etc/ssh

# NOTE: https://github.com/Mic92/sops-nix/issues/24
ssh-keygen -a 100 -t rsa -N "" -f /mnt/etc/ssh/ssh_host_rsa_key &>/dev/null
ssh-keygen -a 100 -t ed25519 -N "" -f /mnt/etc/ssh/ssh_host_ed25519_key &>/dev/null

mkdir -p "/mnt/root/.sops"

chown root:root "/mnt/root"
chmod 700 "/mnt/root"

chown root:root "/mnt/root/.sops"
chmod 700 "/mnt/root/.sops"

if [[ -f "$SECRETS" ]]; then
  cp "$SECRETS" "/mnt/root/.sops/secrets.age"
else
  touch "/mnt/root/.sops/secrets.age"
fi
chown root:root "/mnt/root/.sops/secrets.age"
chmod 600 "/mnt/root/.sops/secrets.age"

nixos-install --flake "$SELF#$HOST-$SYSTEM"

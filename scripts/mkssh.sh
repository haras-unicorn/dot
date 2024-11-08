#!/usr/bin/env bash
set -eo pipefail

SECRETS="$1"
if [[ ! -d "$SECRETS" ]]; then
  printf "Please enter a secrets directory\n"
  exit 1
fi

REMOTE="$2"
if [[ "$REMOTE" == "" ]]; then
  printf "Please enter a valid remote\n"
  exit 1
fi

USER="$3"
if [[ "$USER" == "" ]]; then
  printf "Please enter a valid user\n"
  exit 1
fi

HOST="$4"
if [[ "$HOST" == "" ]]; then
  printf "Please enter a valid host\n"
  exit 1
fi

mkdir -p "$SECRETS"
ID="$(openssl rand -hex 16)"
NOW="$(date --utc -Iseconds)"
ID_SECRETS="$SECRETS/ssh/$NOW-$ID"
if [[ -d "$ID_SECRETS" ]]; then
  printf "Ssh secrets already exist! Please try again..."
  exit 1
fi
mkdir -p "$ID_SECRETS"

REMOTE_SECRETS="$SECRETS/$REMOTE"
mkdir -p "$REMOTE_SECRETS"
printf "%s" "$ID" >"$REMOTE_SECRETS/ssh.id"

mkremote() {
  local name

  name="$1"

  if [[ -f "$REMOTE_SECRETS/$name" ]]; then
    return
  fi

  cp "$ID_SECRETS/$name" "$REMOTE_SECRETS/$name"
}

mkssh() {
  local name
  local comment

  if [[ "$2" == "" ]]; then
    name="$1"

    ssh-keygen -q -a 100 -t ed25519 -N "" \
      -f "$ID_SECRETS/$name.ssh"
  else
    name="$1"
    comment="$2"

    ssh-keygen -q -a 100 -t ed25519 -N "" \
      -C "$comment" \
      -f "$ID_SECRETS/$name.ssh"
  fi

  chmod 400 "$ID_SECRETS/$name.ssh"
}

mkssh "$USER-$HOST" "$HOST"
mkremote "$USER-$HOST.ssh"
mkremote "$USER-$HOST.ssh.pub"

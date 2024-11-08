#!/usr/bin/env bash
set -eo pipefail

SECRETS="$1"
if [[ ! -d "$SECRETS" ]]; then
  printf "Please enter a secrets directory\n"
  exit 1
fi

USER="$2"
if [[ "$USER" == "" ]]; then
  printf "Please enter a valid user\n"
  exit 1
fi

HOST="$3"
if [[ "$HOST" == "" ]]; then
  printf "Please enter a valid host\n"
  exit 1
fi

mkdir -p "$SECRETS"
ID="$(openssl rand -hex 16)"
NOW="$(date --utc -Iseconds)"
ID_SECRETS="$SECRETS/pass/$NOW-$ID"
if [[ -d "$ID_SECRETS" ]]; then
  printf "Pass secrets already exist! Please try again..."
  exit 1
fi
mkdir -p "$ID_SECRETS"

HOST_SECRETS="$SECRETS/$HOST"
mkdir -p "$HOST_SECRETS"
printf "%s" "$ID" >"$HOST_SECRETS/pass.id"

mkhost() {
  local name

  name="$1"

  if [[ -f "$HOST_SECRETS/$name" ]]; then
    return
  fi

  cp "$ID_SECRETS/$name" "$HOST_SECRETS/$name"
}

mkpass() {
  local name

  name="$1"

  # NOTE: if you do it raw it adds a newline
  passwd="$(openssl rand -base64 32)"
  printf "%s" "$passwd" >"$ID_SECRETS/$name.pass"
  chmod 400 "$ID_SECRETS/$name.pass"
  printf "%s" "$(echo "$passwd" | mkpasswd --stdin)" >"$ID_SECRETS/$name.pass.pub"
}

mkpass "$USER"
mkhost "$USER.pass.pub"

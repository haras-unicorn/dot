#!/usr/bin/env bash
set -eo pipefail

SECRETS="$1"
if [[ ! -d "$SECRETS" ]]; then
  printf "Please enter a secrets directory\n"
  exit 1
fi

HOST="$2"
if [[ "$HOST" == "" ]]; then
  printf "Please enter a valid host\n"
  exit 1
fi

if [[ "$3" == "" ]]; then
  NAME="secrets"
else
  NAME="$2"
  HOST="$3"
fi

mkdir -p "$SECRETS"
ID="$(openssl rand -hex 16)"
NOW="$(date --utc -Iseconds)"
ID_SECRETS="$SECRETS/age/$NOW-$ID"
if [[ -d "$ID_SECRETS" ]]; then
  printf "Age secrets already exist! Please try again..."
  exit 1
fi
mkdir -p "$ID_SECRETS"

HOST_SECRETS="$SECRETS/$HOST"
mkdir -p "$HOST_SECRETS"
printf "%s" "$ID" >"$HOST_SECRETS/age.id"

mkserver() {
  local name

  name="$1"

  if [[ -f "$HOST_SECRETS/$name" ]]; then
    return
  fi

  cp "$ID_SECRETS/$name" "$HOST_SECRETS/$name"
}

mkage() {
  local name

  name="$1"

  age-keygen -o "$ID_SECRETS/$name.age" 2>&1 |
    awk '{ print $3 }' >"$ID_SECRETS/$name.age.pub"
  chmod 400 "$ID_SECRETS/$name.age"
}

mkage "$NAME"
mkserver "$NAME.age"
mkserver "$NAME.age.pub"

#!/usr/bin/env bash
set -eo pipefail

# TODO: now that root is added everything else can just be renewed

SECRETS="$1"
if [[ ! -d "$SECRETS" ]]; then
  printf "Please enter a secrets directory\n"
  exit 1
fi

SERVER="$2"
if [[ "$SERVER" == "" ]]; then
  printf "Please enter a valid server\n"
  exit 1
fi

CLIENT="$3"
if [[ "$CLIENT" == "" ]]; then
  printf "Please enter a valid client\n"
  exit 1
fi

mkdir -p "$SECRETS"
ID="$(openssl rand -hex 16)"
NOW="$(date --utc -Iseconds)"
ID_SECRETS="$SECRETS/vpn/$NOW-$ID"
if [[ -d "$ID_SECRETS" ]]; then
  printf "Device secrets already exist! Please try again..."
  exit 1
fi
mkdir -p "$ID_SECRETS"

ROOT_SECRETS="$SECRETS/root"
mkdir -p "$ROOT_SECRETS"
printf "%s" "$ID" >"$ROOT_SECRETS/vpn.id"

SERVER_SECRETS="$SECRETS/$SERVER"
mkdir -p "$SERVER_SECRETS"
printf "%s" "$ID" >"$SERVER_SECRETS/vpn.id"

CLIENT_SECRETS="$SECRETS/$CLIENT"
mkdir -p "$CLIENT_SECRETS"
printf "%s" "$ID" >"$CLIENT_SECRETS/vpn.id"

idroot() {
  local name

  name="$1"

  if [[ -f "$ROOT_SECRETS/$name" ]]; then
    return
  fi

  cp "$ID_SECRETS/$name" "$ROOT_SECRETS/$name"
}

idserver() {
  local name

  name="$1"

  if [[ -f "$SERVER_SECRETS/$name" ]]; then
    return
  fi

  cp "$ID_SECRETS/$name" "$SERVER_SECRETS/$name"
}

idclient() {
  local name

  name="$1"

  if [[ -f "$CLIENT_SECRETS/$name" ]]; then
    return
  fi

  cp "$ID_SECRETS/$name" "$CLIENT_SECRETS/$name"
}

rootserver() {
  local name

  name="$1"

  cp -f "$ROOT_SECRETS/$name" "$SERVER_SECRETS/$name"
}

rootclient() {
  local name

  name="$1"

  cp -f "$ROOT_SECRETS/$name" "$CLIENT_SECRETS/$name"
}

mkssl() {
  local name
  local ca
  local subj

  if [[ "$3" == "" ]]; then
    name="$1"
    subj="$2"

    openssl genpkey -algorithm ED25519 \
      -out "$ID_SECRETS/$name.ssl.key" >/dev/null 2>&1
    openssl req -x509 \
      -key "$ID_SECRETS/$name.ssl.key" \
      -out "$ID_SECRETS/$name.ssl.crt" \
      -subj "/CN=$subj" \
      -days 3650 >/dev/null 2>&1
  else
    name="$1"
    ca="$2"
    subj="$3"

    openssl genpkey -algorithm ED25519 \
      -out "$ID_SECRETS/$name.ssl.key" >/dev/null 2>&1
    openssl req -new \
      -key "$ID_SECRETS/$name.ssl.key" \
      -out "$ID_SECRETS/$name.ssl.csr" \
      -subj "/CN=$subj" >/dev/null 2>&1
    openssl x509 -req \
      -in "$ID_SECRETS/$name.ssl.csr" \
      -CA "$ca.ssl.crt" \
      -CAkey "$ca.ssl.key" \
      -CAcreateserial \
      -out "$ID_SECRETS/$name.ssl.crt" \
      -days 3650 >/dev/null 2>&1
  fi

  chmod 400 "$ID_SECRETS/$name.ssl.key"
}

mkparam() {
  local name

  name="$1"

  printf "Generating Diffie-Hellman parameters takes a while, so hang on for a bit.\n"

  openssl dhparam -out "$ID_SECRETS/$name.dhparam.pem" 4096 >/dev/null 2>&1
}

mktakey() {
  local name

  name="$1"

  openvpn --genkey --secret "$ID_SECRETS/$name.ta.key" >/dev/null 2>&1
}

mkssl "root-ca" "root"
idroot "root-ca.ssl.key"
idroot "root-ca.ssl.crt"
rootserver "root-ca.ssl.key"
rootserver "root-ca.ssl.crt"
rootclient "root-ca.ssl.crt"

mkssl "server" "$ROOT_SECRETS/root-ca" "$SERVER"
idserver "server.ssl.key"
idserver "server.ssl.crt"

mkparam "server"
idserver "server.dhparam.pem"

mktakey "server"
idroot "server.ta.key"
rootserver "server.ta.key"
rootclient "server.ta.key"

mkssl "client" "$ROOT_SECRETS/root-ca" "$CLIENT"
idclient "client.ssl.key"
idclient "client.ssl.csr"
idclient "client.ssl.crt"

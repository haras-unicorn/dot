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

HOST="$1"
if [[ ! -d "$SELF/src/host/$HOST" || ! -f "$SELF/src/host/$HOST/default.nix" ]]; then
  printf "Please enter a valid host.\n"
  exit 1
fi

nix build \
  --extra-experimental-features nix-command \
  --extra-experimental-features flakes \
  "$SELF#nixosConfigurations.$HOST-$SYSTEM.config.system.build.sdImage"

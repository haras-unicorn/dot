#!/usr/bin/env bash
set -eo pipefail

SECRETS_DIR="$1"
if [[ ! -d "$SECRETS_DIR" ]]; then
  printf "Please enter a valid secrets directory\n"
  exit 1
fi
SECRETS_FILE="$SECRETS_DIR/secrets.sops.yaml"
SECRETS_ENC_FILE="$SECRETS_DIR/secrets.sops.enc.yaml"

AGE_KEY_FILES=("${@:2}")
if [[ ${#AGE_KEY_FILES[@]} -lt 1 ]]; then
  printf "Please enter at least one age key file\n"
  exit 1
fi

indent() {
  local text
  local amount

  text="$1"
  amount="$2"

  printf "%b" "$text" |
    sed -z "s/\\n/,/g;s/,/\\n$(printf "%${amount}s" "")/g"
}

AGE=""
for age_key_file in "${AGE_KEY_FILES[@]}"; do
  age_key=$(cat "$age_key_file")
  if [[ "$AGE" == "" ]]; then
    AGE="$age_key"
  else
    AGE="$AGE,$age_key"
  fi
done

SECRETS=""
for secret_file in "$SECRETS_DIR"/*; do
  if [[ -f "$secret_file" && ! "$secret_file" =~ .*(\.sops(\.enc)?\.yaml|.age|.id) ]]; then
    secret_name=${secret_file##*/}
    if [[ "$SECRETS" == "" ]]; then
      SECRETS+="$(
        cat <<EOF
$secret_name: |
  $(indent "$(cat "$secret_file")" 2)
EOF
      )"
    else
      SECRETS+="$(
        cat <<EOF

$secret_name: |
  $(indent "$(cat "$secret_file")" 2)
EOF
      )"
    fi
  fi
done

echo "$SECRETS" >"$SECRETS_FILE"
sops --encrypt --age "$AGE" "$SECRETS_FILE" >"$SECRETS_ENC_FILE"

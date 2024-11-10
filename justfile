set windows-shell := ["nu.exe", "-c"]
set shell := ["nu", "-c"]

root := justfile_directory()
secrets-script := absolute_path('scripts/secrets.nu')
secrets-dir := absolute_path('secrets')

default:
  @just --choose

format:
  cd '{{ root }}'; just --unstable --fmt
  prettier --write "{{root}}"
  nixpkgs-fmt "{{root}}"

lint:
  prettier --check "{{root}}"

secrets *args:
  mkdir {{ secrets-dir }}; cd {{ secrets-dir }}; {{ secrets-script }} {{ args }}

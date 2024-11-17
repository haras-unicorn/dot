set windows-shell := ["nu.exe", "-c"]
set shell := ["nu", "-c"]

root := justfile_directory()
secrets-script := absolute_path('scripts/secrets.nu')
secrets-dir := absolute_path('secrets/current')
hosts := absolute_path('src/host')

default:
    @just --choose

format:
    cd '{{ root }}'; just --unstable --fmt
    prettier --write '{{ root }}'
    nixpkgs-fmt '{{ root }}'

lint:
    prettier --check '{{ root }}'
    nix flake check

secrets *args:
    mkdir '{{ secrets-dir }}'
    cd '{{ secrets-dir }}'; {{ secrets-script }} {{ args }}

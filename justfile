set windows-shell := ["nu.exe", "-c"]
set shell := ["nu", "-c"]

secrets-script := absolute_path('scripts/secrets.nu')
secrets-dir := absolute_path('secrets/current')

default:
    @just --choose

format:
    nix fmt

check:
    nix flake check

secrets *args:
    mkdir '{{ secrets-dir }}'
    cd '{{ secrets-dir }}'; {{ secrets-script }} {{ args }}

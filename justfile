set windows-shell := ["nu.exe", "-c"]
set shell := ["nu", "-c"]

root := absolute_path('')

default:
    @just --choose

format:
    nix fmt

check:
    nix flake check

hosts *args:
    {{ root }}/scripts/hosts.nu {{ args }}

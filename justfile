set windows-shell := ["nu.exe", "-c"]
set shell := ["nu", "-c"]

root := justfile_directory()

format:
  prettier --write "{{root}}"
  nixpkgs-fmt "{{root}}"

lint:
  prettier --check "{{root}}"

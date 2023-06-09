# NixOS dotfiles

Configurations for my NixOS systems.

## Install

```sh
curl -s 'https://gitlab.com/Hrle/dotfiles-nixos/-/raw/{revision(main)}/scripts/install.sh' | \
  bash -s '{device(/dev/sda)}' '{host(desktop)}'
```

## Updating

```sh
nix-rebuild switch --flake '/opt/dotfiles#{host(desktop)}'
```

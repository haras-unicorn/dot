# NixOS dotfiles

Configurations for my NixOS systems.

## Install

```bash
curl -s 'https://gitlab.com/Hrle/dotfiles-nixos/-/raw/{revision(main)}/scripts/install.sh' | \
  sudo bash -s '{device(/dev/sda)}' '{host(virtualbox)}'
```

## Updating

```sh
nixos-rebuild {switch/boot} --flake '/opt/dotfiles#{host(virtualbox)}'
```

# AGENTS.md

This is a project that contains NixOS configurations for my machines.

## Project overview

The project uses [flake-parts] and [import-tree] to import all files under
`./src` as flake modules and make the flake.

Most flake modules under `./src` define either a `nixosModule` or a `homeModule`
or both. Some of the modules define glue code for various tools that I started
relying on over the years which include but are not limited to:

- [./src/lib/host.nix](./src/lib/host.nix)
- [./src/hardware/module.nix](./src/hardware/module.nix)
- [./src/hardware/nvidia.nix](./src/hardware/nvidia.nix)
- [./src/critical/vault.nix](./src/critical/vault.nix)

The project uses the [just] command runner for [running commands](./justfile)
and [nushell] for running more [complicated commands](./scripts/hosts.nu) on my
host machines. Both expect to be ran from inside the
[default development shell](./src/dev.nix).

[Nix]: https://nixos.org/
[NixOS]: https://nixos.org/
[flake-parts]: https://flake.parts/
[import-tree]: https://import-tree.oeiuwq.com/
[just]: https://just.systems/
[nushell]: https://www.nushell.sh/

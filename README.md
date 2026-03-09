# Dot

My NixOS configurations.

## Installation

Use [Nix] to switch your [NixOS] system to one of the configurations.

```sh
sudo nixos-rebuild switch --flake ".#<name>"
```

Use [Nix] to get a list of available [NixOS] configurations in the
`nixosConfigurations` section.

```sh
nix flake show
```

## Usage

As per the license, you may use code from this repository to make your own
configurations. The project relies on [flake-parts] and [import-tree] flakes to
create the flake from flake modules inside `./src`.

Most flake modules under `./src` define either a `nixosModule` or a `homeModule`
or both. Some of the modules define glue code for various tools that I started
relying on over the years which include but are not limited to:

- [./src/lib/host.nix](./src/lib/host.nix)
- [./src/capabilities/hardware.nix](./src/capabilities/hardware.nix)
- [./src/lib/test.nix](./src/lib/test.nix)

The project uses the [just] command runner for [running commands](./justfile)
and [nushell] for running more [complicated commands](./scripts/hosts.nu) on my
host machines. Both expect to be ran from inside the
[default development shell](./src/dev.nix).

## Contributing

Pull requests will not be accepted as these are my personal configurations.

## License

This project is licensed under the [MIT](./LICENSE.md) license.

[Nix]: https://nixos.org/
[NixOS]: https://nixos.org/
[flake-parts]: https://flake.parts/
[import-tree]: https://import-tree.oeiuwq.com/
[just]: https://just.systems/
[nushell]: https://www.nushell.sh/

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
- [./src/lib/test.nix](./src/lib/test.nix)

The project uses the [just] command runner for [running commands](./justfile)
and [nushell] for running more [complicated commands](./scripts/hosts.nu) on my
host machines. Both expect to be ran from inside the
[default development shell](./src/dev.nix).

## Testing

The project uses [nix-unit] for unit testing and
[`config.flake.lib.test.mkTest`] (a wrapper over `pkgs.testers.runNixOSTest`)
for NixOS VM testing. An example of how to write tests can be found in the
[library test file](./src/lib/test.nix).

When adding test code (e2e or unit tests), commit the changes after tests pass
successfully using [Conventional Commits] format (e.g., `test(module-name): add
e2e test for critical-openssh`).

## Gotchas

- unit test attrset leaves must have `expr` and `expected` args and their key
  must start with `test`
- please read all the files mentioned in this file inside this repository -
  especially the [justfile](./justfile).
- always first check the [justfile](./justfile) for available recipes before
  running any commands
- when writing e2e tests for modules that use `dot.*` options (e.g.,
  `dot.hardware.network.enable`), you must mock these options in the test's
  `nodes.<name>.options` attribute since they are defined in other modules which
  are not imported by default

[Nix]: https://nixos.org/
[NixOS]: https://nixos.org/
[flake-parts]: https://flake.parts/
[import-tree]: https://import-tree.oeiuwq.com/
[just]: https://just.systems/
[nushell]: https://www.nushell.sh/
[nix-unit]: https://github.com/nix-community/nix-unit/
[`config.flake.lib.test.mkTest`]: ./src/lib/test.nix
[Conventional Commits]: https://www.conventionalcommits.org/

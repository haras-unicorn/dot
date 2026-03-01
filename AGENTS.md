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
successfully using [Conventional Commits] format (e.g.,
`test(module-name): add e2e test for critical-openssh`).

## E2E Testing

Use `machine` for the test node name and ensure test commands match this name
(e.g., `machine.succeed()`).

When writing e2e tests for modules that use `dot.*` options (e.g.,
`dot.hardware.network.enable`), you must mock these options in the test's
`nodes.<name>.options` attribute since they are defined in other modules which
are not imported by default.

For modules using external dependencies like [sops-nix] and [rumor], import
their modules (e.g., `config.flake.nixosModules.rumor`) and mock required
options. You generally don't need to set up actual secrets - the module will
configure secret paths automatically based on `dot.host.user`.

When verifying that a specific package or kernel version is being used, prefer
"canonical" paths over direct nix store searches. For example, use
`readlink /run/booted-system/kernel` to check the kernel instead of
`find /nix/store -name '*kernel*'`. Nix store paths are implementation details
and may change; canonical paths like symlinks in `/run/booted-system/`, `/etc`,
or service status checks are more stable and maintainable.

## Gotchas

- unit test attrset leaves must have `expr` and `expected` args and their key
  must start with `test`
- please read all the files mentioned in this file inside this repository -
  especially the [justfile](./justfile).
- always first check the [justfile](./justfile) for available recipes before
  running any commands
- **Important**: Nix flakes only see git-tracked files. When adding new test
  files or modules, you must `git add` them before Nix can evaluate them. This
  is a common source of "attribute not found" errors when adding new tests.
- **Important**: Nix flakes only see git-tracked files. When adding new test
  files or modules, you must `git add` them before Nix can evaluate them. This
  is a common source of "attribute not found" errors when adding new tests.

## Security Warning

**IMPORTANT: Never execute or run anything related to [rumor] or secret
management tools.** This includes:

- Do not run `rumor` commands or import and execute its generators/importers
- Do not generate, rotate, or export real certificates or keys
- Do not access or modify production Vault, SOPS, or Age keys
- Only mock the `rumor.*` option schema for NixOS module compatibility when
  testing
- Mock `sops.secrets` with dummy paths and test data only when testing

These tools manage sensitive production credentials. Tests should only verify
module configuration and service behavior using mock/test data, never interact
with real secret infrastructure.

[flake-parts]: https://flake.parts/
[import-tree]: https://import-tree.oeiuwq.com/
[just]: https://just.systems/
[nushell]: https://www.nushell.sh/
[nix-unit]: https://github.com/nix-community/nix-unit/
[`config.flake.lib.test.mkTest`]: ./src/lib/test.nix
[Conventional Commits]: https://www.conventionalcommits.org/
[sops-nix]: https://github.com/Mic92/sops-nix
[rumor]: https://github.com/haras-unicorn/rumor

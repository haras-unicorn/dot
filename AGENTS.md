# AGENTS.md

NixOS configuration flake built with `flake-parts` and `import-tree` over the
`src` directory.

## Structure

- `src/` — the flake module tree; `flake.nix` imports it via `import-tree`
  - `systems.nix` — supported systems (`x86_64-linux`, `aarch64-linux`)
  - `machines.nix` — machine wiring: every `machines.machines.<name>` entry
    becomes a `nixosConfiguration` with `networking.hostName` set from the
    machine name; the nixos-facter report at `assets/hardware/<name>.json` is
    used when present
  - `machines/` — one file per machine
  - `modules/` — shared NixOS and home-manager modules, grouped by category:
    - `meta/` — defines the `dot.*` option interface the rest consumes
    - `critical/`, `desktop/`, `hardware/`, `nix/`, `programs/`, `sandbox/`,
      `services/`, `ai/` — module implementations
    - `deprecated/` — retired modules kept for reference
  - `lib/` — `self.lib` helpers shared across the flake
  - `dev/` — the development shell and tooling (see below)
- `assets/` — static files referenced by modules (hardware reports, wallpapers,
  presets)
- `.github/workflows/check.yaml` — CI, runs `nix flake check` on pull requests

Modules register themselves under `machines.nixosModules.<name>` or
`machines.homeModules.<name>`: `meta/` files declare the `dot.*` options,
everything else consumes them and defines the concrete NixOS or home-manager
configuration.

## Development

Enter the development shell with `nix develop` (or `direnv` via `.envrc`). It
provides the `dev` command (a Nushell CLI; `dev -h` lists everything):

- `dev format` — format the repository (`prettier` + `nixfmt`)
- `dev lint` — lint the repository (`prettier`, `nixfmt`, `markdownlint`,
  `cspell`, `markdown-link-check`); CI runs this via `nix flake check`
- `dev rebuild report|switch|boot` — `nixos-rebuild` for the current host
  (hostname read from `/etc/hostname`)
- `dev detect` — run `nixos-facter` and save the hardware report to
  `assets/hardware/<hostname>.json`

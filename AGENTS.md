# AGENTS.md

NixOS configuration flake built with `haraspkgs.lib.makeFlake` over the `src`
directory. Haraspkgs provides the `flake-parts` and `import-tree` plumbing.

## Structure

- `src/` — the flake module tree; `flake.nix` passes it to `makeFlake`
  - `systems.nix` — supported systems (`x86_64-linux`, `aarch64-linux`)
  - `namespace.nix` — sets the haraspkgs overlay namespace to `harasPackages`
  - `machines/` — one file per machine; each registers a
    `self.nixosConfigurations.<name>` with `flake = true`
  - `modules/` — shared NixOS and home-manager modules, grouped by category:
    - `meta/` — defines the `dot.*` option interface the rest consumes
    - `critical/`, `desktop/`, `hardware/`, `nix/`, `programs/`, `sandbox/`,
      `services/` — module implementations
    - `hardware/facter.nix` — shared facter report and `nixpkgs.system` wiring
    - `ai/` — Claude Code and OpenCode home modules, `mcps` (the shared
      `programs.mcp` registry both consume, with the sandboxed git, filesystem,
      nix, web, and memory MCP servers and the `mcp-memory` user service), and
      supporting AI services (`corm`, `librechat`, `piper`, `tesseract`,
      `whisper-cpp`)
  - `deprecated/` — retired modules kept for reference; they register under
    `self.lib.deprecated.*` and are inert unless imported explicitly
  - `lib/` — `self.lib` helpers shared across the flake; `self.lib.ai` loads the
    global agent instructions and skills from `assets/ai/` for the Claude Code
    and OpenCode modules
  - `overlays/` — standalone packages, general wrappers, and overlays; each
    registers `self.overlays.overlays.<name>.value = final: prev: { … }` and is
    available as `pkgs.harasPackages.<name>` (namespace from `namespace.nix`)
  - `dev/` — `shell.nix` configures the haraspkgs dev shell and generates
    repository files (see below)
- `assets/` — static files referenced by modules (hardware reports, wallpapers,
  presets, and the global `AGENTS.md` and skill files under `ai/`; every
  markdown file in `ai/skills/` is a skill named after the file)
- `.github/workflows/` — generated mirror for `check`; CI runs `nix flake check`
  on pull requests

Modules register themselves under `self.nixosModules.<name>.value` or
`self.homeModules.<name>.value`: `meta/` files declare the `dot.*` options,
everything else consumes them and defines the concrete NixOS or home-manager
configuration. Every `self.nixosModules.*` entry is included automatically, and
every `self.homeModules.*` entry becomes a home-manager shared module.
`deprecated/` modules register under `self.lib.deprecated.*` and stay inert
until imported explicitly.

### Packages and overlays

Overlays register `self.overlays.overlays.<name>.value`. With the default
`self = true` the result is available as `pkgs.harasPackages.<name>` in NixOS,
home-manager, and the dev shell, and its derivations appear in
`packages.<system>.<name>`. Set `flake = true` when the overlay itself should
also be exported as `flake.overlays.<name>`.

An overlay can also expose a builder function instead of a package, like
`makeNetworkIsolate` and `makeServerClientApp`. Modules call it as
`pkgs.harasPackages.<name>`, with no `selfLib` and no `pkgs` argument.

Standalone packages, general-purpose tools, and reusable wrappers live in
`src/overlays/` (for example `anythingllm`, `zeroclaw`, `utils`, `clipboard`,
and `mcp-memory-service`, which packages the memory MCP server with its offline
embedding and rerank models). Overlay values are evaluated outside the NixOS and
home-manager module system, so they cannot read `config`; they take what they
need as arguments. A wrapper that depends on one module's `config`, a host
device, a service unit, or a session stays a local binding in that module, like
the MCP server sandboxes in `modules/ai/mcps.nix`.

## Style deviations

This repository is only my own NixOS configurations. It is not a product, a
library or a monorepo, and nobody else consumes it. So it strays from the
defaults in these ways, on purpose:

- **No mdbook in `docs/`.** There is no one to write documentation for, and the
  `dot.*` options are used only by the machines in this repository.
- **All Nix lives in `src/`, not `src/nix/`.** Nix is the whole repository, so a
  `nix` subfolder would add a level and separate nothing. `flake.nix` passes
  `./src` to `makeFlake`.
- **No tests.** Anything that needs tests belongs in another repository, as a
  package or a module with its own tests. What is left here is thin glue: small
  overlays and modules that wire other things together. These are hard to test
  on their own, so they are tested by hand after switching to the new
  configuration. `mcp-memory-service` is the one exception, and it carries its
  own `passthru.tests`.
- **Magic values are allowed, but never repeated.** The whole repository is the
  configuration, so a literal like a port or a timeout is already the value
  wanted, and an option with one reader is only indirection. A value used once
  stays a literal. A value used in several places in one file is bound once in
  that file's `let`. A value used in several files is defined once in `src/lib/`
  and read through `selfLib`.

## Development

Enter the development shell with `nix develop` (or `direnv` via `.envrc`). It
provides the `dev` command (a bash CLI from haraspkgs; `dev -h` lists
everything):

- `dev format` — format the repository with treefmt (`nixfmt` + `prettier`)
- `dev check` — run cspell, markdownlint, markdown-link-check, and nil
  diagnostics in the checkout
- `nix flake check` — build the same checks as `dev check` plus the format,
  generated-workflow, and `nix-unit` checks; CI runs this on pull requests.
  Markdown link checks are skipped inside the Nix build sandbox.
- `dev rebuild report|switch|boot` — `nixos-rebuild` for the current host
  (hostname read from `/etc/hostname`)
- `dev detect` — run `nixos-facter` and save the hardware report to
  `assets/hardware/<hostname>.json`

`.gitignore`, `.gitattributes`, `.github/workflows/*.yaml`, and `LICENSE.md` are
generated by the dev shell. Commit their mirrors; the dev module is the source
of truth. `.envrc` is committed and is not regenerated on shell entry. The
CSpell, EditorConfig, and Prettier-ignore configs are generated in the Nix store
and bound into the sandboxed tools, so they are not committed. The `hx` wrapper
receives a generated `.helix/languages.toml`.

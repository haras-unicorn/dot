# AGENTS.md

This file provides context for AI agents working with this Nix flake repository.

## Project Overview

This is a NixOS system configuration flake using **flake-parts** for managing
multiple hosts (desktops, laptops, Raspberry Pis) with shared modules and
hardware detection.

- **Primary user**: haras
- **Hosts**: 7 systems (hearth, officer, workbug, koncar9000, bean, brock,
  puffy)
- **Architecture**: x86_64-linux and aarch64-linux
- **Network**: All hosts on 10.69.42.0/24 subnet with Nebula VPN

## Architecture

### Flake Structure

```
flake.nix              # Entry point using flake-parts
src/
├── lib/               # Library functions (flake.lib)
├── programs/          # User applications (flake.homeModules.programs-*)
├── services/          # System & user services (flake.nixosModules.services-* / flake.homeModules.services-*)
├── critical/          # Infrastructure services (flake.nixosModules.critical-*)
├── hardware/          # Hardware detection (flake.nixosModules.hardware-*)
├── hosts/             # Host-specific configurations (flake.nixosConfigurations.<name>)
├── clusters/          # Application clusters (flake.nixosModules.clusters-*)
└── *.nix              # Root modules (defaults, nix, nixpkgs, host, etc.)
```

### Module System

This repo uses **flake-parts** instead of the previous perch framework.

**Key differences from standard NixOS:**

- All modules under `src/` are automatically discovered and imported
- Modules export via `flake.*` options instead of returning attrsets
- Library functions go to `flake.lib.*`
- NixOS modules go to `flake.nixosModules.*`
- Home-manager modules go to `flake.homeModules.*`
- System configurations go to `flake.nixosConfigurations.*`

## Module Conventions

### Naming Pattern

```nix
# File: src/programs/bat.nix
{ ... }: {
  flake.homeModules.programs-bat = { pkgs, ... }: {
    programs.bat.enable = true;
  };
}

# File: src/services/docker.nix
{ ... }: {
  flake.nixosModules.services-docker = { pkgs, ... }: {
    virtualisation.docker.enable = true;
  };
}

# File: src/critical/vault.nix
{ ... }: {
  flake.nixosModules.critical-vault = { config, lib, pkgs, ... }: {
    # Complex infrastructure module
  };
}
```

### Directory → Namespace Mapping

| Directory            | NixOS Module                    | Home Module                                    |
| -------------------- | ------------------------------- | ---------------------------------------------- |
| `src/programs/*.nix` | -                               | `flake.homeModules.programs-*`                 |
| `src/services/*.nix` | `flake.nixosModules.services-*` | `flake.homeModules.services-*`                 |
| `src/critical/*.nix` | `flake.nixosModules.critical-*` | `flake.homeModules.critical-*` (if applicable) |
| `src/hardware/*.nix` | `flake.nixosModules.hardware-*` | `flake.homeModules.hardware-*` (if applicable) |
| `src/hosts/<name>/`  | `flake.nixosModules.hosts-*`    | `flake.homeModules.hosts-*`                    |
| `src/clusters/*/`    | `flake.nixosModules.clusters-*` | `flake.homeModules.clusters-*`                 |
| `src/lib/*.nix`      | `flake.lib.*`                   | `flake.lib.*`                                  |
| `src/*.nix`          | `flake.nixosModules.*`          | `flake.homeModules.*`                          |

## Hardware Detection System

The repo has a sophisticated hardware detection system in
`src/hardware/module.nix` using nixos-facter:

```nix
config.dot.hardware = {
  # Detection based on facter report
  monitor.enable      # Has display output
  keyboard.enable     # Has keyboard
  mouse.enable        # Has mouse
  sound.enable        # Has audio
  network.enable      # Has network interface
  bluetooth.enable    # Has Bluetooth
  gpu.enable          # Has any GPU
  nvidia.enable       # Has NVIDIA GPU (PCI ID matching)
  rpi."4".enable      # Is Raspberry Pi 4

  # Computed values
  threads             # CPU threads
  memory              # RAM in MB
  hasMinCpu / hasMinMem  # For VM eligibility

  # Graphics
  graphics.driver     # "nvidia", "amdgpu", "radeon", or null
  graphics.version    # "latest", "production", "legacy"
};
```

**Usage in modules:**

```nix
{ config, lib, ... }:
let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasNetwork = config.dot.hardware.network.enable;
in
{
  flake.nixosModules.my-module = lib.mkIf hasNetwork {
    # Network-dependent config
  };
}
```

## Host Configurations

All hosts are defined in `src/hosts/<hostname>/default.nix`:

### Export Pattern

```nix
{ inputs, ... }:
{
  # The actual NixOS system
  flake.nixosConfigurations.<hostname> = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux"; # or "aarch64-linux"
    modules = [
      # System modules
    ];
  };

  # Host-specific NixOS module
  flake.nixosModules.hosts-<hostname> = { ... }: { };

  # Host-specific Home Manager module
  flake.homeModules.hosts-<hostname> = { ... }: { };
}
```

### Host Inventory

| Host       | System        | Type    | IP         | Notes                                  |
| ---------- | ------------- | ------- | ---------- | -------------------------------------- |
| hearth     | x86_64-linux  | Desktop | 10.69.42.2 | No password                            |
| officer    | x86_64-linux  | Desktop | 10.69.42.4 | No password                            |
| workbug    | x86_64-linux  | Laptop  | 10.69.42.3 | Has battery                            |
| koncar9000 | x86_64-linux  | Desktop | 10.69.42.7 | Minimal                                |
| bean       | aarch64-linux | RPi4    | 10.69.42.6 | Server (lighthouse, cockroachdb, etc.) |
| brock      | aarch64-linux | RPi4    | 10.69.42.5 | Server                                 |
| puffy      | aarch64-linux | RPi4    | 10.69.42.1 | Server                                 |

## Important Modules

### src/host.nix (CRITICAL)

This is the central module that:

1. Defines `dot.host.*` options (name, ip, user, etc.)
2. Imports all other modules
3. Sets up hardware sharing between NixOS and home-manager
4. Configures home-manager with `sharedModules` for hardware passing

**Key insight**: All hosts import `self.nixosModules.host` which pulls in
everything else.

### src/defaults.nix

Defines default applications and user preferences:

- `dot.shell.*` - Shell configuration
- `dot.editor.*` - Editor settings
- `dot.terminal.*` - Terminal emulator
- `dot.browser.*` - Web browser
- `dot.visual.*` - GUI editor/IDE

### Hardware Sharing

Home-manager receives hardware config via `home-manager.sharedModules`:

```nix
home-manager.sharedModules = [
  {
    dot.hardware = config.dot.hardware;  # Pass hardware to home-manager
  }
];
```

This allows home-manager modules to use `config.dot.hardware.*` for conditional
config.

## Key External Dependencies

### Perch Modules (Temporary)

The repo still uses `perch-modules` for some functionality:

- `perch-modules.nixosModules."flake-deployRs"` - Deployment
- `perch-modules.nixosModules."flake-rumor"` - Secret management

These should eventually be migrated to native flake-parts.

### Secret Management (Rumor)

Uses `rumor` for secret generation and management:

- Integrates with HashiCorp Vault
- Generates certificates, passwords, keys
- Defined in modules via `rumor.specification.*`

### Consul Service Discovery

Services register with Consul for service mesh:

```nix
dot.consul.services = [{
  name = "my-service";
  port = 8080;
  # ...
}];
```

## Common Patterns

### Conditional Configuration

```nix
{ config, lib, ... }:
let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasNetwork = config.dot.hardware.network.enable;
in
{
  flake.homeModules.my-program = lib.mkIf hasMonitor {
    # Only on systems with displays
  };
}
```

### Accessing Other Modules

```nix
{ config, ... }:  # config.flake gives access to all flake outputs
{
  flake.nixosModules.my-module = {
    imports = [
      config.flake.nixosModules.some-other-module
    ];
  };
}
```

### Using Library Functions

```nix
{ config, lib, pkgs, ... }:
let
  hexToDec = config.flake.lib.hex.hexToDec;
in
{
  # Use hexToDec
}
```

## Testing & Building

### Check flake

```bash
nix flake check
```

### Build a host configuration

```bash
nixos-rebuild build --flake .#hearth
```

### Build dev shell

```bash
nix develop
```

## Gotchas & Important Notes

1. **Hardware detection requires facter report**: Each host needs
   `src/hosts/<name>/hardware.json` generated by nixos-facter

2. **Home-manager modules need config arg**: When defining home-manager modules,
   ensure you have `config` in the function args to access `config.dot.hardware`

3. **Module discovery is recursive**: All `.nix` files under `src/` are
   automatically imported - be careful with helper files

4. **Host module imports everything**: `src/host.nix` imports
   `config.flake.nixosModules.*` which includes ALL modules - be mindful of what
   you export

5. **Some modules still use perch-modules**: Deploy-rs and rumor integration
   comes from `perch-modules` - these need manual migration eventually

6. **perSystem vs flake**:
   - Use `perSystem` for packages, devShells, apps (per architecture)
   - Use `flake` for modules, configurations, lib (architecture-independent)

## Files to Know

| File                      | Purpose                                 |
| ------------------------- | --------------------------------------- |
| `flake.nix`               | Entry point with flake-parts            |
| `src/host.nix`            | Central host module, imports everything |
| `src/defaults.nix`        | Default apps and user settings          |
| `src/hardware/module.nix` | Hardware detection from facter          |
| `src/nix.nix`             | Nix settings, substituters, gc          |
| `src/nixpkgs.nix`         | Nixpkgs config, overlays, unstablePkgs  |

## Migration Notes (Perch → Flake-Parts)

If you encounter old perch-style code:

**Old:**

```nix
{
  nixosModule = { ... }: { ... };
  homeManagerModule = { ... }: { ... };
}
```

**New:**

```nix
{ ... }: {
  flake.nixosModules.name = { ... }: { ... };
  flake.homeModules.name = { ... }: { ... };
}
```

---

Last updated: 2026-02-27

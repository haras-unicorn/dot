{
  self,
  lib,
  specialArgs,
  config,
  ...
}:
let
  cfg = config.machines;
in
{
  options.machines = {
    machines = lib.mkOption {
      type = lib.types.attrsOf lib.types.deferredModule;
      default = { };
      description = "Machine declaring NixOS modules.";
    };

    nixosModules = lib.mkOption {
      type = lib.types.attrsOf lib.types.deferredModule;
      default = { };
      description = "NixOS modules for all machines.";
    };

    homeModules = lib.mkOption {
      type = lib.types.attrsOf lib.types.deferredModule;
      default = { };
      description = "Home modules for all machines for config.dot.user.user.";
    };
  };

  config = {
    flake.nixosConfigurations = builtins.mapAttrs (
      name: machineModule:
      lib.nixosSystem {
        inherit specialArgs;
        modules = builtins.attrValues cfg.nixosModules ++ [
          machineModule
          (
            { config, ... }:
            let
              hardware = "${self}/assets/hardware/${name}.json";
            in
            {
              _file = ./machines.nix;
              key = ./machines.nix;

              networking.hostName = name;

              hardware.facter.reportPath = lib.mkIf (builtins.pathExists hardware) (lib.mkDefault hardware);

              home-manager.extraSpecialArgs = specialArgs;
              home-manager.users.${config.dot.user.user}.imports = builtins.attrValues cfg.homeModules;

              nixpkgs.system = config.hardware.facter.report.system;
            }
          )
        ];
      }
    ) cfg.machines;
  };
}

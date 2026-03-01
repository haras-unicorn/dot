{ config, ... }:

{
  flake.nixosModules.critical-linux =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      isRpi4 = config.dot.hardware.rpi."4".enable;
      isLegacyNvidia =
        let
          version = config.dot.hardware.graphics.version;
          driver = config.dot.hardware.graphics.driver;
        in
        driver == "nvidia" && ((version != "latest") && (version != "production"));
    in
    {
      boot.binfmt.preferStaticEmulators = true;
      boot.binfmt.emulatedSystems = lib.mkIf (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [
        "aarch64-linux"
      ];

      boot.kernelPackages =
        if isRpi4 then
          pkgs.linuxKernel.packages.linux_rpi4
        else if isLegacyNvidia then
          pkgs.linuxKernel.packages.linux_6_6
        else
          pkgs.linuxPackages_zen;
    };

  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  perSystem =
    { pkgs, ... }:
    {
      checks.test-critical-linux-standard = config.flake.lib.test.mkTest pkgs {
        name = "critical-linux-standard";
        nodes.machine = {
          imports = [ config.flake.nixosModules.critical-linux ];
          options.dot.hardware.rpi."4".enable = pkgs.lib.mkOption {
            type = pkgs.lib.types.bool;
            default = false;
          };
          options.dot.hardware.graphics.driver = pkgs.lib.mkOption {
            type = pkgs.lib.types.str;
            default = "";
          };
          options.dot.hardware.graphics.version = pkgs.lib.mkOption {
            type = pkgs.lib.types.str;
            default = "";
          };
        };
        script = ''
          start_all()
          # Verify the system boots with zen kernel packages available
          machine.succeed("readlink /run/booted-system/kernel | grep -qi zen")
          machine.succeed("systemctl is-system-running --wait || true")
        '';
      };

      checks.test-critical-linux-legacy-nvidia = config.flake.lib.test.mkTest pkgs {
        name = "critical-linux-legacy-nvidia";
        nodes.machine = {
          imports = [ config.flake.nixosModules.critical-linux ];
          options.dot.hardware.rpi."4".enable = pkgs.lib.mkOption {
            type = pkgs.lib.types.bool;
            default = false;
          };
          options.dot.hardware.graphics.driver = pkgs.lib.mkOption {
            type = pkgs.lib.types.str;
            default = "nvidia";
          };
          options.dot.hardware.graphics.version = pkgs.lib.mkOption {
            type = pkgs.lib.types.str;
            default = "legacy";
          };
        };
        script = ''
          start_all()
          # Verify 6.6 kernel is used for legacy Nvidia
          machine.succeed("readlink /run/booted-system/kernel | grep -q '6.6'")
          machine.succeed("systemctl is-system-running --wait || true")
        '';
      };
    };
}

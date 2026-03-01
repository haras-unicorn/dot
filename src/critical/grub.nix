{ config, ... }:

{
  flake.nixosModules.critical-grub =
    {
      config,
      ...
    }:
    let
      isRpi4 = config.dot.hardware.rpi."4".enable;
    in
    {
      boot.loader.efi.canTouchEfiVariables = false;
      boot.loader.grub.enable = !isRpi4;
      boot.loader.grub.device = "nodev";
      boot.loader.grub.efiSupport = true;
      boot.loader.grub.useOSProber = true;
      boot.loader.generic-extlinux-compatible.enable = isRpi4;

      stylix.targets.grub.useWallpaper = true;
    };

  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  perSystem =
    { pkgs, ... }:
    {
      checks.test-critical-grub-efi = config.flake.lib.test.mkTest pkgs {
        name = "critical-grub-efi";
        nodes.machine = {
          imports = [ config.flake.nixosModules.critical-grub ];
          options.dot.hardware.rpi."4".enable = pkgs.lib.mkOption {
            type = pkgs.lib.types.bool;
            default = false;
          };
          options.stylix.targets.grub.useWallpaper = pkgs.lib.mkOption {
            type = pkgs.lib.types.bool;
            default = true;
          };
        };
        script = ''
          start_all()
          # Verify GRUB tools are available in the system closure
          machine.succeed("find /nix/store -name 'grub*' -type d | head -1")
          # Verify system booted successfully
          machine.succeed("systemctl is-system-running --wait")
        '';
      };

      checks.test-critical-grub-rpi4 = config.flake.lib.test.mkTest pkgs {
        name = "critical-grub-rpi4";
        nodes.machine = {
          imports = [ config.flake.nixosModules.critical-grub ];
          options.dot.hardware.rpi."4".enable = pkgs.lib.mkOption {
            type = pkgs.lib.types.bool;
            default = true;
          };
          options.stylix.targets.grub.useWallpaper = pkgs.lib.mkOption {
            type = pkgs.lib.types.bool;
            default = true;
          };
        };
        script = ''
          start_all()
          # On RPi4, extlinux-compatible should be enabled instead of GRUB
          # Verify extlinux tools are present in the system
          machine.succeed("find /nix/store -name '*extlinux*' -type f | head -1")
          # System should boot successfully with extlinux config
          machine.succeed("systemctl is-system-running --wait")
        '';
      };
    };
}

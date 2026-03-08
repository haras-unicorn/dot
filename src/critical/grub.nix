{ self, ... }:

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
      checks.test-critical-grub-efi = self.lib.test.mkTest pkgs {
        name = "critical-grub-efi";
        nodes.machine = {
          imports = [
            self.nixosModules.critical-grub
          ];

          options.stylix.targets.grub.useWallpaper = pkgs.lib.mkOption {
            type = pkgs.lib.types.bool;
          };

          config.dot.hardware.rpi."4".enable = false;
        };
        testScript = ''
          start_all()
          machine.succeed("find /nix/store -name 'grub*' -type d | head -1")
          machine.succeed("systemctl is-system-running --wait")
        '';
      };

      checks.test-critical-grub-rpi4 = self.lib.test.mkTest pkgs {
        name = "critical-grub-rpi4";
        nodes.machine = {
          imports = [
            self.nixosModules.critical-grub
          ];

          options.stylix.targets.grub.useWallpaper = pkgs.lib.mkOption {
            type = pkgs.lib.types.bool;
          };

          config.dot.hardware.rpi."4".enable = true;
        };
        testScript = ''
          start_all()
          machine.succeed("find /nix/store -name '*extlinux*' -type f | head -1")
          machine.succeed("systemctl is-system-running --wait")
        '';
      };
    };
}

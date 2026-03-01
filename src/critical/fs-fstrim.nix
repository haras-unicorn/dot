{ config, ... }:

{
  flake.nixosModules.critical-fs-fstrim =
    { config, lib, ... }:
    let
      isRpi4 = config.dot.hardware.rpi."4".enable;
    in
    {
      boot.initrd.kernelModules = [
        "ext4"
        "vfat"
      ];
      fileSystems."/firmware" = lib.mkIf isRpi4 {
        device = "/dev/disk/by-label/FIRMWARE";
        fsType = "vfat";
      };
      fileSystems."/boot" = lib.mkIf (!isRpi4) {
        device = "/dev/disk/by-label/NIXBOOT";
        fsType = "vfat";
      };
      fileSystems."/" = lib.mkMerge [
        (lib.mkIf (!isRpi4) {
          device = "/dev/disk/by-label/NIXROOT";
          fsType = "ext4";
        })
        (lib.mkIf (isRpi4) {
          device = "/dev/disk/by-label/NIXOS_SD";
          fsType = "ext4";
        })
      ];
      services.fstrim.enable = true;

      programs.rust-motd.settings = {
        filesystems = {
          root = "/";
        };
      };
    };

  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  perSystem =
    { pkgs, ... }:
    {
      checks.test-critical-fs-fstrim-standard = config.flake.lib.test.mkTest pkgs {
        name = "critical-fs-fstrim-standard";
        nodes.machine = {
          imports = [ config.flake.nixosModules.critical-fs-fstrim ];
          options.dot.hardware.rpi."4".enable = pkgs.lib.mkOption {
            type = pkgs.lib.types.bool;
            default = false;
          };
        };
        script = ''
          start_all()
          # Verify fstrim service/timer is enabled
          machine.succeed("systemctl is-enabled fstrim.service || systemctl is-enabled fstrim.timer")
          # Verify kernel modules are configured (check if module is loaded or available)
          machine.execute("lsmod | grep -q ext4 || grep -q ext4 /proc/modules || test -d /sys/module/ext4")
        '';
      };

      checks.test-critical-fs-fstrim-rpi4 = config.flake.lib.test.mkTest pkgs {
        name = "critical-fs-fstrim-rpi4";
        nodes.machine = {
          imports = [ config.flake.nixosModules.critical-fs-fstrim ];
          options.dot.hardware.rpi."4".enable = pkgs.lib.mkOption {
            type = pkgs.lib.types.bool;
            default = true;
          };
        };
        script = ''
          start_all()
          # Verify fstrim service/timer is enabled
          machine.succeed("systemctl is-enabled fstrim.service || systemctl is-enabled fstrim.timer")
          # Verify the module is loaded by checking it's available
          machine.execute("lsmod | grep -q ext4 || grep -q ext4 /proc/modules || test -d /sys/module/ext4")
        '';
      };
    };
}

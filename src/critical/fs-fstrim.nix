{ self, ... }:

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
      checks.test-critical-fs-fstrim = self.lib.test.mkTest pkgs {
        name = "critical-fs-fstrim";
        nodes.machine = {
          imports = [
            self.nixosModules.critical-fs-fstrim
          ];

          dot.hardware.rpi."4".enable = false;
        };
        testScript = ''
          start_all()
          machine.succeed("systemctl is-enabled fstrim.service || systemctl is-enabled fstrim.timer")
          machine.execute("lsmod | grep -q ext4 || grep -q ext4 /proc/modules || test -d /sys/module/ext4")
        '';
      };

      checks.test-critical-fs-fstrim-rpi4 = self.lib.test.mkTest pkgs {
        name = "critical-fs-fstrim-rpi4";
        nodes.machine = {
          imports = [
            self.nixosModules.critical-fs-fstrim
          ];

          dot.hardware.rpi."4".enable = true;
        };
        testScript = ''
          start_all()
          machine.succeed("systemctl is-enabled fstrim.service || systemctl is-enabled fstrim.timer")
          machine.execute("lsmod | grep -q ext4 || grep -q ext4 /proc/modules || test -d /sys/module/ext4")
        '';
      };
    };
}

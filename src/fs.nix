{ config, lib, ... }:

let
  isRpi4 = config.dot.hardware.rpi."4".enable;
in
{
  branch.nixosModule.nixosModule = {
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
}

{
  machines.nixosModules.fs = {
    boot.initrd.kernelModules = [
      "ext4"
      "vfat"
    ];
    fileSystems."/boot" = {
      device = "/dev/disk/by-label/NIXBOOT";
      fsType = "vfat";
    };
    fileSystems."/" = {
      device = "/dev/disk/by-label/NIXROOT";
      fsType = "ext4";
    };
    services.fstrim.enable = true;
  };
}

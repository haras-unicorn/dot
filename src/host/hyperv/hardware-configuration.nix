{ ... }:

{
  boot.initrd.availableKernelModules = [ "sd_mod" "sr_mod" ];

  fileSystems."/" = {
    device = "/dev/disk/by-partlabel/nixroot";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/nixboot";
    fsType = "vfat";
  };

  swapDevices = [
    {
      device = "/.swapfile";
      size = 4 * 1024;
    }
  ];

  virtualisation.hypervGuest.enable = true;
}

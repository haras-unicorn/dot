{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ ];

  boot.initrd.availableKernelModules = [ "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixroot";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/nixboot";
    fsType = "vfat";
  };

  swapDevices = [ 
    {
      device = "/.swapfile";
      size = 4 * 1024;
    }
  ];

  networking.useDHCP = true;

  nixpkgs.hostPlatform = "x86_64-linux";
  virtualisation.hypervGuest.enable = true;
}

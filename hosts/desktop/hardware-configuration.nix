{ lib, modulesPath, ... }:

{
  imports = [ 
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  nixpkgs.config.allowUnfree = true;

  boot.initrd.availableKernelModules = [ 
    "nvme"
    "xhci_pci"
    "ahci"
    "usb_storage"
    "usbhid"
    "sd_mod"
    "sr_mod"
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];
  boot.kernelModules = [
    "kvm-amd"
  ];

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
      device = "/var/swap";
      size = 32 * 1024;
    }
  ];

  hardware.cpu.amd.updateMicrocode = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true;
  hardware.opengl.driSupport32Bit = true;
  hardware.nvidia.modesetting.enable = true;
  hardware.nvidia.open = true;
}
